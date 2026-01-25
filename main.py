from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from typing import List, Optional

app = FastAPI()

# --- 1. CORS CONFIGURATION ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 2. SUPABASE CONFIGURATION ---
url: str = "https://eopamdsepyvaglxpifji.supabase.co"
key: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvcGFtZHNlcHl2YWdseHBpZmppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0NTk2NDcsImV4cCI6MjA4NDAzNTY0N30.4sStNUyBDOc6MrzTFMIg9eny4cb6ndVF6aOqecjUtXM"
supabase: Client = create_client(url, key)

# --- 3. DATA MODELS ---
class User(BaseModel):
    email: str
    password: str

class OrderModel(BaseModel):
    user_email: str
    total_price: float
    items: list
    payment_id: Optional[str] = None

class ProfileUpdate(BaseModel):
    email: str
    address: str
    phone: str

# --- 4. PRODUCT ENDPOINTS ---
@app.get("/products")
def get_products():
    try:
        response = supabase.table("products").select("*").execute()
        return response.data
    except Exception as e:
        print(f"Error fetching products: {e}")
        return []

@app.get("/banners")
def get_banners():
    try:
        response = supabase.table("banners").select("*").eq("is_active", "true").execute()
        return response.data
    except Exception as e:
        print(f"Error fetching banners: {e}")
        return []

# --- 5. AUTH ENDPOINTS ---
@app.post("/signup")
def signup(user: User):
    try:
        existing = supabase.table("users").select("*").eq("email", user.email).execute()
        if existing.data:
            return {"error": "User already exists!"}
        
        supabase.table("users").insert({"email": user.email, "password": user.password}).execute()
        return {"message": "Account created!"}
    except Exception as e:
        return {"error": str(e)}

@app.post("/login")
def login(user: User):
    try:
        response = supabase.table("users").select("*").eq("email", user.email).execute()
        if not response.data or response.data[0]['password'] != user.password:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        return {"message": "Login Successful", "email": user.email}
    except Exception as e:
        if "401" in str(e):
            raise e
        return {"error": str(e)}

# --- 6. ORDER SYSTEM (WITH STOCK MANAGEMENT) ---
@app.post("/place_order")
def place_order(order: OrderModel):
    try:
        # 1. First, CHECK if we have enough stock for all items
        for item in order.items:
            # Get current stock from DB
            product_name = item['name']
            response = supabase.table("products").select("stock_quantity").eq("name", product_name).execute()
            
            if not response.data:
                continue # Skip if product not found (shouldn't happen)
                
            current_stock = response.data[0]['stock_quantity']
            
            if current_stock <= 0:
                raise HTTPException(status_code=400, detail=f"Sorry! {product_name} is Out of Stock.")

        # 2. If check passes, PLACE the order
        response = supabase.table("orders").insert({
            "user_email": order.user_email,
            "total_price": order.total_price,
            "items": order.items,
            "payment_id": order.payment_id
        }).execute()

        # 3. Finally, DECREASE the stock for each item
        for item in order.items:
            product_name = item['name']
            # We need to fetch current stock again to be safe, or just decrement
            # Ideally, we subtract 1 (since your cart adds 1 qty per row currently)
            # Find the product and update stock - 1
            
            # Get current stock
            curr = supabase.table("products").select("stock_quantity").eq("name", product_name).execute().data[0]['stock_quantity']
            new_stock = curr - 1
            
            supabase.table("products").update({"stock_quantity": new_stock}).eq("name", product_name).execute()

        return {"message": "Order placed successfully!"}
    except Exception as e:
        print(f"Order Error: {e}")
        # If it's our custom stock error, pass it to the app
        if "Out of Stock" in str(e):
             # We need to send a 400 error so Flutter knows to show a Red Message
             raise e
        return {"error": str(e)}

# --- 7. PROFILE SYSTEM ---
@app.post("/update_profile")
def update_profile(data: ProfileUpdate):
    try:
        response = supabase.table("users").update({
            "address": data.address,
            "phone": data.phone
        }).eq("email", data.email).execute()
        return {"message": "Profile updated!"}
    except Exception as e:
        return {"error": str(e)}

@app.get("/get_profile/{email}")
def get_profile(email: str):
    try:
        response = supabase.table("users").select("address, phone").eq("email", email).execute()
        if response.data:
            return response.data[0]
        return {"address": "", "phone": ""}
    except Exception as e:
        return {"address": "", "phone": ""}
# --- 9. ADMIN SYSTEM (SMARTER VERSION) ---
@app.get("/admin/all_orders")
def get_all_orders():
    try:
        # 1. Get all orders
        orders_response = supabase.table("orders").select("*").order("created_at", desc=True).execute()
        orders = orders_response.data
        
        # 2. For each order, find the user's address & phone
        for order in orders:
            user_email = order['user_email']
            # Search user table
            user_response = supabase.table("users").select("address, phone").eq("email", user_email).execute()
            
            if user_response.data:
                # Add address/phone to the order data
                order['address'] = user_response.data[0]['address']
                order['phone'] = user_response.data[0]['phone']
            else:
                order['address'] = "Not Found"
                order['phone'] = "Not Found"
                
        return orders
    except Exception as e:
        print(f"Admin Error: {e}")
        return []