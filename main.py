from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from typing import List, Optional
from PIL import Image
import numpy as np
import io
from fastapi import UploadFile, File

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

        # --- NEW: LOYALTY COIN LOGIC ---
        # 1. Calculate coins (10% of total price)
        coins_earned = int(order.total_price * 0.10)
        
        # 2. Get current coins
        current_profile = supabase.table("profiles").select("coins").eq("email", order.user_email).execute()
        current_coins = current_profile.data[0]['coins'] if current_profile.data else 0
        
        # 3. Update new balance
        new_balance = current_coins + coins_earned
        supabase.table("profiles").update({"coins": new_balance}).eq("email", order.user_email).execute()
        # -------------------------------

        return {"message": f"Order placed! You earned {coins_earned} Coins! 🪙"}
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

@app.post("/place_order")
def place_order(order: Order):
    try:
        # 1. Insert Order into Database
        order_data = {
            "user_email": order.user_email,
            "items": order.items,
            "total_price": order.total_price,
            "status": "Pending" # Default status
        }
        supabase.table("orders").insert(order_data).execute()

        # --- NEW: LOYALTY COIN LOGIC ---
        # 1. Calculate coins (10% of total price)
        coins_earned = int(order.total_price * 0.10)
        
        # 2. Get current coins from 'profiles' table
        current_profile = supabase.table("profiles").select("coins").eq("email", order.user_email).execute()
        
        # If profile exists, get coins. If not, start at 0.
        current_coins = current_profile.data[0]['coins'] if current_profile.data else 0
        
        # 3. Update new balance
        new_balance = current_coins + coins_earned
        
        # Check if profile exists to decide between UPDATE or INSERT
        if current_profile.data:
            supabase.table("profiles").update({"coins": new_balance}).eq("email", order.user_email).execute()
        else:
            # Create profile if it doesn't exist yet
            supabase.table("profiles").insert({"email": order.user_email, "coins": new_balance}).execute()
        # -------------------------------

        return {"message": f"Order placed! You earned {coins_earned} Coins! 🪙"}

    except Exception as e:
        return {"error": str(e)}

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
# --- 10. WISHLIST SYSTEM ---
class WishlistItem(BaseModel):
    user_email: str
    product_name: str
    image_url: str
    price: float

@app.post("/add_wishlist")
def add_wishlist(item: WishlistItem):
    try:
        # Check if already exists to prevent duplicates
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
# --- 11. VISUAL SEARCH AI (Color Detection) ---
@app.post("/visual_search")
async def visual_search(file: UploadFile = File(...)):
    try:
        # 1. Read Image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert('RGB')
        
        # 2. Resize for speed (Analysis)
        image = image.resize((100, 100))
        img_array = np.array(image)
        
        # 3. Calculate Average RGB
        avg_color_per_row = np.average(img_array, axis=0)
        avg_color = np.average(avg_color_per_row, axis=0)
        r, g, b = avg_color
        
        # 4. AI Logic (Heuristic Classification)
        detected_item = "Unknown"
        confidence = 0.0
        
        # RED DOMINANT (Tomato, Apple)
        if r > g + 20 and r > b + 20:
            detected_item = "Fresh Tomato" # Matches DB Name
            confidence = 92.5
        
        # GREEN DOMINANT (Spinach, Chili)
        elif g > r + 10 and g > b + 10:
            detected_item = "Spinach (Palak)"
            confidence = 88.3
            
        # YELLOW DOMINANT (Red + Green are high)
        elif r > 150 and g > 150 and b < 100:
            detected_item = "Banana"
            confidence = 95.1
            
        # WHITE/BROWN (Potato, Onion)
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