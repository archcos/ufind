import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'dart:math';

class MessagesListPage extends StatelessWidget {
  final String userId;

  MessagesListPage({required this.userId});

  // Function to fetch the full name by combining first_name and last_name from the users collection
  Future<String> _getSenderFullName(String senderId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    String firstName = userDoc['first_name'] ?? '';
    String lastName = userDoc['last_name'] ?? '';
    return '$firstName $lastName';
  }

  // Function to calculate the unread message count for each sender
  Future<int> _getUnreadCount(String senderId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiver', isEqualTo: userId)
        .where('sender', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  // Stream to get the senders of messages
  Stream<List<String>> getSenders(String userId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('receiver', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      Set<String> senders = {};

      // Add senders of messages where the user is the receiver
      for (var doc in snapshot.docs) {
        senders.add(doc['sender']);
      }

      // Now check for messages where the user is the sender
      final senderMessagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('sender', isEqualTo: userId)
          .get();

      // Add receivers of messages where the user is the sender
      for (var doc in senderMessagesSnapshot.docs) {
        senders.add(doc['receiver']);
      }

      return senders.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Messages"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<String>>(
        stream: getSenders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No messages yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final senders = snapshot.data!;

          return FutureBuilder<List<Map<String, String>>>(
            future: Future.wait(senders.map((sender) async {
              String fullName = await _getSenderFullName(sender);
              int unreadCount = await _getUnreadCount(sender);
              return {'senderId': sender, 'fullName': fullName, 'unreadCount': unreadCount.toString()};
            }).toList()),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "No senders found.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final senderDetails = futureSnapshot.data!;

              return ListView.builder(
                itemCount: senderDetails.length,
                itemBuilder: (context, index) {
                  final sender = senderDetails[index];
                  final senderId = sender['senderId']!;
                  final fullName = sender['fullName']!;
                  final unreadCount = sender['unreadCount']!;
                  final initials = fullName
                      .split(' ')
                      .map((e) => e.isNotEmpty ? e[0] : '')
                      .join()
                      .toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(
                            initials,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: unreadCount != '0'
                            ? Text(
                          "$unreadCount unread messages",
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        )
                            : Text(
                          "Tap to view messages",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        onTap: () async {
                          // Mark messages as read when opening the chat
                          final query = FirebaseFirestore.instance
                              .collection('messages')
                              .where('sender', isEqualTo: senderId)
                              .where('receiver', isEqualTo: userId)
                              .where('isRead', isEqualTo: false);

                          final snapshot = await query.get();
                          for (var doc in snapshot.docs) {
                            doc.reference.update({'isRead': true});
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                userId: userId,
                                receiverId: senderId,
                              ),
                            ),
                          );
                        },
                      ),
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
