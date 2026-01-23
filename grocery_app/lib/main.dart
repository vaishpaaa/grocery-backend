import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart'; 
import 'login_page.dart';
import 'cart.dart'; 
import 'cart_page.dart';
import 'orders_page.dart'; // <--- Make sure this is imported

String currentUserEmail = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Check Memory before app starts
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  
  if(isLoggedIn) {
    currentUserEmail = prefs.getString('userEmail') ?? "";
  }

  globalCart.clear(); 
  
  runApp(GroceryApp(startHome: isLoggedIn));
}

class GroceryApp extends StatelessWidget {
  final bool startHome; 
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
      home: startHome ? const HomeScreen() : const LoginPage(),
    );
  }
}

// --- UPDATED HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = []; 
  List<dynamic> banners = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController(); 

  // --- VARIABLES FOR CATEGORIES ---
  final List<String> categories = ["All", "Vegetables", "Fruits", "Dairy", "General"];
  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([fetchProducts(), fetchBanners()]);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/products'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          filteredProducts = products; // Initially, show everything
        });
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  // --- FILTER BY SEARCH TEXT ---
  void runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = products; 
    } else {
      results = products
          .where((item) => item["name"].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredProducts = results; 
      selectedCategory = "All"; // Reset category when searching
    });
  }

  // --- FILTER BY CATEGORY BUTTONS ---
  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      searchController.clear(); // Clear search bar when clicking category
      
      if (category == "All") {
        filteredProducts = products;
      } else {
        filteredProducts = products
            .where((item) => item["category"] == category) // Checks the database column
            .toList();
      }
    });
  }

  Future<void> fetchBanners() async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/banners');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        banners = json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching banners: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        title: const Text("Vaishnav's Market", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // --- NEW: HISTORY BUTTON ---
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white), // Clock Icon
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage()));
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- 1. SEARCH BAR ---
                  Container(
                    color: Colors.green,
                    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => runFilter(value), 
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Search for milk, vegetables...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // --- 2. CAROUSEL SLIDER (BANNERS) ---
                  if (banners.isNotEmpty)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 180.0,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 0.9,
                      ),
                      items: banners.map((banner) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: NetworkImage(banner['image_url']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 15),

                  // --- 3. CATEGORY CHIPS (Horizontal List) ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: Colors.green,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.grey[200],
                            onSelected: (bool selected) {
                              if (selected) filterByCategory(category);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Text("Shop by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  // --- 4. PRODUCT GRID ---
                  filteredProducts.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: Text("No items found in this category")),
                    )
                  : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: filteredProducts.length, 
                    itemBuilder: (context, index) {
                      final item = filteredProducts[index]; 
                      return ProductCard(item: item);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// --- PRODUCT CARD & DETAIL SCREEN ---

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
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: item['name'], 
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      item['image_url'] ?? "",
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹${item['price']}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                        child: const Text("ADD", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
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
                          globalCart.add({
                            "name": item['name'], 
                            "price": item['price'], 
                            "image_url": item['image_url'] 
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