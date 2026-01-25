import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart'; 
import 'main.dart'; 
import 'cart.dart'; 

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Razorpay _razorpay; 

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear(); 
  }

  void openCheckout() {
    if (globalCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cart is empty!")));
      return;
    }
    double totalAmount = globalCart.fold(0.0, (sum, item) => sum + (item['price'] as num));

    var options = {
      'key': 'rzp_test_S6zkdC0PK4Nb1S', 
      'amount': (totalAmount * 100).toInt(), 
      'name': 'Vaishnav Market',
      'description': 'Grocery Bill',
      'timeout': 180, 
      'prefill': {'contact': '9876543210', 'email': currentUserEmail},
      'theme': {'color': '#5D4037'} // Brown Payment Screen
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/place_order');
    double totalAmount = globalCart.fold(0.0, (sum, item) => sum + (item['price'] as num));

    final body = {
      "user_email": currentUserEmail, 
      "items": globalCart,
      "total_price": totalAmount,
      "payment_id": response.paymentId 
    };

    try {
      final res = await http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode(body));
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() { globalCart.clear(); });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xFFFFF8E1),
            title: const Text("Order Placed! 🥖", style: TextStyle(color: Color(0xFF5D4037))),
            content: const Text("Your fresh groceries will be delivered soon."),
            actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("OK", style: TextStyle(color: Color(0xFF5D4037))))],
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    double totalAmount = globalCart.fold(0.0, (sum, item) => sum + (item['price'] as num));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D4037), // Brown
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: globalCart.isEmpty
          ? const Center(child: Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.brown)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: globalCart.length,
                    itemBuilder: (context, index) {
                      final item = globalCart[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(image: NetworkImage(item['image_url'] ?? ""), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3E2723))),
                                  Text("₹${item['price']}", style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() { globalCart.removeAt(index); });
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("₹$totalAmount", style: const TextStyle(fontSize: 22, color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: openCheckout, 
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text("CHECKOUT & PAY", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}