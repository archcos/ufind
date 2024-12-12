import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'dart:convert'; // For hashing
import 'package:crypto/crypto.dart'; // For hashing passwords
import 'package:flutter/services.dart'; // For input formatters

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

  bool _isRegistering = false;
  bool _isPasswordHidden = true;

  void _handleRegister() async {
    if (_isRegistering) return; // Prevent multiple clicks

    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String schoolId = _schoolIdController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || schoolId.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill all the fields.');
      return;
    }

    // Validate that schoolId is exactly 10 digits
    if (schoolId.length != 10) {
      _showMessage('School ID must be exactly 10 digits.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot existingDoc = await FirebaseFirestore.instance.collection('users').doc(schoolId).get();

      if (existingDoc.exists) {
        _showMessage('A user with this School ID already exists.');
        setState(() {
          _isRegistering = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(schoolId).set({
        'first_name': firstName,
        'last_name': lastName,
        'school_id': schoolId,
        'email': email,
        'password': hashPassword(password),
        'created_at': FieldValue.serverTimestamp(),
      });

      _showMessage('Registration Successful! Please login now with your school ID');
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showMessage('Registration failed: $e');
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
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
              colors: [Colors.teal, Colors.cyan],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
              const SizedBox(height: 20),
              const Text(
                'U-Find Registration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField(_firstNameController, 'First Name', Icons.person),
              const SizedBox(height: 10),
              _buildTextField(_lastNameController, 'Last Name', Icons.person),
              const SizedBox(height: 10),
              _buildTextField(_schoolIdController, 'School ID', Icons.school, isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(_emailController, 'Email', Icons.email),
              const SizedBox(height: 10),
              _buildPasswordField(),
              const SizedBox(height: 30),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isRegistering ? 60 : MediaQuery.of(context).size.width * 0.8, // Use a relative width
                height: 60,
                child: ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_isRegistering ? 30 : 10),
                    ),
                  ),
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.blue)
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

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
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),    // Limit to 10 digits
            ]
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.blue),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _isPasswordHidden,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordHidden ? Icons.visibility : Icons.visibility_off,
            color: Colors.blue,
          ),
          onPressed: () {
            setState(() {
              _isPasswordHidden = !_isPasswordHidden;
            });
          },
        ),
      ),
    );
  }
}