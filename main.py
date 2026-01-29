from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from typing import List, Optional
from PIL import Image
import numpy as np
import io

app = FastAPI()

# --- 1. CONFIGURATION ---
# ⚠️ PASTE YOUR SUPABASE KEYS HERE AGAIN!
url: str = "YOUR_SUPABASE_URL_HERE"
key: str = "YOUR_SUPABASE_ANON_KEY_HERE"
supabase: Client = create_client(url, key)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 2. DATA MODELS ---
class User(BaseModel):
    email: str
    password: str

class Order(BaseModel):
    user_email: str
    total_price: float
    items: list
    payment_id: Optional[str] = None
    payment_mode: str = "Online" # <--- NEW FIELD

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

# --- 3. BASIC ROUTES ---
@app.get("/")
def home():
    return {"message": "Vaishnav's Supermarket API is Live! 🚀"}

@app.get("/products")
def get_products():
    try: return supabase.table("products").select("*").execute().data
    except: return []

@app.get("/banners")
def get_banners():
    try: return supabase.table("banners").select("*").eq("is_active", "true").execute().data
    except: return []

# --- 4. AUTH & PROFILE ---
@app.post("/signup")
def signup(user: User):
    try:
        existing = supabase.table("users").select("*").eq("email", user.email).execute()
        if existing.data: return {"error": "User already exists!"}
        supabase.table("users").insert({"email": user.email, "password": user.password}).execute()
        return {"message": "Account created!"}
    except Exception as e: return {"error": str(e)}

@app.post("/login")
def login(user: User):
    try:
        response = supabase.table("users").select("*").eq("email", user.email).execute()
        if not response.data or response.data[0]['password'] != user.password:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        return {"message": "Login Successful", "email": user.email}
    except Exception as e:
        if "401" in str(e): raise e
        return {"error": str(e)}

@app.get("/get_profile/{email}")
def get_profile(email: str):
    try:
        data = supabase.table("profiles").select("*").eq("email", email).execute()
        if data.data: return data.data[0]
        supabase.table("profiles").insert({"email": email, "coins": 0}).execute()
        return {"email": email, "coins": 0}
    except: return {"error": "Profile error"}

@app.post("/update_profile")
def update_profile(data: ProfileUpdate):
    try:
        supabase.table("users").update({"address": data.address, "phone": data.phone}).eq("email", data.email).execute()
        return {"message": "Updated"}
    except Exception as e: return {"error": str(e)}

# --- 5. WISHLIST ---
@app.post("/add_wishlist")
def add_wishlist(item: WishlistItem):
    try:
        exists = supabase.table("wishlist").select("*").eq("user_email", item.user_email).eq("product_name", item.product_name).execute()
        if exists.data: return {"message": "Already added"}
        supabase.table("wishlist").insert(item.dict()).execute()
        return {"message": "Added"}
    except Exception as e: return {"error": str(e)}

@app.get("/get_wishlist/{email}")
def get_wishlist(email: str):
    try: return supabase.table("wishlist").select("*").eq("user_email", email).execute().data
    except: return []

@app.delete("/remove_wishlist")
def remove_wishlist(email: str, product_name: str):
    try:
        supabase.table("wishlist").delete().eq("user_email", email).eq("product_name", product_name).execute()
        return {"message": "Removed"}
    except: return {"error": "Failed"}

# --- 6. ORDER PLACEMENT (UPDATED FOR COD) ---
@app.post("/place_order")
def place_order(order: Order):
    try:
        # Check Stock
        for item in order.items:
            prod = supabase.table("products").select("stock_quantity").eq("name", item['name']).execute()
            if prod.data and prod.data[0]['stock_quantity'] <= 0:
                raise HTTPException(status_code=400, detail=f"{item['name']} is Out of Stock!")

        # Save Order with Payment Mode
        supabase.table("orders").insert({
            "user_email": order.user_email,
            "total_price": order.total_price,
            "items": order.items,
            "payment_id": order.payment_id,
            "status": "Pending",
            "payment_mode": order.payment_mode # <--- SAVING COD or ONLINE
        }).execute()

        # Update Stock
        for item in order.items:
            curr = supabase.table("products").select("stock_quantity").eq("name", item['name']).execute()
            if curr.data:
                new_qty = curr.data[0]['stock_quantity'] - 1
                supabase.table("products").update({"stock_quantity": new_qty}).eq("name", item['name']).execute()

        # Update Coins
        coins = int(order.total_price * 0.10)
        profile = supabase.table("profiles").select("coins").eq("email", order.user_email).execute()
        current_coins = profile.data[0]['coins'] if profile.data else 0
        
        if profile.data:
            supabase.table("profiles").update({"coins": current_coins + coins}).eq("email", order.user_email).execute()
        else:
            supabase.table("profiles").insert({"email": order.user_email, "coins": coins}).execute()

        return {"message": f"Order Placed! Earned {coins} Coins! 🪙"}
    except Exception as e:
        if "Out of Stock" in str(e): raise e
        return {"error": str(e)}

# --- 7. ORDER HISTORY ---
@app.get("/my_orders/{email}")
def get_my_orders(email: str):
    try:
        response = supabase.table("orders").select("*").eq("user_email", email).order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        print(f"Error fetching orders: {e}")
        return []

# --- 8. ADMIN ---
@app.get("/admin/all_orders")
def get_all_orders():
    try:
        orders = supabase.table("orders").select("*").order("created_at", desc=True).execute().data
        for order in orders:
            user = supabase.table("users").select("address, phone").eq("email", order['user_email']).execute()
            if user.data:
                order['address'] = user.data[0]['address']
                order['phone'] = user.data[0]['phone']
            else:
                order['address'] = "Not Found"
                order['phone'] = "Not Found"
        return orders
    except: return []

# --- 9. VISUAL AI ---
@app.post("/visual_search")
async def visual_search(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert('RGB').resize((100, 100))
        r, g, b = np.average(np.average(np.array(image), axis=0), axis=0)
        
        item, conf = "Unknown", 0.0
        if r > g+20 and r > b+20: item, conf = "Fresh Tomato", 92.5
        elif g > r+10 and g > b+10: item, conf = "Spinach (Palak)", 88.3
        elif r > 150 and g > 150 and b < 100: item, conf = "Banana", 95.1
        elif r > 180 and g > 160 and b > 140: item, conf = "Potato", 85.0
            
        return {"detected": item, "confidence": f"{conf}%"}
    except Exception as e: return {"error": str(e)}

# --- 10. CHATBOT ---
@app.post("/chat")
def ai_chat(query: ChatQuery):
    q = query.text.lower()
    if "hello" in q: return {"response": "Hello! I am Vaishnav AI 🤖."}
    if "delivery" in q: return {"response": "We deliver in 30-45 minutes! 🚀"}
    
    try:
        for word in q.split():
            if len(word) > 3:
                res = supabase.table("products").select("*").ilike("name", f"%{word}%").execute()
                if res.data: return {"response": f"Yes! We have {res.data[0]['name']} for ₹{res.data[0]['price']}."}
        return {"response": "I couldn't find that item."}
    except: return {"response": "AI Brain Error."}