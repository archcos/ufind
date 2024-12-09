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
      drawer: FutureBuilder<String>( // Drawer to display the user's name
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
                  leading: const Icon(Icons.account_circle),
                  title: const Text('My Account'),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Create Listing'),
                  onTap: () {
                    Navigator.pushNamed(context, '/create-ticket');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Browse Item'),
                  onTap: () {
                    Navigator.pushNamed(context, '/browse-items');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.view_list),
                  title: const Text('View My Ticket'),
                  onTap: () {
                    Navigator.pushNamed(context, '/homepage');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About Us'),
                  onTap: () {
                    Navigator.pushNamed(context, '/about-us');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_mail),
                  title: const Text('Contact Us'),
                  onTap: () {
                    Navigator.pushNamed(context, '/contact-us');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Logout'),
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,  // Center the content
          children: [
            // Animated Image at the top
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              height: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/banner.png'),  // Add your banner image here
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Paragraph below the image
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Welcome to U-Find! Your one-stop solution for finding and managing your lost and found items. Explore our services and get started with ease!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            // Action buttons for user to browse items, view tickets, or create a ticket
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/browse-items');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text('Browse Items'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/view-my-tickets');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('View My Tickets'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/create-ticket');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Create a Ticket'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Footer (Contact Details and Copyright)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.blueAccent,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Contact Us:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Email: support@ufind.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Phone: +123 456 7890',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Office Hours: Monday - Friday, 9:00 AM - 5:00 PM',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '© 2024 U-Find. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
