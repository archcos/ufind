import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'dart:convert'; // For hashing
import 'package:crypto/crypto.dart'; // For hashing passwords

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleRegister() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String schoolId = _schoolIdController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || schoolId.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill all the fields.');
      return;
    }

    try {
      // Register user with Firebase Auth (email & password)
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the school ID already exists in Firestore
      DocumentSnapshot existingDoc = await FirebaseFirestore.instance.collection('users').doc(schoolId).get();

      if (existingDoc.exists) {
        _showMessage('A user with this School ID already exists.');
        return;
      }

      // After user is created, store additional user information in Firestore
      await FirebaseFirestore.instance.collection('users').doc(schoolId).set({
        'first_name': firstName,
        'last_name': lastName,
        'school_id': schoolId,
        'email': email,
        'password': hashPassword(password), // Storing hashed password
        'created_at': FieldValue.serverTimestamp(),
      });

      _showMessage('Registration successful!');
      Navigator.pushReplacementNamed(context, '/'); // Navigate to login or home page
    } catch (e) {
      _showMessage('Registration failed: $e');
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    return sha256.convert(bytes).toString(); // Hash password with SHA-256
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.blueAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/images/logo.png'), // Replace with your logo
              ),
              const SizedBox(height: 20),
              const Text(
                'U-Find Registration',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // First Name Input
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'First Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),

              // Last Name Input
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Last Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),

              // School ID Input
              TextField(
                controller: _schoolIdController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'School ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.school, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),

              // Email Input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 30),

              // Register Button
              ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Already have an account?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text('Login', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
