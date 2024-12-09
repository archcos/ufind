import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item-details.dart';

class Ticket {
  final String itemName;
  final String description;
  final String dateTime;
  final String contactName;
  final String contactNumber;
  final String email;
  final String lastSeenLocation;

  Ticket({
    required this.itemName,
    required this.description,
    required this.dateTime,
    required this.contactName,
    required this.contactNumber,
    required this.email,
    required this.lastSeenLocation,
  });

  // Factory method to convert Firestore document to Ticket object
  factory Ticket.fromDocument(DocumentSnapshot doc) {
    return Ticket(
      itemName: doc['itemName'] ?? '',
      description: doc['description'] ?? '',
      dateTime: doc['dateTime'] ?? '',
      contactName: doc['contactName'] ?? '',
      contactNumber: doc['contactNumber'] ?? '',
      email: doc['email'] ?? '',
      lastSeenLocation: doc['lastSeenLocation'] ?? '',
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

          // Create a list view of tickets
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return ListTile(
                title: Text(ticket.itemName),
                subtitle: Text(ticket.description),
                onTap: () {
                  // Navigate to the ticket details page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsPage(ticket: ticket),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
