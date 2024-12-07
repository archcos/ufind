import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For sending emails directly from the app

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  // Function to launch the email app with pre-filled details
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Contact Us Inquiry'}, // You can add more query parameters if needed
    );

    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    } else {
      throw 'Could not launch $email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Contact Information Section
              const Text(
                'Get in Touch',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Email: rain.shigatsu@gmail.com', // Replace with your contact email
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                'Phone: +1 234 567 8901', // Replace with your contact number
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                'Office Hours: Mon - Fri, 9:00 AM - 5:00 PM',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),

              // Contact Form Section
              const Text(
                'Send Us a Message',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              // Button to send the email
              ElevatedButton(
                onPressed: () {
                  _launchEmail('contact@ufind.com'); // This will open the email client with a pre-filled subject
                },
                child: const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
