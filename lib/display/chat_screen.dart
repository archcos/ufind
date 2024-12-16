import 'package:flutter/gestures.dart';
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
  final ScrollController _scrollController = ScrollController();
  String? receiverName;

  Future<String> _getUserFullName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Get first_name and last_name from Firestore
    String firstName = userDoc['first_name'] ?? ''; // Default to empty string if not available
    String lastName = userDoc['last_name'] ?? '';   // Default to empty string if not available

    // Combine first_name and last_name
    return '$firstName $lastName';
  }


  Future<void> _fetchReceiverName() async {
    String name = await _getUserFullName(widget.receiverId);
    setState(() {
      receiverName = name;
    });
  }
  final isRead = false; // Initially, the message is unread


  Future<void> sendMessage(
      String senderId, String receiverId, String message, String itemName) async {
    final timestamp = FieldValue.serverTimestamp();
    await FirebaseFirestore.instance.collection('messages').add({
      'sender': senderId,
      'receiver': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead, // Set the message as unread initially
      'itemName': itemName,
    });

    Future<void> markMessagesAsRead(String senderId, String receiverId) async {
      var query = FirebaseFirestore.instance
          .collection('messages')
          .where('sender', isEqualTo: senderId)
          .where('receiver', isEqualTo: receiverId)
          .where('isRead', isEqualTo: false);

      var snapshot = await query.get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'isRead': true,
        });
      }
    }


    // Scroll to the bottom after sending a message
    _scrollToBottom();
  }

  Stream<List<Map<String, dynamic>>> getMessages(
      String userId, String receiverId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('sender', whereIn: [userId, receiverId])
        .where('receiver', whereIn: [userId, receiverId])
        .orderBy('timestamp') // Ensure messages are ordered by timestamp
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
    return DateFormat('MM-dd-yyyy hh:mm a').format(dateTime);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReceiverName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName ?? 'Chat'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.blue[50], // Light blue background for the card
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon for the reminder
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 10), // Add space between icon and text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reminder:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.orange[700],
                          ),
                        ),
                        RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, color: Colors.black87), // Default text style
                            children: [
                              const TextSpan(
                                text: "Please update the Status of your ticket once you claim/give an item. ",
                              ),
                              TextSpan(
                                text: "Click Here",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue, // Blue color to indicate it's a link
                                  decoration: TextDecoration.underline, // Underline to look like a link
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Navigate to '/my-tickets' route when tapped
                                    Navigator.pushNamed(context, '/my-tickets');
                                  },
                              ),
                            ],
                          ),
                        )

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getMessages(widget.userId, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No messages"));
                }

                final messages = snapshot.data!;

                // Use `WidgetsBinding` to ensure scrolling happens after the frame renders
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message['sender'] == widget.userId;

                    return Align(
                      alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isSender
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: TextStyle(
                                  color: isSender ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              message['timestamp'] != null
                                  ? formatTimestamp(
                                  message['timestamp'] as Timestamp?)
                                  : 'Pending...',
                              style:
                              const TextStyle(fontSize: 8, color: Colors.black54),
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
                    decoration: const InputDecoration(hintText: 'Enter your message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(
                        widget.userId,
                        widget.receiverId,
                        _controller.text,
                        '', // Pass the item name
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
