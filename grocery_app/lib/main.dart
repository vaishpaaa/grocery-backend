import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // <--- Import this
import 'login_page.dart';
import 'cart.dart'; 
import 'cart_page.dart';
import 'orders_page.dart';

String currentUserEmail = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async main
  
  // Check Memory before app starts
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  
  if(isLoggedIn) {
    currentUserEmail = prefs.getString('userEmail') ?? "";
  }

  globalCart.clear(); 
  
  // Pass the login state to the app
  runApp(GroceryApp(startHome: isLoggedIn));
}

class GroceryApp extends StatelessWidget {
  final bool startHome; // Receive the decision
  const GroceryApp({super.key, required this.startHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery App',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, primary: Colors.green),
        useMaterial3: true,
      ),
      // Decide which page to show first!
      home: startHome ? const HomeScreen() : const LoginPage(),
    );
  }
}

// ... Keep HomeScreen and the rest of the file the same ...
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    // Using 127.0.0.1 for USB connection
    final url = Uri.parse('https://vaishnavi-api.onrender.com/products'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print("Error: $e");
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
          ),
        ),
        title: const Text("Vaishnav's Market", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Wipe memory
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage())),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // Adjusted for better fit
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final item = products[index];
                  return ProductCard(item: item);
                },
              ),
            ),
    );
  }
}

// --- BEAUTIFUL CARD COMPONENT ---
class ProductCard extends StatelessWidget {
  final dynamic item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => ProductDetailScreen(item: item)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with HERO Animation
            Expanded(
              child: Hero(
                tag: item['name'], 
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      item['image_url'] ?? "",
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹ ${item['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PRODUCT DETAIL SCREEN ---
class ProductDetailScreen extends StatelessWidget {
  final dynamic item;
  const ProductDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: item['name'],
                child: Image.network(
                  item['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(color: Colors.grey[200]),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("₹ ${item['price']}", style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text(
                      "This is a premium quality product sourced directly from the best farms. Fresh, organic, and perfect for your daily needs.",
                      style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // --- UPDATED ADD TO CART LOGIC ---
                          globalCart.add({
                            "name": item['name'], 
                            "price": item['price'], 
                            "image_url": item['image_url'] // Saves Image Now!
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${item['name']} added to cart!"), backgroundColor: Colors.green),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("ADD TO CART", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }
}