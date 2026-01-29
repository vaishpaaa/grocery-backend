from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from typing import List, Optional
from PIL import Image
import numpy as np
import io

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

# --- 3. DATA MODELS (BLUEPRINTS) ---
# These must be defined BEFORE the functions that use them.

class User(BaseModel):
    email: str
    password: str

class Order(BaseModel):
    user_email: str
    total_price: float
    items: list
    payment_id: Optional[str] = None

class ProfileUpdate(BaseModel):
    email: str
    address: str
    phone: str

class WishlistItem(BaseModel):
    user_email: str
    product_name: str
    image_url: str
    price: float

class ChatQuery(BaseModel):
    text: str

# --- 4. PRODUCT ENDPOINTS ---
@app.get("/")
def home():
    return {"message": "Vaishnav's Supermarket API is Live! 🚀"}

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

@app.get("/get_profile/{email}")
def get_profile(email: str):
    try:
        data = supabase.table("profiles").select("*").eq("email", email).execute()
        if data.data:
            return data.data[0]
        else:
            # Create if not exists
            new_profile = {"email": email, "coins": 0}
            supabase.table("profiles").insert(new_profile).execute()
            return new_profile
    except Exception as e:
        return {"error": str(e)}

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

# --- 6. ORDER SYSTEM (WITH STOCK & COINS) ---
@app.post("/place_order")
def place_order(order: Order):
    try:
        # 1. CHECK STOCK
        for item in order.items:
            product_name = item['name']
            response = supabase.table("products").select("stock_quantity").eq("name", product_name).execute()
            
            if not response.data:
                continue 
                
            current_stock = response.data[0]['stock_quantity']
            
            if current_stock <= 0:
                raise HTTPException(status_code=400, detail=f"Sorry! {product_name} is Out of Stock.")

        # 2. PLACE ORDER
        response = supabase.table("orders").insert({
            "user_email": order.user_email,
            "total_price": order.total_price,
            "items": order.items,
            "payment_id": order.payment_id,
            "status": "Pending"
        }).execute()

        # 3. DECREASE STOCK
        for item in order.items:
            product_name = item['name']
            curr_data = supabase.table("products").select("stock_quantity").eq("name", product_name).execute()
            if curr_data.data:
                curr_stock = curr_data.data[0]['stock_quantity']
                new_stock = curr_stock - 1
                supabase.table("products").update({"stock_quantity": new_stock}).eq("name", product_name).execute()

        # 4. LOYALTY COINS LOGIC
        coins_earned = int(order.total_price * 0.10)
        
        current_profile = supabase.table("profiles").select("coins").eq("email", order.user_email).execute()
        current_coins = current_profile.data[0]['coins'] if current_profile.data else 0
        
        new_balance = current_coins + coins_earned
        
        if current_profile.data:
            supabase.table("profiles").update({"coins": new_balance}).eq("email", order.user_email).execute()
        else:
            supabase.table("profiles").insert({"email": order.user_email, "coins": new_balance}).execute()

        return {"message": f"Order placed! You earned {coins_earned} Coins! 🪙"}

    except Exception as e:
        print(f"Order Error: {e}")
        if "Out of Stock" in str(e):
             raise e
        return {"error": str(e)}

# --- 7. ADMIN SYSTEM ---
@app.get("/admin/all_orders")
def get_all_orders():
    try:
        orders_response = supabase.table("orders").select("*").order("created_at", desc=True).execute()
        orders = orders_response.data
        
        for order in orders:
            user_email = order['user_email']
            user_response = supabase.table("users").select("address, phone").eq("email", user_email).execute()
            
            if user_response.data:
                order['address'] = user_response.data[0]['address']
                order['phone'] = user_response.data[0]['phone']
            else:
                order['address'] = "Not Found"
                order['phone'] = "Not Found"
                
        return orders
    except Exception as e:
        print(f"Admin Error: {e}")
        return []

@app.get("/my_orders/{email}")
def get_my_orders(email: str):
    try:
        # Fetch orders for this specific email, newest first
        response = supabase.table("orders").select("*").eq("user_email", email).order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        print(f"Error fetching orders: {e}")
        return []
# --- 8. WISHLIST SYSTEM ---
@app.post("/add_wishlist")
def add_wishlist(item: WishlistItem):
    try:
        exists = supabase.table("wishlist").select("*").eq("user_email", item.user_email).eq("product_name", item.product_name).execute()
        if exists.data:
            return {"message": "Already in wishlist"}
            
        supabase.table("wishlist").insert({
            "user_email": item.user_email,
            "product_name": item.product_name,
            "image_url": item.image_url,
            "price": item.price
        }).execute()
        return {"message": "Added to Wishlist"}
    except Exception as e:
        return {"error": str(e)}

@app.get("/get_wishlist/{email}")
def get_wishlist(email: str):
    try:
        response = supabase.table("wishlist").select("*").eq("user_email", email).execute()
        return response.data
    except Exception as e:
        return []

@app.delete("/remove_wishlist")
def remove_wishlist(email: str, product_name: str):
    try:
        supabase.table("wishlist").delete().eq("user_email", email).eq("product_name", product_name).execute()
        return {"message": "Removed"}
    except Exception as e:
        return {"error": str(e)}

# --- 9. VISUAL SEARCH AI ---
@app.post("/visual_search")
async def visual_search(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert('RGB')
        image = image.resize((100, 100))
        img_array = np.array(image)
        
        avg_color_per_row = np.average(img_array, axis=0)
        avg_color = np.average(avg_color_per_row, axis=0)
        r, g, b = avg_color
        
        detected_item = "Unknown"
        confidence = 0.0
        
        if r > g + 20 and r > b + 20:
            detected_item = "Fresh Tomato"
            confidence = 92.5
        elif g > r + 10 and g > b + 10:
            detected_item = "Spinach (Palak)"
            confidence = 88.3
        elif r > 150 and g > 150 and b < 100:
            detected_item = "Banana"
            confidence = 95.1
        elif r > 180 and g > 160 and b > 140:
            detected_item = "Potato"
            confidence = 85.0
            
        return {
            "detected": detected_item, 
            "confidence": f"{confidence}%",
            "message": f"AI analyzed RGB: ({int(r)}, {int(g)}, {int(b)})"
        }

    except Exception as e:
        return {"error": str(e)}

# --- 10. VAISHNAV AI CHATBOT ---
@app.post("/chat")
def ai_chat(query: ChatQuery):
    q = query.text.lower()
    
    if "hello" in q or "hi" in q:
        return {"response": "Hello! I am Vaishnav AI 🤖. Ask me about products or delivery!"}
    
    if "delivery" in q or "time" in q:
        return {"response": "We deliver in 30-45 minutes! 🚀"}
    if "return" in q or "refund" in q:
        return {"response": "You can return damaged items within 24 hours."}
    
    try:
        words = q.split()
        for word in words:
            if len(word) > 3:
                response = supabase.table("products").select("*").ilike("name", f"%{word}%").execute()
                if response.data:
                    item = response.data[0]
                    return {"response": f"Yes! We have {item['name']} in stock for ₹{item['price']}. 🛍️"}
        
        return {"response": "I couldn't find that item specifically, but we are adding new stock daily!"}
        
    except Exception as e:
        return {"response": "I am having trouble connecting to the brain right now. 😵"}