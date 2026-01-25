import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart'; 
import 'login_page.dart';
import 'cart.dart'; 
import 'cart_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';
import 'admin_page.dart'; 
import 'splash_screen.dart';
import 'wishlist_page.dart';

String currentUserEmail = "";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Note: We removed the SharedPreferences check here because 
  // the Splash Screen will handle it now!
  runApp(const GroceryApp());
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'V S M',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        primaryColor: const Color(0xFF5D4037),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D4037),
          primary: const Color(0xFF5D4037),
          secondary: const Color(0xFF8D6E63),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5D4037),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        useMaterial3: true,
      ),
      // START WITH SPLASH SCREEN
      home: const SplashScreen(),
    );
  }
}

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
          filteredProducts = products; 
        });
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

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
      selectedCategory = "All"; 
    });
  }

  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      searchController.clear();
      if (category == "All") {
        filteredProducts = products;
      } else {
        filteredProducts = products
            .where((item) => item["category"] == category)
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
      appBar: AppBar(
        title: const Text("V S M"),
        actions: [
          if (currentUserEmail == "vaishpaa@gmail.com") 
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage()));
              },
            ),
          
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
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
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistPage())),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)))
          : SafeArea( // ADDED SAFE AREA
              child: SingleChildScrollView( 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar Area (Brown)
                    Container(
                      color: const Color(0xFF5D4037), 
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20), // Better Padding
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) => runFilter(value), 
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Search for bread, coffee...",
                          hintStyle: TextStyle(color: Colors.brown[300]),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF5D4037)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), 

                    // Banners
                    if (banners.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 160.0, // Slightly reduced for better ratio
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.92, // Shows peek of next banner
                        ),
                        items: banners.map((banner) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                                  image: DecorationImage(image: NetworkImage(banner['image_url']), fit: BoxFit.cover),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 24), // Vertical Rhythm

                    // Categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Align with screen edge
                      child: Row(
                        children: categories.map((category) {
                          final isSelected = selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12), // Consistent spacing
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              selectedColor: const Color(0xFF5D4037), 
                              labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF5D4037), fontWeight: FontWeight.bold),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFF5D4037).withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onSelected: (bool selected) {
                                if (selected) filterByCategory(category);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12), // Title Padding
                      child: Text(
                        "Fresh Picks For You", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF3E2723), letterSpacing: 0.5)
                      )
                    ),
                    
                    // Product Grid
                    filteredProducts.isEmpty 
                    ? const Padding(padding: EdgeInsets.all(50.0), child: Center(child: Text("No items found")))
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Screen Edge Padding
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        childAspectRatio: 0.72, // PERFECT RATIO for Image + Text + Button
                        crossAxisSpacing: 16,   // Space between cards horizontally
                        mainAxisSpacing: 16,    // Space between cards vertically
                      ),
                      itemCount: filteredProducts.length, 
                      itemBuilder: (context, index) {
                        return ProductCard(item: filteredProducts[index]);
                      },
                    ),
                    const SizedBox(height: 40), // Bottom breathing room
                  ],
                ),
              ),
            ),
    );
  }
}

// --- SMART PRODUCT CARD (UPDATED WITH WISHLIST) ---
class ProductCard extends StatefulWidget {
  final dynamic item;
  const ProductCard({super.key, required this.item});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 0;
  late int stock; 

  @override
  void initState() {
    super.initState();
    stock = widget.item['stock_quantity'] ?? 0;
    quantity = globalCart.where((element) => element['name'] == widget.item['name']).length;
  }

  void _increment() {
    if (quantity >= stock) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No more stock available!"), duration: Duration(seconds: 1)));
       return;
    }

    if (quantity < 5) {
      setState(() {
        quantity++;
      });
      globalCart.add({
        "name": widget.item['name'], 
        "price": widget.item['price'], 
        "image_url": widget.item['image_url']
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max limit is 5 items!"), duration: Duration(seconds: 1)));
    }
  }

  void _decrement() {
    if (quantity > 0) {
      setState(() {
        quantity--;
      });
      for (var i = 0; i < globalCart.length; i++) {
        if (globalCart[i]['name'] == widget.item['name']) {
          globalCart.removeAt(i);
          break; 
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOutOfStock = stock <= 0;

    return GestureDetector(
      onTap: () {
        if (!isOutOfStock) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(item: widget.item)));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Modern 16px radius
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D4037).withOpacity(0.08), // Very subtle brown shadow
              blurRadius: 15,
              offset: const Offset(0, 5), 
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. IMAGE SECTION (Flexible Height) ---
            Expanded(
              flex: 4, // Takes 4/7th of the card
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: ColorFiltered(
                      colorFilter: isOutOfStock 
                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) 
                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: Image.network(
                        widget.item['image_url'] ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                      ),
                    ),
                  ),
                  if (isOutOfStock)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const Text("SOLD OUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                    ),
                  if (!isOutOfStock && stock < 5)
                     Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                        child: Text("$stock left!", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  
                  // --- HEART BUTTON (Top Right) ---
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final url = Uri.parse('https://vaishnavi-api.onrender.com/add_wishlist');
                        await http.post(url, 
                          headers: {"Content-Type": "application/json"},
                          body: json.encode({
                            "user_email": currentUserEmail,
                            "product_name": widget.item['name'],
                            "image_url": widget.item['image_url'],
                            "price": widget.item['price']
                          })
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Wishlist! ❤️"), duration: Duration(milliseconds: 800)));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                        child: const Icon(Icons.favorite_border, size: 18, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- 2. DETAILS SECTION ---
            Expanded(
              flex: 3, // Takes 3/7th of the card
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes button to bottom
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w700, 
                            fontSize: 15, 
                            color: isOutOfStock ? Colors.grey : const Color(0xFF3E2723)
                          ), 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Standard Delivery", 
                          style: TextStyle(fontSize: 10, color: Colors.brown[300]),
                        ),
                      ],
                    ),
                    
                    // Price & Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${widget.item['price']}",
                          style: TextStyle(
                            color: isOutOfStock ? Colors.grey[400] : const Color(0xFF5D4037), 
                            fontWeight: FontWeight.w800, 
                            fontSize: 16
                          ),
                        ),
                        
                        // Compact Button
                        if (!isOutOfStock)
                          quantity == 0 
                          ? SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: _increment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFF8E1), // Cream bg
                                  foregroundColor: const Color(0xFF5D4037), // Brown text
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFF5D4037)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12)
                                ),
                                child: const Text("ADD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            )
                          : Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D4037),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 12, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 25),
                                    onPressed: _decrement,
                                  ),
                                  Text("$quantity", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 12, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 25),
                                    onPressed: _increment,
                                  ),
                                ],
                              ),
                            )
                      ],
                    )
                  ],
                ),
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
            backgroundColor: const Color(0xFF5D4037),
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: item['name'],
                child: Image.network(item['image_url'], fit: BoxFit.cover),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24), // Consistent 24px padding for details
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                    const SizedBox(height: 12),
                    Text("₹ ${item['price']}", style: const TextStyle(fontSize: 24, color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text("Premium quality product sourced for Vaishnav's Market.", style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Slightly taller button
                      child: ElevatedButton(
                        onPressed: () {
                          globalCart.add({"name": item['name'], "price": item['price'], "image_url": item['image_url']});
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item['name']} added!"), backgroundColor: Colors.brown));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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