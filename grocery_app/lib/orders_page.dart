import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart'; 

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (currentUserEmail.isEmpty) { setState(() => isLoading = false); return; }
    final url = Uri.parse('https://vaishnavi-api.onrender.com/user_orders/$currentUserEmail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() { orders = json.decode(response.body); isLoading = false; });
      } else { setState(() => isLoading = false); }
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D4037), // Brown
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : orders.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.brown[200]), const Text("No orders yet", style: TextStyle(fontSize: 18, color: Colors.brown))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items = order['items'] as List<dynamic>;
                    final date = order['created_at'].toString().substring(0, 10);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: const Color(0xFFD7CCC8), borderRadius: const BorderRadius.vertical(top: Radius.circular(15))), // Light Brown Header
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("ORDER #${order['id']}", style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037), fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(20)), child: const Text("Success", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Text("• ${item['name']}", style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text("₹${item['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown))]))).toList()),
                          ),
                          const Divider(height: 1),
                          Padding(padding: const EdgeInsets.all(15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Paid", style: TextStyle(fontWeight: FontWeight.bold)), Text("₹${order['total_price']}", style: const TextStyle(fontSize: 18, color: Color(0xFF5D4037), fontWeight: FontWeight.bold))]))
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}