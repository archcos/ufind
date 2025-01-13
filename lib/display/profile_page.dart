import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'signin_page.dart';  // Import the SigninPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  String? userId;  // Use String for userId (since it's stored as a document ID)

  @override
  void initState() {
    super.initState();
    _loadUserData();  // Fetch user data from SharedPreferences
  }

  // Fetch user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('user_first_name');
    final lastName = prefs.getString('user_last_name');
    final contactNumber = prefs.getString('contact_number');
    final schoolId = prefs.getString('user_school_id'); // school_id is stored as String

    if (schoolId == null) {
      // If user data is not found, navigate to SignInPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SigninPage()),
      );
    } else {
      setState(() {
        _firstNameController.text = firstName ?? '';
        _lastNameController.text = lastName ?? '';
        _contactNumberController.text = contactNumber ?? '';
        _schoolIdController.text = schoolId; // schoolId as String
        _passwordController.text = ''; // Clear password field as it's sensitive data
        userId = schoolId; // Set userId to schoolId
      });
    }
  }

  // Save the updated profile
  Future<void> saveProfile() async {
    if (userId != null) {
      final success = await AuthService().updateProfile(
        userId!,  // Pass userId (schoolId) as String
        _firstNameController.text,
        _lastNameController.text,
        _contactNumberController.text,
        _passwordController.text, // Pass the password for update
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated! Relogin to see changes.')),
        );

        // Save updated data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_first_name', _firstNameController.text);
        await prefs.setString('user_last_name', _lastNameController.text);
        await prefs.setString('contact_number', _contactNumberController.text);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is missing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If userId is null, show loading spinner until data is fetched
    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show loading until userId is fetched
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile picture section (Just a placeholder here)
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/profile.jpg'), // Replace with actual image
              ),
              const SizedBox(height: 16),

              // Text fields for user details
              Column(
                children: [
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12), // Add spacing between fields
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _schoolIdController,
                    readOnly: true, // School ID is used as the document ID, so it's read-only
                    decoration: const InputDecoration(
                      labelText: 'School ID',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Save Button
              ElevatedButton(
                onPressed: saveProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
