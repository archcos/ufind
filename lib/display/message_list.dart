import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesListPage extends StatelessWidget {
  final String userId;

  MessagesListPage({required this.userId});

  // Function to fetch the full name by combining first_name and last_name from the users collection
  Future<String> _getSenderFullName(String senderId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    String firstName = userDoc['first_name'] ?? '';
    String lastName = userDoc['last_name'] ?? '';
    return '$firstName $lastName';  // Combine first_name and last_name
  }

  Stream<List<String>> getSenders(String userId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('receiver', isEqualTo: userId)  // Get messages where the current user is the receiver
        .snapshots()
        .map((snapshot) {
      Set<String> senders = {};  // Set to hold unique senders
      for (var doc in snapshot.docs) {
        senders.add(doc['sender']);  // Add the sender to the set
      }
      return senders.toList();  // Convert set to list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Messages")),
      body: StreamBuilder<List<String>>(
        stream: getSenders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No messages yet."));
          }

          final senders = snapshot.data!;

          return FutureBuilder<List<Map<String, String>>>(
            future: Future.wait(senders.map((sender) async {
              String fullName = await _getSenderFullName(sender);  // Fetch the sender's full name
              return {
                'senderId': sender,
                'fullName': fullName,
              };
            }).toList()),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                return Center(child: Text("No senders found."));
              }

              final senderDetails = futureSnapshot.data!;

              return ListView.builder(
                itemCount: senderDetails.length,
                itemBuilder: (context, index) {
                  final sender = senderDetails[index];
                  final senderId = sender['senderId']!;
                  final fullName = sender['fullName']!;

                  return ListTile(
                    title: Text(fullName),  // Display the sender's full name
                    onTap: () {
                      // Navigate to the chat screen with the selected sender
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userId: userId,
                            receiverId: senderId,  // Pass the sender's ID as the receiver
                          ),
                        ),
                      );
                    },
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
