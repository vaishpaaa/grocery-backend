import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Import main to access HomeScreen

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true; 
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> authenticate() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        isLogin ? 'https://vaishnavi-api.onrender.com/login' : 'https://vaishnavi-api.onrender.com/signup');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailController.text,
          "password": passwordController.text
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save Login State
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', emailController.text);
        
        // Update Global Variable
        currentUserEmail = emailController.text;

        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? "Auth Failed"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream Background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, size: 80, color: const Color(0xFF5D4037)), // Brown Icon
                const SizedBox(height: 20),
                Text(
                  isLogin ? "Welcome Back" : "Create Account",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.brown),
                    prefixIcon: const Icon(Icons.email, color: Colors.brown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5D4037))),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.brown),
                    prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5D4037))),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037), // Brown Button
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(isLogin ? "LOGIN" : "SIGN UP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin ? "New here? Create Account" : "Already have an account? Login",
                    style: const TextStyle(color: Color(0xFF5D4037)), // Brown Text
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}