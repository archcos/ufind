import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import 'package:intl/intl.dart';

import 'my_item_details.dart'; // Import the intl package for formatting

class MyReportsPage extends StatefulWidget {
  @override
  _MyReportsPageState createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 tabs: Pending, Success
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
                if (schoolId == '1234567890') {
                  return uid == schoolId || doc['claimStatus'] == 'turnover(guard)' || doc['claimStatus'] == 'turnover(osa)';
                } else {
                  return uid == schoolId;
                }
              })
                  .where((doc) => doc['ticket'] == 'pending')
                  .map((doc) => Ticket.fromDocument(doc))
                  .toList();

              final successTickets = snapshot.data!.docs
                  .where((doc) {
                final uid = doc.id.substring(0, 10);
                if (schoolId == '1234567890') {
                  return uid == schoolId || doc['claimStatus'] == 'turnover(guard)'  || doc['claimStatus'] == 'turnover(osa)';
                } else {
                  return uid == schoolId;
                }
              })
                  .where((doc) => doc['ticket'] == 'success')
                  .map((doc) => Ticket.fromDocument(doc))
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTicketGrid(pendingTickets, schoolId),
                  _buildTicketGrid(successTickets, schoolId),
                ],
              );
            },
          );
        },
      ),
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
        final isTurnedOver =
            ticket.claimStatus == 'turnover(guard)' || ticket.claimStatus == 'turnover(osa)';

        return GestureDetector(
          onTap: () {
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
                                onPressed: schoolId == '1234567890' || !isTurnedOver
                                    ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentEditTicketPage(ticket: ticket),
                                    ),
                                  );
                                }
                                    : null, // Disable edit for non-1234567890 users if turned over
                              ),
                            ],
                          ],
                        ),
                        Center(
                          child: TextButton(
                            onPressed: (!isTurnedOver || schoolId == '1234567890')
                                ? () {
                              if (ticket.ticket == 'pending') {
                                _showCompletionDialog(context, ticket);
                              }
                            }
                                : null, // Disable button for non-1234567890 users if turned over
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: (!isTurnedOver || schoolId == '1234567890')
                                  ? (ticket.ticket == 'pending'
                                  ? Colors.red // Active for pending tickets
                                  : Colors.green) // Completed tickets
                                  : Colors.grey, // Disabled button for turned over
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _showClaimDialog(context, ticket); // Show the claim details dialog
              },
              child: const Text('Yes'),
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



class StudentEditTicketPage extends StatefulWidget {
  final Ticket ticket;

  StudentEditTicketPage({required this.ticket});

  @override
  State<StudentEditTicketPage> createState() => _StudentEditTicketPageState();
}

class _StudentEditTicketPageState extends State<StudentEditTicketPage> {
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
  final _claimStatuses = ['keep', 'turnover(guard)', 'turnover(osa)'];

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
      appBar: AppBar(
        title: const Text("Edit Report"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name Field
              TextFormField(
                initialValue: widget.ticket.name,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) => value!.isEmpty ? "Enter item name" : null,
                onSaved: (value) => _name = value!,
              ),

              // Description Field
              TextFormField(
                initialValue: widget.ticket.description,
                decoration: const InputDecoration(
                  labelText: "Description",
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => value!.isEmpty ? "Enter description" : null,
                onSaved: (value) => _description = value!,
              ),

              // Date & Time Picker
              TextFormField(
                controller: _dateTimeController,
                decoration: const InputDecoration(
                  labelText: "Date & Time",
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
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
                      final dateTime = DateTime(
                        selectedDateTime.year,
                        selectedDateTime.month,
                        selectedDateTime.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      setState(() {
                        _dateTimeController.text =
                            DateFormat('yyyy-MM-dd hh:mm').format(dateTime);
                      });
                    }
                  }
                },
              ),

              // Contact Name Field
              TextFormField(
                initialValue: widget.ticket.fullName,
                decoration: const InputDecoration(
                  labelText: "Contact Name",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? "Enter contact name" : null,
                onSaved: (value) => _fullName = value!,
              ),

              // Contact Number Field
              TextFormField(
                initialValue: widget.ticket.contactNumber,
                decoration: const InputDecoration(
                  labelText: "Contact Number",
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Enter contact number";
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return "Enter a valid contact number";
                  }
                  return null;
                },
                onSaved: (value) => _contactNumber = value!,
              ),

              // Email Field
              TextFormField(
                initialValue: widget.ticket.email,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Enter email";
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),

              // Status Dropdown
              DropdownButtonFormField<String>(
                value: widget.ticket.status.isNotEmpty ? widget.ticket.status : _statuses[0],
                decoration: const InputDecoration(
                  labelText: "Status",
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) => _status = value!,
                validator: (value) => value == null ? "Select Item Status" : null,
              ),

              // Keep/Turnover Dropdown
              if (widget.ticket.status != 'lost')
                DropdownButtonFormField<String>(
                  value: widget.ticket.claimStatus.isNotEmpty
                      ? widget.ticket.claimStatus
                      : _claimStatuses[0],
                  decoration: const InputDecoration(
                    labelText: "Keep/Turnover",
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items: _claimStatuses.map((claimStatus) {
                    return DropdownMenuItem<String>(
                      value: claimStatus,
                      child: Text(claimStatus),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == 'turnover(osa)') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Only Campus Security can directly turnover to OSA. Please turnover to Guard first.',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      _claimStatus = _claimStatuses[0];
                    } else {
                      _claimStatus = value!;
                    }
                  },
                  validator: (value) => value == null ? "Select claim status" : null,
                ),

              const SizedBox(height: 20),

              // Save Changes Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _updateTicket(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.lightBlueAccent,
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _updateTicket(BuildContext context) async {
    // Check if the claimStatus is 'turnover(guard)' and set the appropriate values
    if (_claimStatus == 'turnover(guard)') {
      // Set specific fields for "turnover(guard)"
      _fullName = 'Campus Security - Gate Entrance';
      _contactNumber = '000000000';
      _email = 'noemail@gmail.com';
      _claimStatus = 'turnover(guard)'; // Ensure claimStatus is set to 'turnover(guard)'

      // Optionally, show a message or warning about the turnover
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This item is being turned over to the Guard.',
            style: TextStyle(color: Colors.white), // White text color
          ),
          backgroundColor: Colors.red, // Red background
          duration: Duration(seconds: 3), // Duration of the Snackbar
        ),
      );
    }

    try {
      // Ensure widget is still mounted before updating
      if (mounted) {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.ticket.id)
            .update({
          'name': _name,
          'description': _description,
          'fullName': _fullName, // Set to 'Campus Security - Gate Entrance'
          'contactNumber': _contactNumber, // Set to '000000000'
          'email': _email, // Set to 'noemail@gmail.com'
          'location': _location,
          'status': _status,
          'imageUrl': _imageUrl,
          'claimStatus': _claimStatus, // Set to 'turnover(guard)'
          'dateTime': _dateTimeController.text, // Save the updated dateTime here
        });

        Navigator.of(context).pop(); // Navigate back after update
      }
    } catch (error) {
      // Handle the error
      print("Error updating ticket: $error");
    }
  }
}