import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';  // Import AuthService

class HomePage extends StatelessWidget {
  // Create a GlobalKey for the Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  HomePage({super.key});

  // Logout method
  void _logout(BuildContext context) async {
    await AuthService().logOut();  // Call the logOut method from AuthService

    // After logout, navigate to the login page and clear the navigation stack
    Navigator.pushReplacementNamed(context, '/signin');
  }

  // Fetch user full name from SharedPreferences
  Future<String> _getUserFullName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String firstName = prefs.getString('user_first_name') ?? 'User';
    String lastName = prefs.getString('user_last_name') ?? '';
    return '$firstName $lastName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the key to the Scaffold
      appBar: AppBar(
        backgroundColor: Colors.transparent,  // Makes the AppBar transparent
        elevation: 0,  // Removes the shadow of the AppBar
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),  // Menu icon
          onPressed: () {
            // Use the Scaffold key to open the drawer
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          // Profile picture icon in the trailing section
          GestureDetector(
            onTap: () {
              // Navigate to the profile page when clicked
              Navigator.pushNamed(context, '/profile');
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/profile.jpg'),  // Replace with your profile image
              ),
            ),
          ),
        ],
      ),
      drawer: FutureBuilder<String>(
        future: _getUserFullName(), // Fetch the user's full name
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()), // Show loading indicator while fetching data
            );
          }

          if (snapshot.hasError) {
            return const Drawer(
              child: Center(child: Text('Error fetching user data')),
            );
          }

          String fullName = snapshot.data ?? 'User';

          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // Drawer Header
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/profile.jpg'), // Replace with your logo
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Welcome, $fullName', // Display the full name
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation Items
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About Us'),
                  onTap: () {
                    // Navigate to About Us page
                    Navigator.pushNamed(context, '/about-us');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_mail),
                  title: const Text('Contact Us'),
                  onTap: () {
                    // Navigate to Contact Us page
                    Navigator.pushNamed(context, '/contact-us');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Create Listing'),
                  onTap: () {
                    // Navigate to Create Listing page
                    Navigator.pushNamed(context, '/homepage');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Browse Item'),
                  onTap: () {
                    // Navigate to Browse Item page
                    Navigator.pushNamed(context, '/homepage');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('My Account'),
                  onTap: () {
                    // Navigate to My Account page
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.view_list),
                  title: const Text('View My Ticket'),
                  onTap: () {
                    // Navigate to View My Ticket page
                    Navigator.pushNamed(context, '/homepage');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Logout'),
                  onTap: () {
                    // Implement logout functionality
                    _logout(context);  // Call the _logout method
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: const Center(
        child: Text(
          'Welcome to the Home Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
