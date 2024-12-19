import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InitialChatPage extends StatefulWidget {
  final String userId;
  final String receiverId;
  final String itemType; // Add itemType to the widget

  InitialChatPage({required this.userId, required this.receiverId, required this.itemType});

  @override
  _InitialChatPageState createState() => _InitialChatPageState();
}

class _InitialChatPageState extends State<InitialChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool isFirstMessage = true; // Flag to track if it's the first message
  bool isPopupShown = false; // Ensure popup shows only once
  final ScrollController _scrollController = ScrollController();

  String getChatDocumentId() {
    // Sort the user IDs to ensure the documentId is the same for both users
    final ids = [widget.userId, widget.receiverId];
    ids.sort(); // Sort alphabetically or numerically
    return ids.join("_"); // Combine IDs with an underscore
  }

  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    final timestamp = FieldValue.serverTimestamp();
    final isRead = false;

    // Firestore path: /chats1/{documentId}/messages/{messageId}
    final documentId = getChatDocumentId();
    final chatDocRef = FirebaseFirestore.instance.collection('chats1').doc(documentId);
    final messagesRef = chatDocRef.collection('messages');

    // Check if the chat document already exists
    final chatDoc = await chatDocRef.get();

    if (!chatDoc.exists) {
      // Create the chat document with metadata if it doesn't exist
      await chatDocRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': message,
        'lastMessageTime': timestamp,
      });
    } else {
      // Update last message details if the chat already exists
      await chatDocRef.update({
        'lastMessage': message,
        'lastMessageTime': timestamp,
      });
    }

    // Add the message to the messages sub-collection
    await messagesRef.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String userId, String receiverId) {
    final documentId = getChatDocumentId();
    final chatRef = FirebaseFirestore.instance.collection('chats1').doc(documentId).collection('messages');

    return chatRef.orderBy('timestamp').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Pending...';
    final dateTime = timestamp.toDate();
    return DateFormat('MM-dd-yyyy hh:mm a').format(dateTime); // Example: "2024-12-13 02:45 PM"
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void showItemDetailsPopup() {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Provide Item Details to make your inquiry faster',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Item Description '),
              ),
              TextField(
                controller: timeController,
                decoration: InputDecoration(labelText: 'Time Lost/Found'),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    timeController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without doing anything
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final description = descriptionController.text.trim();
                final time = timeController.text.trim();

                if (description.isNotEmpty && time.isNotEmpty) {
                  // Send the item details as the first message
                  await sendMessage(
                    widget.userId,
                    widget.receiverId,
                    'ITEM DETAILS: \nDescription: $description\nTime Lost/Found: $time',
                  );

                  setState(() {
                    isPopupShown = true; // Prevent the popup from showing again
                  });

                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Show the popup only if the itemType is not "Lost"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isPopupShown && widget.itemType != 'Lost') {
        showItemDetailsPopup();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"), // Use the itemName as the title in the app bar
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
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No messages"));
                }

                final messages = snapshot.data!;

                // Scroll to the bottom whenever new messages are loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message['senderId'] == widget.userId;

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

                      // Send user message
                      await sendMessage(
                        widget.userId,
                        widget.receiverId,
                        userMessage,
                      );

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
