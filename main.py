from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client

app = FastAPI()

# --- 1. CORS CONFIGURATION (Helps prevent connection blocks) ---
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

# --- 4. PRODUCT LIST (High-Speed Images) ---
products = [
    {"id": 1, "name": "Fresh Apples", "price": 120, "image_url": "https://placehold.co/400x400/png?text=Apples"},
    {"id": 2, "name": "Aashirvaad Atta", "price": 240, "image_url": "https://placehold.co/400x400/png?text=Atta"},
    {"id": 3, "name": "Amul Milk", "price": 32, "image_url": "https://placehold.co/400x400/png?text=Milk"},
    {"id": 4, "name": "Dark Fantasy", "price": 40, "image_url": "https://placehold.co/400x400/png?text=Choco"},
    {"id": 5, "name": "Tata Salt", "price": 25, "image_url": "https://placehold.co/400x400/png?text=Salt"},
]

@app.get("/products")
def get_products():
    return products

# --- 5. SECURE SIGNUP ---
@app.post("/signup")
def signup(user: User):
    try:
        # Check if user already exists
        existing = supabase.table("users").select("*").eq("email", user.email).execute()
        if existing.data:
            return {"error": "User already exists!"}
        
        # Create new user
        supabase.table("users").insert({"email": user.email, "password": user.password}).execute()
        return {"message": "Account created!"}
    except Exception as e:
        return {"error": str(e)}

# --- 6. SECURE LOGIN (Fixed) ---
@app.post("/login")
def login(user: User):
    try:
        # Find user by email
        response = supabase.table("users").select("*").eq("email", user.email).execute()
        
        # If no user found, OR password doesn't match
        if not response.data or response.data[0]['password'] != user.password:
            # FORCE AN ERROR CODE (401)
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        return {"message": "Login Successful", "email": user.email}
    except Exception as e:
        # If it was our manual 401 error, re-raise it so FastAPI handles it
        if "401" in str(e):
            raise e
        return {"error": str(e)}

# --- 7. ORDER SYSTEM ---
@app.post("/place_order")
def place_order(order: OrderModel):
    try:
        response = supabase.table("orders").insert({
            "user_email": order.user_email,
            "total_price": order.total_price,
            "items": order.items
        }).execute()
        return {"message": "Order placed successfully!"}
    except Exception as e:
        print(f"Order Error: {e}")
        return {"error": str(e)}

@app.get("/my_orders")
def get_orders(email: str):
    try:
        response = supabase.table("orders").select("*").eq("user_email", email).order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        return []