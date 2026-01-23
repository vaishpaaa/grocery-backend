import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart'; // To get currentUserEmail

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String debugMessage = ""; // To show errors on screen

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    // 1. Check Email
    if (currentUserEmail.isEmpty) {
      setState(() {
        isLoading = false;
        debugMessage = "Error: Not Logged In (Email is empty)";
      });
      return;
    }

    // 2. Check URL
    final url = Uri.parse('https://vaishnavi-api.onrender.com/user_orders/$currentUserEmail');
    print("Fetching from: $url"); // Check your terminal for this!

    try {
      final response = await http.get(url);
      
      // 3. Check Server Response
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = data;
          isLoading = false;
          debugMessage = "Found ${data.length} orders";
        });
      } else {
        setState(() {
          isLoading = false;
          debugMessage = "Server Error: ${response.statusCode} (Not Found?)";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        debugMessage = "Connection Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // DEBUG PANEL (Shows what's happening)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.yellow[100],
            child: Text("Debug: $currentUserEmail \nStatus: $debugMessage", 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(child: Text("No orders found.", style: TextStyle(fontSize: 18, color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final items = order['items'] as List<dynamic>;
                          final date = order['created_at'].toString().split('T')[0];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Ordered on $date", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      Text("₹${order['total_price']}", style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Divider(),
                                  ...items.map((item) => Text("• ${item['name']}", style: const TextStyle(fontSize: 14))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}