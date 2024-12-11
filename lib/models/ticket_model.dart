import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id; // Added ID field
  final String itemName;
  final String description;
  final String dateTime;
  final String contactName;
  final String contactNumber;
  final String email;
  final String lastSeenLocation;
  final String imageUrl;
  final String itemType;

  Ticket({
    required this.id, // Include ID in constructor
    required this.itemName,
    required this.description,
    required this.dateTime,
    required this.contactName,
    required this.contactNumber,
    required this.email,
    required this.lastSeenLocation,
    required this.imageUrl,
    required this.itemType,
  });

  factory Ticket.fromDocument(DocumentSnapshot doc) {
    return Ticket(
      id: doc.id, // Assign document ID
      itemName: doc['itemName'] ?? '',
      description: doc['description'] ?? '',
      dateTime: doc['dateTime'] ?? '',
      contactName: doc['contactName'] ?? '',
      contactNumber: doc['contactNumber'] ?? '',
      email: doc['email'] ?? '',
      lastSeenLocation: doc['lastSeenLocation'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
      itemType: doc['itemType'] ?? '',
    );
  }
}
