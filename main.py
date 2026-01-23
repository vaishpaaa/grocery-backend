from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from typing import List, Optional # <--- Added for optional fields

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
    payment_id: Optional[str] = None # <--- NEW: Accepts Razorpay ID

# --- 4. PRODUCT ENDPOINT (Now fetches from Database) ---
@app.get("/products")
def get_products():
    try:
        # Fetch products from DB so 'category' works!
        response = supabase.table("products").select("*").execute()
        return response.data
    except Exception as e:
        print(f"Error fetching products: {e}")
        return []

# --- 5. BANNERS ENDPOINT ---
@app.get("/banners")
def get_banners():
    try:
        response = supabase.table("banners").select("*").eq("is_active", "true").execute()
        return response.data
    except Exception as e:
        print(f"Error fetching banners: {e}")
        return []

# --- 6. AUTH ENDPOINTS ---
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

# --- 7. ORDER SYSTEM (Updated for Razorpay) ---
@app.post("/place_order")
def place_order(order: OrderModel):
    try:
        # Save order to DB with the Payment ID
        response = supabase.table("orders").insert({
            "user_email": order.user_email,
            "total_price": order.total_price,
            "items": order.items,
            "payment_id": order.payment_id # <--- Saving Payment ID
        }).execute()
        return {"message": "Order placed successfully!"}
    except Exception as e:
        print(f"Order Error: {e}")
        return {"error": str(e)}

# --- NEW: ORDER HISTORY (Matches Flutter App) ---
@app.get("/user_orders/{email}")
def get_user_orders(email: str):
    try:
        # Fetch orders for this email, newest first
        response = supabase.table("orders")\
            .select("*")\
            .eq("user_email", email)\
            .order("created_at", desc=True)\
            .execute()
        return response.data
    except Exception as e:
        print(f"Error fetching orders: {e}")
        return []