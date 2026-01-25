import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'login_page.dart';
import 'main.dart'; // To access HomeScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // 1. Setup Animation (Fade In)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // 2. Start Timer
    navigateAfterDelay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> navigateAfterDelay() async {
    // Wait for 3 seconds for branding effect
    await Future.delayed(const Duration(seconds: 3));

    // Check Login Status
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => isLoggedIn ? const HomeScreen() : const LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5D4037), // Dark Brown Background
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- BIG LOGO ICON ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: const Icon(Icons.storefront_outlined, size: 80, color: Color(0xFF5D4037)),
              ),
              
              const SizedBox(height: 30),
              
              // --- APP NAME ---
              const Text(
                "vaishnavi\nsuper Market",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto', // Or use GoogleFonts.playfairDisplay() if added
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // --- LOADING SPINNER ---
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}