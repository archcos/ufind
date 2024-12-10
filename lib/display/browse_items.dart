import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';  // For caching images
import 'dart:ui';

import 'item_details.dart';

class Ticket {
  final String itemName;
  final String description;
  final String dateTime;  // Use this instead of description
  final String contactName;
  final String contactNumber;
  final String email;
  final String lastSeenLocation;
  final String imageUrl;

  Ticket({
    required this.itemName,
    required this.description,
    required this.dateTime,  // Use dateTime
    required this.contactName,
    required this.contactNumber,
    required this.email,
    required this.lastSeenLocation,
    required this.imageUrl,
  });

  factory Ticket.fromDocument(DocumentSnapshot doc) {
    return Ticket(
      itemName: doc['itemName'] ?? '',
      description: doc['description'] ?? '',
      dateTime: doc['dateTime'] ?? '',  // Use dateTime field
      contactName: doc['contactName'] ?? '',
      contactNumber: doc['contactNumber'] ?? '',
      email: doc['email'] ?? '',
      lastSeenLocation: doc['lastSeenLocation'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
    );
  }
}

class ItemsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ticket List"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tickets').snapshots(),
        builder: (context, snapshot) {
          // Handle loading state
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Extract data from snapshot
          final tickets = snapshot.data!.docs.map((doc) => Ticket.fromDocument(doc)).toList();

          // Create a grid view of tickets with a card design (2 columns)
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Number of columns
              crossAxisSpacing: 8, // Space between columns
              mainAxisSpacing: 8, // Space between rows
              childAspectRatio: 0.7, // Aspect ratio for grid items
            ),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to ItemDetailsPage when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsPage(ticket: ticket),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image display
                      if (ticket.imageUrl.isNotEmpty)
                        Container(
                          height: 120, // Adjust the height of the image container
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8), // Ensure clipping matches the border radius
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: ticket.imageUrl,
                                  fit: BoxFit.cover,
                                  height: double.infinity,
                                  width: double.infinity,
                                  placeholder: (context, url) =>
                                      Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error, color: Colors.red),
                                ),
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Apply blur
                                    child: Container(
                                      color: Colors.black.withOpacity(0.1), // Optional overlay for darkening
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                      // Title and date
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.itemName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                ticket.dateTime,
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
