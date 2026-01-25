import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Add this to pubspec.yaml later
import 'main.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final url = Uri.parse('https://vaishnavi-api.onrender.com/get_profile/$currentUserEmail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() { 
          _addressController.text = data['address'] ?? ""; 
          _phoneController.text = data['phone'] ?? ""; 
          isLoading = false; 
        });
      }
    } catch (e) { setState(() => isLoading = false); }
  }

  Future<void> saveProfile() async {
    setState(() => isLoading = true);
    final url = Uri.parse('https://vaishnavi-api.onrender.com/update_profile');
    final body = { "email": currentUserEmail, "address": _addressController.text, "phone": _phoneController.text };
    try {
      await http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode(body));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved! 🍞"), backgroundColor: Color(0xFF5D4037)));
    } catch (e) { print(e); }
    setState(() => isLoading = false);
  }

  // --- NEW: SUPPORT FUNCTIONS ---
  void _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text("My Account"), 
        backgroundColor: const Color(0xFF5D4037), 
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: isLoading 
      ? const Center(child: CircularProgressIndicator(color: Colors.brown)) 
      : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROFILE HEADER
            Center(
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Color(0xFF5D4037), child: Icon(Icons.person, size: 40, color: Colors.white)), 
                  const SizedBox(height: 10), 
                  Text(currentUserEmail, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)))
                ]
              )
            ),
            const SizedBox(height: 30),
            
            // --- EDIT DETAILS SECTION ---
            const Text("Contact Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5D4037))),
            const SizedBox(height: 15),
            _buildTextField("Phone Number", Icons.phone, _phoneController),
            const SizedBox(height: 15),
            _buildTextField("Delivery Address", Icons.home, _addressController, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton(
                onPressed: saveProfile, 
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              )
            ),

            const SizedBox(height: 40),
            const Divider(color: Colors.brown),
            const SizedBox(height: 20),

            // --- SUPPORT SECTION (NEW) ---
            const Text("Support & Legal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5D4037))),
            const SizedBox(height: 10),
            
            ListTile(
              leading: const Icon(Icons.call, color: Colors.brown),
              title: const Text("Call Support"),
              subtitle: const Text("+91 98765 43210"),
              onTap: () => _launchURL("tel:+919876543210"),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text("WhatsApp Us"),
              onTap: () => _launchURL("https://wa.me/919876543210"),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blueGrey),
              title: const Text("Privacy Policy"),
              onTap: () => _launchURL("https://www.termsfeed.com/live/your-privacy-policy-link"), // Replace later
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.brown),
        prefixIcon: Icon(icon, color: Colors.brown),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}