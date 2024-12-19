import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/display/message_list.dart';
import '../services/auth_service.dart';  // Import AuthService
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

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

  Future<int> _getUnreadMessagesCount(String userId) async {
    try {
      // Query the Firestore collection for messages where 'userId' matches and 'isRead' is false
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiver', isEqualTo: userId)  // Ensure we filter by userId
          .where('isRead', isEqualTo: false)  // Filter by unread messages (isRead = false)
          .get();

      // Return the count of unread messages
      return snapshot.size;
    } catch (e) {
      print("Error fetching unread messages: $e");
      return 0;  // Return 0 if there's an error
    }
  }

  Stream<int> _getUnreadMessagesCountStream(String userId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('receiver', isEqualTo: userId)  // Filter by userId
        .where('isRead', isEqualTo: false)  // Only unread messages
        .snapshots()
        .map((snapshot) => snapshot.size);  // Return the count of unread messages
  }

  // Fetch user full name from SharedPreferences
  Future<String> _getUserFullName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String firstName = prefs.getString('user_first_name') ?? 'User';
    String lastName = prefs.getString('user_last_name') ?? '';
    return '$firstName $lastName';
  }

  Future<String> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_school_id');  // Replace with actual key for userId
    return userId ?? '';  // Return an empty string if no userId found
  }

  Future<void> _handlePopupMenuSelection(String value, BuildContext context) async {
    if (value == 'profile') {
      // Navigate to profile page when profile is selected
      Navigator.pushNamed(context, '/profile');
    } else if (value == 'message') {
      // Fetch the userId and navigate to the message list using Navigator.push()
      String userId = await _getUserId();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesListPage(userId: userId),
        ),
      );
    } else if (value == 'logout') {
      // Perform logout when logout is selected
      _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the key to the Scaffold
      appBar: AppBar(
        backgroundColor: Colors.white,  // Makes the AppBar transparent
        elevation: 0,  // Removes the shadow of the AppBar
        leading: FutureBuilder<String>(
          future: _getUserId(),  // Fetch user ID first
          builder: (context, userIdSnapshot) {
            if (userIdSnapshot.connectionState == ConnectionState.waiting) {
              return const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/profile.jpg'),  // Placeholder
              );
            }

            if (userIdSnapshot.hasError || !userIdSnapshot.hasData) {
              return const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/profile.jpg'),  // Placeholder
              );
            }

            String userId = userIdSnapshot.data!;

            // Use StreamBuilder to listen to unread messages count
            return StreamBuilder<int>(
              stream: _getUnreadMessagesCountStream(userId),  // Listen to unread messages count stream
              builder: (context, unreadMessagesSnapshot) {
                if (unreadMessagesSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),  // Placeholder
                  );
                }

                if (unreadMessagesSnapshot.hasError || !unreadMessagesSnapshot.hasData) {
                  return const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),  // Placeholder
                  );
                }

                int unreadCount = unreadMessagesSnapshot.data!;

                return PopupMenuButton<String>(
                  icon: Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/images/profile.jpg'),  // Your profile image
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onSelected: (String value) {
                    _handlePopupMenuSelection(value, context);  // Handle menu item selection
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Text('Profile'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'message',
                      child: Text('Messages'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          // Add additional actions if needed
        ],
      ),

      endDrawer: FutureBuilder<String>( // Use endDrawer to open the drawer from the right
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
                // Drawer Header with profile image
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.lightBlueAccent,
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
                  leading: const Icon(Icons.message),
                  title: const Text('Messages'),
                  onTap: () async { // Mark the onTap callback as async
                    String userId = await _getUserId(); // Await the Future to get the String value
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagesListPage(userId: userId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Create Ticket'),
                  onTap: () {
                    Navigator.pushNamed(context, '/create-ticket');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Browse Items'),
                  onTap: () {
                    Navigator.pushNamed(context, '/browse-items');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.view_list),
                  title: const Text('View My Ticket'),
                  onTap: () {
                    Navigator.pushNamed(context, '/my-tickets');
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
                  leading: const Icon(Icons.exit_to_app, color: Colors.red,),
                  title: const Text(
                      'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.red,
                    ),
                  ),
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
              duration: const Duration(seconds: 5),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Recent Items",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .where('ticket', isNotEqualTo: 'Completed')
                  .orderBy('dateTime', descending: true) // Order by 'dateTime'
                  .limit(6)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No recent tickets found.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  );
                }

                final tickets = snapshot.data!.docs.map((doc) {
                  return {
                    'name': doc['name'] ?? '',
                    'imageUrl': doc['imageUrl'] ?? '',
                    'status': doc['status'] ?? 'found',  // Fetching itemType
                  };
                }).toList();

                if (tickets.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No recent tickets found.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,  // 3 items per row
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final isLostItem = ticket['status'] == 'lost';  // Check if itemType is 'Lost'

                      return Card(
                        elevation: 4,
                          child: InkWell(
                          onTap: () {
                        Navigator.pushNamed(context, '/browse-items');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack (
                                    children: [CachedNetworkImage(
                                      imageUrl: ticket['imageUrl'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (context, url) =>
                                      const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                      const Icon(Icons.error, color: Colors.red),
                                    ),
                                      if (!isLostItem)
                                        Positioned.fill(
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Apply blur
                                          child: Container(
                                            color: Colors.black.withOpacity(0.1), // Optional overlay for darkening
                                          ),
                                        ),
                                      ),
                                    ]
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${ticket['name']} \n', // Keep itemName black
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black, // Item name stays black
                                      ),
                                    ),
                                    TextSpan(
                                      text: ticket['status'], // Display itemType in dynamic color
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: ticket['status'] == 'found' ? Colors.green : Colors.red, // Green if Found, Red otherwise
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ));
                    },
                  ),
                );
              },
            ),


// Action buttons for user to browse items, view tickets, or create a ticket
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Browse Items Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/browse-items');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 18),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(
                            color: Colors.black54, // Border color
                            width: 1, // Border width
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.search, color: Colors.black54),
                      label: const Text(
                        'See More',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),

                    // Create Ticket Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/create-ticket');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(
                            color: Colors.black54, // Border color
                            width: 1, // Border width
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_outlined, color: Colors.black54),
                      label: const Text(
                        'Create Ticket',
                        style: TextStyle(fontSize: 12),
                      ),
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '© 2024 U-Find. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
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
