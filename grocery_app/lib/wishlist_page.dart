import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart'; // To access globalCart and currentUserEmail
import 'cart.dart'; // To access cart logic

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<dynamic> wishlist = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/get_wishlist/$currentUserEmail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          wishlist = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> removeFromWishlist(String productName) async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/remove_wishlist?email=$currentUserEmail&product_name=$productName');
    await http.delete(url);
    fetchWishlist(); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Wishlist"), duration: Duration(seconds: 1)));
  }

  void moveToCart(dynamic item) {
    globalCart.add({
      "name": item['product_name'],
      "price": item['price'],
      "image_url": item['image_url']
    });
    removeFromWishlist(item['product_name']); // Optional: Remove after adding to cart
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Moved to Cart! 🛒"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text("My Wishlist ❤️"),
        backgroundColor: const Color(0xFF5D4037),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : wishlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.brown[200]),
                      const SizedBox(height: 10),
                      const Text("No favorites yet!", style: TextStyle(fontSize: 18, color: Colors.brown)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: wishlist.length,
                  itemBuilder: (context, index) {
                    final item = wishlist[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(item['image_url'], width: 70, height: 70, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("₹${item['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_checkout, color: Colors.green),
                            onPressed: () => moveToCart(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeFromWishlist(item['product_name']),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}