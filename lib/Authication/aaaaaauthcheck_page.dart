import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app/Authication/login_page.dart';
import 'package:food_app/screan/home_page.dart';

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Check if user is logged in
    User? user = _auth.currentUser;
    
    // Add a small delay to show loading screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (user != null) {
      // User is logged in, go to home page
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => AllResturentList())
      );
    } else {
      // User is not logged in, go to login page
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 50,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Loading Indicator
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            
            const SizedBox(height: 20),
            
            // Loading Text
            const Text(
              'Checking...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}