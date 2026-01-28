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
import 'package:speech_to_text/speech_to_text.dart' as stt; // <--- ADD THIS
String currentUserEmail = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  if(isLoggedIn) {
    currentUserEmail = prefs.getString('userEmail') ?? "";
  }

  runApp(const GroceryApp());
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vaishnavi super market',
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
  int userCoins = 0;
  TextEditingController searchController = TextEditingController(); 

  // --- VOICE SEARCH VARIABLES ---
  late stt.SpeechToText _speech;
  bool _isListening = false;
  // -----------------------------

  final List<String> categories = ["All", "Vegetables", "Fruits", "Dairy", "General"];
  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText(); // Initialize Speech
    fetchData();
  }

  // --- VOICE SEARCH FUNCTION ---
  // --- UPDATED SMART VOICE SEARCH ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        // 1. AUTO-DISABLE LOGIC: Turn off mic when phone says 'done' or 'notListening'
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() => _isListening = false); // Turn off on error too
        },
      );

      if (available) {
        setState(() => _isListening = true); // Turn ON Red Icon
        _speech.listen(
          onResult: (val) {
            setState(() {
              searchController.text = val.recognizedWords;
              runFilter(val.recognizedWords);
            });
          },
        );
      }
    } else {
      // 2. MANUAL DISABLE: If user taps again, stop immediately
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
  // ----------------------------------
  // -----------------------------

  Future<void> fetchData() async {
    await Future.wait([fetchProducts(), fetchBanners(), fetchCoins()]);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCoins() async {
    if (currentUserEmail.isEmpty) return;
    try {
      final url = Uri.parse('https://vaishnavi-api.onrender.com/get_profile/$currentUserEmail');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userCoins = data['coins'] ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching coins: $e");
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
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF5D4037)),
              accountName: const Text("Welcome back,", style: TextStyle(fontSize: 14, color: Colors.white70)),
              accountEmail: Text(currentUserEmail, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF5D4037)),
              ),
            ),
            if (currentUserEmail == "vaishpaa@gmail.com")
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.brown),
                title: const Text("Admin Panel"),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage())),
              ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.brown),
              title: const Text("My Profile"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.brown),
              title: const Text("Order History"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if(!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Vaishnav's Market"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            color: const Color(0xFF4E342E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Loyalty Balance: ", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text("$userCoins Coins", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistPage())),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)))
          : SafeArea(
              child: SingleChildScrollView( 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SEARCH BAR WITH VOICE MIC ---
                    Container(
                      color: const Color(0xFF5D4037), 
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) => runFilter(value), 
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: _isListening ? "Listening..." : "Search items...",
                          hintStyle: TextStyle(color: _isListening ? Colors.red : Colors.brown[300]),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF5D4037)),
                          // MIC ICON BUTTON
                          suffixIcon: IconButton(
                            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.brown),
                            onPressed: _listen,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    // ---------------------------------

                    const SizedBox(height: 20), 

                    if (banners.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 160.0,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.92,
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
                    
                    const SizedBox(height: 24),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: categories.map((category) {
                          final isSelected = selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
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
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        "Fresh Picks For You", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF3E2723), letterSpacing: 0.5)
                      )
                    ),
                    
                    filteredProducts.isEmpty 
                    ? const Padding(padding: EdgeInsets.all(50.0), child: Center(child: Text("No items found")))
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredProducts.length, 
                      itemBuilder: (context, index) {
                        return ProductCard(item: filteredProducts[index]);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
// --- PRODUCT CARD (Stock, Wishlist & Heart) ---
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D4037).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5), 
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Expanded(
              flex: 4,
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
                  
                  // HEART BUTTON
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        if (currentUserEmail.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
                           return;
                        }
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
            
            // DETAILS SECTION
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        
                        if (!isOutOfStock)
                          quantity == 0 
                          ? SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: _increment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFF8E1),
                                  foregroundColor: const Color(0xFF5D4037),
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
                padding: const EdgeInsets.all(24),
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
                      height: 56,
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