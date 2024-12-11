import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final schoolId = _schoolIdController.text.trim();
    final password = _passwordController.text.trim();

    if (schoolId.isEmpty || password.isEmpty) {
      _showMessage('Please enter both school ID and password.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Try to login with school ID
    final loginData = await _authService.loginWithSchoolId(schoolId, password);

    setState(() {
      _isLoading = false;
    });

    if (loginData['success']) {
      var userData = loginData['user'];  // This is the user data fetched from Firestore

      // Save user data locally (example using SharedPreferences)
      _saveUserDataLocally(userData);

      _showMessage(loginData['message']);
      Navigator.pushReplacementNamed(context, '/homepage');
    } else {
      _showMessage(loginData['message'] ?? 'Invalid credentials. Please try again.');
    }
  }

  void _saveUserDataLocally(Map<String, dynamic> userData) {
    // Save user data to SharedPreferences (already done in AuthService)
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.purpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'U-Find',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
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
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/registration');
                  },
                  child: const Text('Sign up', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
