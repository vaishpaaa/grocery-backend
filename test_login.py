import requests

# 1. Test Signup (Creating a user)
print("--- Testing Signup ---")
my_data = {"email": "vaishpaa@gmail.com", "password": "8099492949@mvl"}

# Send data to your running API
try:
    response = requests.post("http://127.0.0.1:8000/signup", json=my_data)
    print(response.json())
except Exception as e:
    print("Error:", e)

# 2. Test Login (Logging in)
print("\n--- Testing Login ---")
try:
    response = requests.post("http://127.0.0.1:8000/login", json=my_data)
    print(response.json())
except Exception as e:
    print("Error:", e)