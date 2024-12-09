import 'package:flutter/material.dart';
import 'browse-items.dart';

class ItemDetailsPage extends StatelessWidget {
  final Ticket ticket;

  ItemDetailsPage({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.itemName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Name: ${ticket.itemName}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Description: ${ticket.description}'),
            SizedBox(height: 10),
            Text('Date & Time: ${ticket.dateTime}'),
            SizedBox(height: 10),
            Text('Contact Name: ${ticket.contactName}'),
            SizedBox(height: 10),
            Text('Contact Number: ${ticket.contactNumber}'),
            SizedBox(height: 10),
            Text('Email: ${ticket.email}'),
            SizedBox(height: 10),
            Text('Last Seen Location: ${ticket.lastSeenLocation}'),
          ],
        ),
      ),
    );
  }
}
