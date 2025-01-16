import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import 'package:intl/intl.dart';

import 'my_item_details.dart'; // Import the intl package for formatting

class MyTicketPage extends StatefulWidget {
  @override
  _MyTicketPageState createState() => _MyTicketPageState();
}

class _MyTicketPageState extends State<MyTicketPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 2 tabs: Pending, Success
  }

  Future<String?> _getSchoolId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_school_id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'OSA'),
          ],
        ),
      ),
      body: FutureBuilder<String?>(
        future: _getSchoolId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle null case for schoolId
          final schoolId = snapshot.data;
          if (schoolId == null || schoolId.isEmpty) {
            return const Center(child: Text('School ID not found.'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('items').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter tickets based on the status for each tab
              final pendingTickets = snapshot.data!.docs
                  .where((doc) {
                final uid = doc.id.substring(0, 10);
                // Ensure we exclude tickets with claimStatus 'turnover(osa)'
                if (schoolId == '1234567890') {
                  return uid == schoolId || doc['claimStatus'] == 'turnover(guard)';
                } else {
                  return uid == schoolId;
                }
              })
                  .where((doc) => doc['ticket'] == 'pending' && doc['claimStatus'] != 'turnover(osa)') // Exclude turnover(osa)
                  .map((doc) => Ticket.fromDocument(doc))
                  .toList();

              final successTickets = snapshot.data!.docs
                  .where((doc) {
                final uid = doc.id.substring(0, 10);
                // Ensure we exclude tickets with claimStatus 'turnover(osa)'
                if (schoolId == '1234567890') {
                  return uid == schoolId || doc['claimStatus'] == 'turnover(guard)';
                } else {
                  return uid == schoolId;
                }
              })
                  .where((doc) => doc['ticket'] == 'success' && doc['claimStatus'] != 'turnover(osa)') // Exclude turnover(osa)
                  .map((doc) => Ticket.fromDocument(doc))
                  .toList();


              final turnoverTickets = snapshot.data!.docs
                  .where((doc) {
                final uid = doc.id.substring(0, 10);
                if (schoolId == '1234567890') {
                  return uid == schoolId || doc['claimStatus'] == 'turnover(osa)';
                } else {
                  return uid == schoolId;
                }
              })
                  .map((doc) => Ticket.fromDocument(doc))
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTicketGrid(pendingTickets, schoolId),
                  _buildTicketGrid(successTickets, schoolId),
                  schoolId == '1234567890' ? _buildTurnoverTicketGrid(turnoverTickets) : const Center(child: Text('No access to Turned Over tickets')),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTurnoverTicketGrid(List<Ticket> tickets) {
    if (tickets.isEmpty) {
      return const Center(child: Text("No Turned Over items to OSA found"));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
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
                        ticket.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                        'Item Type: ${ticket.status}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildTicketGrid(List<Ticket> tickets, String schoolId) {
    if (tickets.isEmpty) {
      return const Center(child: Text("No reports found"));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.59,
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final isTurnedOver = ticket.claimStatus == 'turnover(guard)';

        // Wrap the entire card with GestureDetector
        return GestureDetector(
          onTap: () {
            // Navigate to MyItemDetailsPage when the card is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyItemDetailsPage(ticket: ticket),
              ),
            );
          },
          child: Card(
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
                          ticket.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                          'Item Type: ${ticket.status}',
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
                            if (ticket.ticket != 'success') ...[
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: (schoolId == '1234567890' || !isTurnedOver)
                                    ? null
                                    : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditTicketPage(ticket: ticket),
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (schoolId == '1234567890' &&
                                ticket.ticket != 'success') ...[
                              IconButton(
                                icon: const Icon(
                                    Icons.move_up_outlined, color: Colors.orange),
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Turn Over Item'),
                                      content: const Text(
                                          'Are you going to turn over this item to OSA?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            _updateTurnOverDetails(
                                              ticket,
                                            );
                                            Navigator.pop(
                                                context); // Close the dialog
                                          },
                                          child: const Text('Yes'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                context, false); // User chooses not to turn over
                                          },
                                          child: const Text('No'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                        Center(
                          child: TextButton(
                            onPressed: (!isTurnedOver ||
                                schoolId == '1234567890')
                                ? () {
                              if (ticket.ticket == 'pending') {
                                _showCompletionDialog(context, ticket);
                              }
                            }
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: (!isTurnedOver ||
                                  schoolId == '1234567890')
                                  ? (ticket.ticket == 'pending'
                                  ? Colors.red
                                  : Colors.green)
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isTurnedOver && schoolId != '1234567890'
                                  ? "Turned Over"
                                  : (ticket.ticket == 'pending'
                                  ? "Mark as Completed"
                                  : "Completed"),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _showCompletionDialog(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ticket Completion'),
          content: const Text('Is this ticket completed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _showClaimDialog(context, ticket); // Show the claim details dialog
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showClaimDialog(BuildContext context, Ticket ticket) {
    final claimFormKey = GlobalKey<FormState>();
    String? claimerId;
    String? claimerName;
    String? yearSection;
    String? contactNumber;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Claim/Find Details'),
          content: SingleChildScrollView(  // Add scrollability for content
            child: Form(
              key: claimFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Claimer's/Finder's Student ID"),
                    onSaved: (value) => claimerId = value,
                    validator: (value) => value!.isEmpty ? 'Please enter ID' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Claimer's/Finder's  Name"),
                    onSaved: (value) => claimerName = value,
                    validator: (value) => value!.isEmpty ? 'Please enter full name' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Year & Section'),
                    onSaved: (value) => yearSection = value,
                    validator: (value) => value!.isEmpty ? 'Please enter year and section' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contact Number'),
                    onSaved: (value) => contactNumber = value,
                    validator: (value) => value!.isEmpty ? 'Please enter contact number' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (claimFormKey.currentState!.validate()) {
                  claimFormKey.currentState!.save();
                  // Process the claim details
                  _updateTicketWithClaimDetails(
                    ticket,
                    claimerId!,
                    claimerName!,
                    yearSection!,
                    contactNumber!,
                  );
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }


  void _updateTurnOverDetails(Ticket ticket) async {


      await FirebaseFirestore.instance.collection('items').doc(ticket.id).update({
        'fullName': "Office of Student Affairs",
        'claimStatus': 'turnover(osa)',
      });

  }
}




void _updateTicketWithClaimDetails(Ticket ticket, String claimerId, String yearSection, String claimerName, String contactNumber) async {
  String? dateCompleted = DateFormat('MMM dd, yyyy, hh:mm a').format(DateTime.now()); // Set to current date and time

  try {
      await FirebaseFirestore.instance.collection('CompletedClaims').doc(ticket.id).set({
        'studentId': claimerId,
        'itemId': ticket.id,
        'name': claimerName,
        'yearSection': yearSection,
        'contactNumber': contactNumber,
        'dateCompleted': dateCompleted

      });
      await FirebaseFirestore.instance.collection('items').doc(ticket.id).update({
        'ticket': 'success',
      });

    } catch (error) {
      // print("Error updating ticket with claim details: $error");
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

  late String _name;

  late String _description;

  late String _fullName;

  late String _contactNumber;

  late String _email;

  String? _location;

  // Nullable type to avoid late initialization errors
  late String? _status;
  late String? _claimStatus;

  // Make it nullable instead of using 'late'
  String? _imageUrl;

  // Make this nullable to prevent LateInitializationError
  final _statuses = ['found', 'lost'];
  final _claimStatuses = ['keep', 'turnover(guard)'];

  // String? _dateTime; // Add this to hold the updated dateTime
  final TextEditingController _dateTimeController = TextEditingController();

  // Dropdown options

  @override
  void initState() {
    super.initState();
    _dateTimeController.text = widget.ticket.dateTime; // Set the initial value
    _claimStatus = widget.ticket.claimStatus.isNotEmpty
        ? widget.ticket.claimStatus
        : 'keep'; // Set initial value for imageUrl

  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    _location =
    widget.ticket.location.isNotEmpty ? widget.ticket.location : null;
    _status = widget.ticket.status.isNotEmpty
        ? widget.ticket.status
        : 'lost'; // Default to 'Lost' if empty
    _imageUrl = widget.ticket.imageUrl.isNotEmpty
        ? widget.ticket.imageUrl
        : null; // Set initial value for imageUrl

    // _dateTime = widget.ticket.dateTime; // Initialize the dateTime with current ticket value

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Report")),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: widget.ticket.name,
                  decoration: const InputDecoration(labelText: "Item Name"),
                  validator: (value) =>
                  value!.isEmpty
                      ? "Enter item name"
                      : null,
                  onSaved: (value) => _name = value!,
                ),
                TextFormField(
                  initialValue: widget.ticket.description,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (value) =>
                  value!.isEmpty
                      ? "Enter description"
                      : null,
                  onSaved: (value) => _description = value!,
                ),
                TextFormField(
                    controller: _dateTimeController,
                    // Use the controller here
                    decoration: const InputDecoration(labelText: "Date & Time"),
                    readOnly: true,
                    // Make the field read-only to open the date picker
                    onTap: () async {
                      // Open Date Picker when tapped
                      DateTime? selectedDateTime = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );

                      if (selectedDateTime != null) {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );

                        if (selectedTime != null) {
                          // Combine the selected date and time
                          final dateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          // Update the controller with the new value
                          setState(() {
                            _dateTimeController.text =
                                DateFormat('yyyy-MM-dd hh:mm').format(dateTime);
                          });
                          // print(
                          //     "Updated dateTime in onTap: ${_dateTimeController
                          //         .text}");
                        }
                      }
                    }
                ),
                TextFormField(
                  initialValue: widget.ticket.fullName,
                  decoration: const InputDecoration(labelText: "Contact Name"),
                  validator: (value) =>
                  value!.isEmpty
                      ? "Enter contact name"
                      : null,
                  onSaved: (value) => _fullName = value!,
                ),
                TextFormField(
                  initialValue: widget.ticket.contactNumber,
                  decoration: const InputDecoration(
                      labelText: "Contact Number"),
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
                    if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                        .hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                Visibility(
                  visible: false, // This makes it hidden
                  child: TextFormField(
                    initialValue: widget.ticket.location,
                    decoration: const InputDecoration(
                      labelText: "Last Seen Location",
                    ),
                    validator: (value) =>
                    value!.isEmpty
                        ? "Enter last seen location"
                        : null,
                    onSaved: (value) => _location = value!,
                    // Nullable value
                    enabled: false, // This makes the field uneditable
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: widget.ticket.status.isNotEmpty
                      ? widget.ticket.status
                      : _statuses[0],
                  decoration: const InputDecoration(labelText: "Status"),
                  items: _statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _status = value!;
                  },
                  validator: (value) =>
                  value == null
                      ? "Select Item Status"
                      : null,
                ),
                // Check if the status is 'lost', if so, hide the dropdown.
                if (widget.ticket.status != 'lost') ...[
                  DropdownButtonFormField<String>(
                    value: widget.ticket.claimStatus.isNotEmpty ? widget.ticket
                        .claimStatus : _claimStatuses[0],
                    // Use _claimStatus here
                    decoration: const InputDecoration(
                        labelText: "Keep/Turnover"),
                    items: _claimStatuses.map((claimStatus) {
                      return DropdownMenuItem<String>(
                        value: claimStatus,
                        child: Text(claimStatus),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _claimStatus =
                        value!; // Update _claimStatus when the dropdown value changes
                      });
                    },
                    validator: (value) =>
                    value == null
                        ? "Select item type"
                        : null,
                  ),
                ],
                Visibility(
                  visible: false, // This makes it hidden
                  child: TextFormField(
                    initialValue: widget.ticket.imageUrl,
                    decoration: const InputDecoration(
                      labelText: "Image URL",
                    ),
                    validator: (value) =>
                    value!.isEmpty
                        ? "Enter image URL"
                        : null,
                    onSaved: (value) => _imageUrl = value!,
                    enabled: false, // This makes the field uneditable
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    child: const Text("Save Changes"),
                    onPressed: () {
                      // Check if claimStatus is 'turnover'
                      if (widget.ticket.claimStatus == 'turnover(guard)') {
                        // Show confirmation dialog if claimStatus is 'turnover'
                        _showTurnOverWarningDialog(context);
                      } else {
                        // Proceed to save changes if not 'turnover'
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _updateTicket(context);
                        }
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

  void _showTurnOverWarningDialog(BuildContext context) {
    // Ensure widget is still mounted before showing dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Warning"),
            content: const Text(
                "This item has been turned over. Are you sure you want to edit?"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  // Proceed with saving changes if the user confirms
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _updateTicket(context);
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text("Yes, Edit"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text("Cancel"),
              ),

            ],
          );
        },
      );
    }
  }

  void _updateTicket(BuildContext context) async {
    // print("DateTime before updateTicket: ${_dateTimeController
    //     .text}"); // Debugging line

    try {
      // Ensure widget is still mounted before updating
      if (mounted) {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.ticket.id)
            .update({
          'name': _name,
          'description': _description,
          'fullName': _fullName,
          'contactNumber': _contactNumber,
          'email': _email,
          'location': _location,
          'status': _status,
          'imageUrl': _imageUrl,
          'claimStatus': _claimStatus,
          // Use _claimStatus here to save the updated value
          'dateTime': _dateTimeController.text,
          // Save the updated dateTime here
        });
        // print(_claimStatus);
        Navigator.of(context).pop(); // Navigate back after update
      }
    } catch (error) {
      // print("Error updating ticket: $error");
    }
  }
}