import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart.dart'; // Imports the globalCart variable

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  
  // 1. Calculate Total Price dynamically
  double get totalPrice {
    double total = 0;
    for (var item in globalCart) {
      total += item['price'];
    }
    return total;
  }

  // 2. Send Order to Python Backend
  Future<void> placeOrder() async {
    // Using 127.0.0.1 for USB connection (ADB Reverse)
    final url = Uri.parse('https://vaishnavi-api.onrender.com/place_order');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_email": "test@grocery.com", // In a real app, this would be dynamic
          "total_price": totalPrice,
          "items": globalCart
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          globalCart.clear(); // Clear the cart locally after success
        });
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Order Placed Successfully! 🎉"), backgroundColor: Colors.green)
            );
            Navigator.pop(context); // Go back to Home
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Order Failed: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: globalCart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // --- LIST OF CART ITEMS ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: globalCart.length,
                    itemBuilder: (context, index) {
                      final item = globalCart[index];
                      return Dismissible(
                        key: UniqueKey(), // Allows swipe-to-delete animation
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            globalCart.removeAt(index);
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            // --- ROBUST IMAGE LOADER ---
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                // Use the image URL, or a safe fallback if it's missing
                                item['image_url'] ?? "https://placehold.co/100x100/png?text=NoImage",
                                width: 70, 
                                height: 70, 
                                fit: BoxFit.cover,
                                // If the image fails to load, show a red error box and print why
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading image for ${item['name']}: $error");
                                  return Container(
                                    width: 70, 
                                    height: 70, 
                                    color: Colors.red[100], 
                                    child: const Icon(Icons.broken_image, color: Colors.red)
                                  );
                                },
                              ),
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            trailing: Text("₹${item['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // --- CHECKOUT BUTTON SECTION ---
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("₹ $totalPrice", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // Modern sleek black button
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: const Text("CHECKOUT NOW", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}