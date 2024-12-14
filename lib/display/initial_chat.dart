import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InitialChatPage extends StatefulWidget {
  final String userId;
  final String receiverId;
  final String itemName; // Add item name parameter

  InitialChatPage({required this.userId, required this.receiverId, required this.itemName});

  @override
  _InitialChatPageState createState() => _InitialChatPageState();
}

class _InitialChatPageState extends State<InitialChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool isFirstMessage = true; // Flag to track if it's the first message

  Future<void> sendMessage(String senderId, String receiverId, String message, {String? itemName}) async {
    final timestamp = FieldValue.serverTimestamp();
    final isRead = false; // Initially, the message is unread

    // Send the message to Firestore
    await FirebaseFirestore.instance.collection('messages').add({
      'sender': senderId,
      'receiver': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead, // Set the message as unread initially
      'itemName': itemName ?? '', // Store the item name if provided
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
    return DateFormat('MM-dd-yyyy hh:mm a').format(dateTime); // Example: "2024-12-13 02:45 PM"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName), // Use the itemName as the title in the app bar
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
                      String userMessage = _controller.text;

                      // Send the first user message
                      await sendMessage(
                        widget.userId,
                        widget.receiverId,
                        userMessage,
                      );

                      // If it's the first message, send the item name as the second message
                      if (isFirstMessage) {
                        await sendMessage(
                          widget.userId,
                          widget.receiverId,
                          'ITEM NAME: ${widget.itemName}',
                        );
                        isFirstMessage = false; // Update the flag after the first message
                      }

                      _controller.clear(); // Clear the input field
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
