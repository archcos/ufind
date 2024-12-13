import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String receiverId;

  ChatScreen({required this.userId, required this.receiverId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String? receiverName;

  // Fetch the user's full name from Firestore
  Future<String> _getUserFullName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc['fullName'];  // Make sure to return the correct field
  }

  Future<void> _fetchReceiverName() async {
    // Fetch receiver's full name
    String name = await _getUserFullName(widget.receiverId);
    setState(() {
      receiverName = name;
    });
  }

  Future<void> sendMessage(String senderId, String receiverId, String message, String itemName) async {
    final timestamp = FieldValue.serverTimestamp();
    final isRead = false;  // Initially, the message is unread

    await FirebaseFirestore.instance.collection('messages').add({
      'sender': senderId,
      'receiver': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,  // Set the message as unread initially
      'itemName': itemName,  // Store the item name
    });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String userId, String receiverId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('sender', whereIn: [userId, receiverId])
        .where('receiver', whereIn: [userId, receiverId])
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((message) =>
      (message['sender'] == userId && message['receiver'] == receiverId) ||
          (message['sender'] == receiverId && message['receiver'] == userId))
          .toList();
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Pending...';
    final dateTime = timestamp.toDate();
    return DateFormat('MM-dd-yyyy hh:mm a').format(dateTime);  // Example: "2024-12-13 02:45 PM"
  }

  @override
  void initState() {
    super.initState();
    _fetchReceiverName();  // Fetch the receiver's name when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName ?? 'Chat'),  // Use receiver name as title, fallback to 'Chat' if not loaded yet
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getMessages(widget.userId, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No messages"));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message['sender'] == widget.userId;

                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: TextStyle(color: isSender ? Colors.white : Colors.black),
                            ),
                            SizedBox(height: 5),
                            Text(
                              message['timestamp'] != null
                                  ? formatTimestamp(message['timestamp'] as Timestamp?)
                                  : 'Pending...',
                              style: TextStyle(fontSize: 8, color: Colors.black),
                            ),
                            // Display the sender's full name
                            SizedBox(height: 5),
                            Text(
                              'Sent by: ${message['senderName']}',
                              style: TextStyle(fontSize: 10, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Enter your message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.isNotEmpty) {
                      final senderName = await _getUserFullName(widget.userId); // Get the sender's full name
                      sendMessage(
                        widget.userId,
                        widget.receiverId,
                        _controller.text,
                        '',  // Pass the item name
                      );
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
