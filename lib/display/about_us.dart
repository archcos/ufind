import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Static image at the top
            Image.asset(
              'assets/images/about-us.png', // Replace with your image path
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20), // Space between the image and text
            // Scrollable content below the image
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'We strive to connect people through an easy and accessible platform that allows them to find and share items in their local community. Our mission is to make the process of buying, selling, and trading items simple and secure, while fostering a sense of community and trust among our users.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Our Story',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Founded in 2024, U-Find was born out of a desire to create a platform where individuals could exchange goods easily. Our founders noticed a growing need for a local and trustworthy marketplace that provided a safe space for users to find what they need and offer what they no longer use.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'What We Do',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                      'U-Find is a user-friendly web and mobile platform designed to help students and staff report, track, and retrieve lost and found items on campus. Our system allows users to securely log in and report any lost or found items, making it easier for the rightful owners to be reunited with their belongings. With real-time notifications, users are quickly alerted whenever a match for their lost or found item is made. Administrators can efficiently manage reports, ensuring that all cases are handled smoothly. Our goal is to create a seamless and convenient experience for the campus community, helping lost items find their way back to their owners in a secure and timely manner.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
