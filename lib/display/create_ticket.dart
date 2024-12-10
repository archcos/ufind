import 'dart:io';  // For file handling
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';  // For DateFormat
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';  // For image selection
import 'package:supabase_flutter/supabase_flutter.dart';  // For Supabase upload
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data'; // For Uint8List
import 'dart:math';

class TicketDetailsPage extends StatefulWidget {
  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Fields
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _lastSeenLocation = "Tap to set location";
  LatLng? _selectedLocation;
  String _itemType = '';  // 'Lost' or 'Found'

  // Image Upload Fields
  File? _selectedImage;  // Selected image file
  final ImagePicker _picker = ImagePicker();  // Image picker instance
  String? _imageUrl;  // URL of the uploaded image

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Show Item Type Selection Dialog
  void _showItemTypeDialog() {
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


  Future<File?> _compressImage(File image) async {
    // Read the image as bytes (Uint8List)
    final Uint8List imageBytes = await image.readAsBytes();

    // Compress the image using flutter_image_compress
    final List<int>? result = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 400, // Resize width (adjust as needed)
      quality: 50,    // Set the quality (lower for better compression)
    );

    if (result == null) {
      return null;
    }

    // Convert List<int> result to Uint8List
    final Uint8List compressedBytes = Uint8List.fromList(result);

    // Create a new file with the compressed bytes
    final compressedImage = File(image.path)..writeAsBytesSync(compressedBytes);

    // Print the original and compressed image sizes for debugging
    print('Original image size: ${image.lengthSync()} bytes');
    print('Compressed image size: ${compressedImage.lengthSync()} bytes');

    return compressedImage;
  }

  // Upload Image to Supabase
  // Upload Image to Supabase with compression
  Future<String?> _uploadImageToSupabase() async {
    if (_selectedImage == null) return null;

    try {
      // Compress the image before uploading
      File? compressedImage = await _compressImage(_selectedImage!);

      if (compressedImage == null) {
        throw Exception('Error compressing image');
      }

      // Create a unique file name with a timestamp to avoid overwriting
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the compressed image to Supabase storage
      final response = await Supabase.instance.client.storage
          .from('images') // 'images' is the name of your bucket
          .upload(fileName, compressedImage);

      // Check if the upload was successful
      if (response.error != null) {
        throw response.error!;
      }

      // Retrieve the public URL for the uploaded file
      final publicUrl = 'https://tqvgagdffmjtxswldtgm.supabase.co/storage/v1/object/public/images/$fileName';

      // Return the URL as a string
      return publicUrl;

    } catch (e) {
      print('Error uploading image: $e');
      // Handle any errors during upload
      return null;
    }
  }


  // Save Ticket Data to Firebase Firestore
  Future<void> _saveToFirebase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? schoolId = prefs.getString('user_school_id');

    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('School ID not found. Please log in again.')),
      );
      return;
    }

    // Check if all fields are filled out correctly
    if (_itemNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _dateTimeController.text.isEmpty ||
        _contactNameController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _itemType.isEmpty ||
        _lastSeenLocation == "Tap to set location" ||
        _imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out all fields and upload an image!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generate a unique document ID
    String uniqueId = _generateRandomId();
    String documentId = '${schoolId}_$uniqueId';

    // Save ticket details to Firestore
    await FirebaseFirestore.instance.collection('tickets').doc(documentId).set({
      'itemType': _itemType,
      'itemName': _itemNameController.text,
      'description': _descriptionController.text,
      'dateTime': _dateTimeController.text,
      'contactName': _contactNameController.text,
      'contactNumber': _contactNumberController.text,
      'email': _emailController.text,
      'lastSeenLocation': _lastSeenLocation,
      'schoolId': schoolId,
      'status': 'Pending',
      'imageUrl': _imageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ticket Saved Successfully!')),
    );
  }

// Generate 8-character random alphanumeric ID
  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }


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


  // Pick an Image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Pick Location
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

  // UI Elements
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
        onPressed: () async {
          // Upload image to Supabase first and get the image URL
          final imageUrl = await _uploadImageToSupabase();
          print(imageUrl);

          if (imageUrl != null) {
            setState(() {
              _imageUrl = imageUrl;  // Set the image URL after successful upload
            });
            // Proceed to save the ticket details to Firebase
            _saveToFirebase();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed. Please try again.')),
            );
          }
        },
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
          GestureDetector(
            onTap: _pickLocation,
            child: AbsorbPointer(
              child: ListTile(
                title: Text("Last Seen Location"),
                subtitle: Text(_lastSeenLocation),
                trailing: Icon(Icons.map),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text(_selectedImage == null ? 'Pick Image' : 'Change Image'),
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

extension on String {
  get error => null;
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
