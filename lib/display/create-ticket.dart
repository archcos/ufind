import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';  // Import for DateFormat
import 'package:shared_preferences/shared_preferences.dart';

class TicketDetailsPage extends StatefulWidget {
  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form fields
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _lastSeenLocation = "Tap to set location";
  LatLng? _selectedLocation;

  String _itemType = ''; // 'Lost' or 'Found'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Function to show the item type selection dialog
  void _showItemTypeDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Item Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Lost'),
              onTap: () {
                setState(() {
                  _itemType = 'Lost';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Found'),
              onTap: () {
                setState(() {
                  _itemType = 'Found';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to validate and save data to Firebase
  void _saveToFirebase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? schoolId = prefs.getString('user_school_id'); // Retrieve the school ID

    if (schoolId == null) {
      // Handle case where the school ID is not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('School ID not found. Please log in again.')),
      );
      return;
    }
    if (_itemNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _dateTimeController.text.isEmpty ||
        _contactNameController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _itemType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill out all fields!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    FirebaseFirestore.instance.collection('tickets').add({
      'itemType': _itemType,
      'itemName': _itemNameController.text,
      'description': _descriptionController.text,
      'dateTime': _dateTimeController.text,
      'contactName': _contactNameController.text,
      'contactNumber': _contactNumberController.text,
      'email': _emailController.text,
      'lastSeenLocation': _lastSeenLocation,
      'schoolId': schoolId,  // Add school ID to the ticket
      'status': 'Pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ticket Saved Successfully!')),
    );
  }

  // Function to open DatePicker
  Future<void> _pickDateTime() async {
    DateTime initialDate = DateTime.now();
    DateTime pickedDate = (await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    )) ??
        initialDate;

    TimeOfDay pickedTime = (await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    )) ??
        TimeOfDay.fromDateTime(initialDate);

    setState(() {
      _dateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute),
      );
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialPosition: LatLng(8.485738, 124.657011),
        ),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _selectedLocation = result;
        _lastSeenLocation = '(${result.latitude}, ${result.longitude})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ticket Details"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Ticket Info"),
            Tab(text: "Contact Info"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Initial popup dialog for item type
          if (_itemType.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: _showItemTypeDialog,
                child: Text('Select Lost or Found'),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketInfoTab(),
                _buildContactInfoTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveToFirebase,
        child: Icon(Icons.save),
      ),
    );
  }

  Widget _buildTicketInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildTextField("Item Name", _itemNameController),
          _buildTextField("Description", _descriptionController),
          GestureDetector(
            onTap: _pickDateTime,
            child: AbsorbPointer(
              child: _buildTextField("Date & Time", _dateTimeController),
            ),
          ),
          ListTile(
            title: Text("Last Seen Location"),
            subtitle: Text(_lastSeenLocation),
            trailing: Icon(Icons.map),
            onTap: _pickLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildTextField("Full Name", _contactNameController),
          _buildTextField("Contact Number", _contactNumberController),
          _buildTextField("Email", _emailController),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const MapPickerScreen({required this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pick Location")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.initialPosition, // Update 'center' to 'initialCenter'
          initialZoom: 18.0,
          onTap: (tapPosition, latLng) {
            setState(() {
              selectedLocation = latLng;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context, selectedLocation),
        child: Icon(Icons.check),
      ),
    );
  }
}
