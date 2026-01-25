import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> allOrders = [];
  List<dynamic> products = []; // To store stock info
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([fetchAllOrders(), fetchStock()]);
    setState(() => isLoading = false);
  }

  Future<void> fetchAllOrders() async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/admin/all_orders');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        allOrders = json.decode(response.body);
      }
    } catch (e) {
      print("Admin Error: $e");
    }
  }

  Future<void> fetchStock() async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        products = json.decode(response.body);
      }
    } catch (e) {
      print("Stock Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Manager Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "Orders"),
            Tab(icon: Icon(Icons.inventory), text: "Stock Alerts"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: ORDERS LIST (What you already had)
                _buildOrdersList(),

                // TAB 2: AI STOCK ALERTS (New!)
                _buildStockAlerts(),
              ],
            ),
    );
  }

  Widget _buildOrdersList() {
    if (allOrders.isEmpty) return const Center(child: Text("No orders yet!"));
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: allOrders.length,
      itemBuilder: (context, index) {
        final order = allOrders[index];
        final items = order['items'] as List<dynamic>;
        final date = order['created_at'].toString().substring(0, 10);
        final address = order['address'] ?? "No Address";

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text("Order #${order['id']} ($date)", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${order['user_email']}\n📍 $address"),
            trailing: Text("₹${order['total_price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        );
      },
    );
  }

  Widget _buildStockAlerts() {
    // AI Logic: Filter only items with stock < 10
    final lowStockItems = products.where((p) => (p['stock_quantity'] ?? 0) < 10).toList();

    if (lowStockItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 60, color: Colors.green[300]),
            const SizedBox(height: 10),
            const Text("All Stock Levels Healthy!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: lowStockItems.length,
      itemBuilder: (context, index) {
        final item = lowStockItems[index];
        final stock = item['stock_quantity'] ?? 0;
        
        return Card(
          color: Colors.red[50],
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Running Low! Action Required."),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: Text("$stock Left", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}