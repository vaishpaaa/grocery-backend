// A simple global list to hold our items
List<Map<String, dynamic>> globalCart = [];

// A helper to calculate total price
double getCartTotal() {
  double total = 0;
  for (var item in globalCart) {
    total += item['price'];
  }
  return total;
}