import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'chat_screen.dart';

class MessagesListPage extends StatelessWidget {
  final String userId;

  MessagesListPage({required this.userId});

  // Fetch sender's full name from the 'users' collection
  Future<String> _getSenderFullName(String senderId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    String firstName = userDoc['first_name'] ?? '';
    String lastName = userDoc['last_name'] ?? '';
    return '$firstName $lastName';
  }

  // Fetch unread message count for each sender
  Future<int> _getUnreadCount(String senderId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiver', isEqualTo: userId)
        .where('sender', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  // Stream to get the sender details including the most recent message timestamp
  Stream<List<Map<String, dynamic>>> getSendersWithTimestamps(String userId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('receiver', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      Map<String, Timestamp> senderTimestamps = {};

      // Collect the latest message timestamp for each sender
      for (var doc in snapshot.docs) {
        String sender = doc['sender'];
        Timestamp timestamp = doc['timestamp'];
        if (!senderTimestamps.containsKey(sender) || senderTimestamps[sender]!.compareTo(timestamp) < 0) {
          senderTimestamps[sender] = timestamp;
        }
      }

      // Add receivers (when user is the sender)
      final sentMessagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('sender', isEqualTo: userId)
          .get();

      for (var doc in sentMessagesSnapshot.docs) {
        String receiver = doc['receiver'];
        Timestamp timestamp = doc['timestamp'];
        if (!senderTimestamps.containsKey(receiver) || senderTimestamps[receiver]!.compareTo(timestamp) < 0) {
          senderTimestamps[receiver] = timestamp;
        }
      }

      // Convert the map into a sorted list by timestamp
      return senderTimestamps.entries
          .map((entry) => {'senderId': entry.key, 'timestamp': entry.value})
          .toList()
        ..sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp)); // Cast explicitly
    });
  }

  // Helper function to format the timestamp into a readable string
  String _formatTimestamp(Timestamp timestamp) {
    try {
      final date = timestamp.toDate();
      return DateFormat('MM/dd/yyyy hh:mm a').format(date); // Format: MM/DD/YYYY hh:mm AM/PM
    } catch (e) {
      return "Invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Messages"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getSendersWithTimestamps(userId),
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

          final senderDetailsWithTimestamps = snapshot.data!;

          return FutureBuilder<List<Map<String, String>>>(
            future: Future.wait(senderDetailsWithTimestamps.map((sender) async {
              String senderId = sender['senderId'];
              String fullName = await _getSenderFullName(senderId);
              int unreadCount = await _getUnreadCount(senderId);
              return {
                'senderId': senderId,
                'fullName': fullName,
                'unreadCount': unreadCount.toString(),
                'timestamp': (sender['timestamp'] as Timestamp).millisecondsSinceEpoch.toString(),
              };
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
                  final timestamp = Timestamp.fromMillisecondsSinceEpoch(int.parse(sender['timestamp']!));
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
                          backgroundColor: Colors.lightBlueAccent,
                          child: Text(
                            initials,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unreadCount != '0'
                                  ? "$unreadCount unread messages"
                                  : "Tap to view messages",
                              style: TextStyle(
                                color: unreadCount != '0' ? Colors.red : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Last message: ${_formatTimestamp(timestamp)}", // Format the timestamp
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.lightBlueAccent),
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
