import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // <--- NEW IMPORT
import 'main.dart'; // Imports the HomeScreen AND the currentUserEmail variable

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true; // Toggle between Login and Signup
  bool isLoading = false;

  Future<void> handleAuth() async {
    setState(() { isLoading = true; });

    // Ensure we are hitting the correct endpoint
    final endpoint = isLogin ? "login" : "signup";
    
    // Using your Cloud Render URL
    final url = Uri.parse('https://vaishnavi-api.onrender.com/$endpoint');

    print("Attempting to connect to: $url"); // Debug print

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      // STRICT SECURITY CHECK
      if (response.statusCode == 200) {
        // SUCCESS
        
        if (isLogin) {
          if (mounted) {
             // --- SAVE TO MEMORY (PERSISTENT LOGIN) ---
             final prefs = await SharedPreferences.getInstance();
             await prefs.setBool('isLoggedIn', true);
             await prefs.setString('userEmail', emailController.text);

             // Update global variable so the rest of the app knows immediately
             currentUserEmail = emailController.text; 
             
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          }
        } else {
          // Signup Success
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account Created! Please Login."), backgroundColor: Colors.green),
            );
            setState(() { isLogin = true; }); // Switch to login screen
          }
        }
      } else {
        // FAILURE (Wrong Password, etc.)
        final data = json.decode(response.body);
        final errorMessage = data['error'] ?? data['detail'] ?? "Authentication Failed";
        
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin ? "Welcome Back" : "Join Us",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 20),
                  isLoading 
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleAuth,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                          child: Text(isLogin ? "LOGIN" : "SIGN UP", style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                  TextButton(
                    onPressed: () {
                      setState(() { isLogin = !isLogin; });
                    },
                    child: Text(isLogin ? "New here? Create Account" : "Already have an account? Login"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}