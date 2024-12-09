import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';  // For caching images

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
              crossAxisCount: 2,  // Set the number of columns to 2
              crossAxisSpacing: 8,  // Space between columns
              mainAxisSpacing: 8,   // Space between rows
              childAspectRatio: 0.7,  // Adjust aspect ratio for grid items
            ),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image display without blur effect
                    if (ticket.imageUrl.isNotEmpty)
                      Container(
                        height: 120,  // Adjust the height of the image container
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: ticket.imageUrl,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                          placeholder: (context, url) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 8),
                    // Title and date (instead of description)
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
                              maxLines: 1,  // Limit title to one line
                              overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                            ),
                            SizedBox(height: 4),
                            Text(
                              ticket.dateTime,  // Use the date field instead of description
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              maxLines: 1,  // Limit the date text to one line
                              overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
