import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';

class MyTicketPage extends StatelessWidget {
  Future<String?> _getSchoolId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_school_id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
      ),
      body: FutureBuilder<String?>(
        future: _getSchoolId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          String schoolId = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tickets').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tickets = snapshot.data!.docs
                  .where((doc) {
                final uid = doc.id.substring(0, 10);
                return uid == schoolId;
              })
                  .map((doc) => Ticket.fromDocument(doc))
                  .toList();

              return tickets.isEmpty
                  ? const Center(child: Text("No tickets found"))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ticket.imageUrl.isNotEmpty)
                          SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: ticket.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.itemName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.dateTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Item Type: ${ticket.itemType}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditTicketPage(ticket: ticket),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _confirmDelete(context, ticket);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _confirmDelete(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Ticket"),
          content: const Text("Are you sure you want to delete this ticket?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteTicket(ticket.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteTicket(String ticketId) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).delete();
    } catch (error) {
      print("Error deleting ticket: $error");
    }
  }
}

class EditTicketPage extends StatefulWidget {
  final Ticket ticket;

  EditTicketPage({required this.ticket});

  @override
  State<EditTicketPage> createState() => _EditTicketPageState();
}

class _EditTicketPageState extends State<EditTicketPage> {
  final _formKey = GlobalKey<FormState>();

  late String _itemName;

  late String _description;

  late String _contactName;

  late String _contactNumber;

  late String _email;

  String? _lastSeenLocation;
  // Nullable type to avoid late initialization errors
  late String? _itemType;
  // Make it nullable instead of using 'late'
  String? _imageUrl;
  // Make this nullable to prevent LateInitializationError
  final _itemTypes = ['Found', 'Lost'];
 // Dropdown options
  @override
  Widget build(BuildContext context) {
    _lastSeenLocation = widget.ticket.lastSeenLocation.isNotEmpty ? widget.ticket.lastSeenLocation : null;
    _itemType = widget.ticket.itemType.isNotEmpty ? widget.ticket.itemType : 'Lost'; // Default to 'Lost' if empty
    _imageUrl = widget.ticket.imageUrl.isNotEmpty ? widget.ticket.imageUrl : null; // Set initial value for imageUrl

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Ticket")),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: widget.ticket.itemName,
                  decoration: const InputDecoration(labelText: "Item Name"),
                  validator: (value) => value!.isEmpty ? "Enter item name" : null,
                  onSaved: (value) => _itemName = value!,
                ),
                TextFormField(
                  initialValue: widget.ticket.description,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (value) => value!.isEmpty ? "Enter description" : null,
                  onSaved: (value) => _description = value!,
                ),
                TextFormField(
                  initialValue: widget.ticket.contactName,
                  decoration: const InputDecoration(labelText: "Contact Name"),
                  validator: (value) => value!.isEmpty ? "Enter contact name" : null,
                  onSaved: (value) => _contactName = value!,
                ),
                TextFormField(
                  initialValue: widget.ticket.contactNumber,
                  decoration: const InputDecoration(labelText: "Contact Number"),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Enter contact number";
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return "Please enter a valid contact number";
                    }
                    return null;
                  },
                  onSaved: (value) => _contactNumber = value!,
                ),
                TextFormField(
                  initialValue: widget.ticket.email,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Enter email";
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                Visibility(
                  visible: false,  // This makes it hidden
                  child: TextFormField(
                    initialValue: widget.ticket.lastSeenLocation,
                    decoration: const InputDecoration(
                      labelText: "Last Seen Location",
                    ),
                    validator: (value) => value!.isEmpty ? "Enter last seen location" : null,
                    onSaved: (value) => _lastSeenLocation = value!,  // Nullable value
                    enabled: false,  // This makes the field uneditable
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: widget.ticket.itemType.isNotEmpty ? widget.ticket.itemType : _itemTypes[0],
                  decoration: const InputDecoration(labelText: "Item Type"),
                  items: _itemTypes.map((itemType) {
                    return DropdownMenuItem<String>(
                      value: itemType,
                      child: Text(itemType),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _itemType = value!;
                  },
                  validator: (value) => value == null ? "Select item type" : null,
                ),
                Visibility(
                  visible: false,  // This makes it hidden
                  child: TextFormField(
                    initialValue: widget.ticket.imageUrl,
                    decoration: const InputDecoration(
                      labelText: "Image URL",
                    ),
                    validator: (value) => value!.isEmpty ? "Enter image URL" : null,
                    onSaved: (value) => _imageUrl = value!,
                    enabled: false,  // This makes the field uneditable
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child:                 ElevatedButton(
                    child: const Text("Save Changes"),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _updateTicket(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateTicket(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticket.id)
          .update({
        'itemName': _itemName,
        'description': _description,
        'contactName': _contactName,
        'contactNumber': _contactNumber,
        'email': _email,
        'lastSeenLocation': _lastSeenLocation,
        'itemType': _itemType,
        'imageUrl': _imageUrl,
      });
      Navigator.of(context).pop();
    } catch (error) {
      print("Error updating ticket: $error");
    }
  }
}
