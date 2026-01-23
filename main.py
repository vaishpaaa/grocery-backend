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

# --- 6. ORDER SYSTEM ---
@app.post("/place_order")
def place_order(order: OrderModel):
    try:
        response = supabase.table("orders").insert({
            "user_email": order.user_email,
            "total_price": order.total_price,
            "items": order.items,
            "payment_id": order.payment_id
        }).execute()
        return {"message": "Order placed successfully!"}
    except Exception as e:
        print(f"Order Error: {e}")
        return {"error": str(e)}

@app.get("/user_orders/{email}")
def get_user_orders(email: str):
    try:
        response = supabase.table("orders")\
            .select("*")\
            .eq("user_email", email)\
            .order("created_at", desc=True)\
            .execute()
        return response.data
    except Exception as e:
        print(f"Error fetching orders: {e}")
        return []

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
# --- 9. ADMIN SYSTEM ---
@app.get("/admin/all_orders")
def get_all_orders():
    try:
        # Fetch all orders, newest first
        # We also want user details (address/phone), but for now let's just get the orders
        # In a real app, we would join tables. Here we will keep it simple.
        response = supabase.table("orders").select("*").order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        print(f"Admin Error: {e}")
        return []