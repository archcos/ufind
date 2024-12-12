import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/ticket_model.dart';  // Import latlong2 for latitude and longitude

class ItemDetailsPage extends StatelessWidget {
  final Ticket ticket;

  ItemDetailsPage({required this.ticket});

  // Helper function to parse the location string and extract latitude and longitude
  LatLng _parseLocation(String location) {
    // Remove the parentheses and split by comma
    final coordinates = location
        .replaceAll('(', '')
        .replaceAll(')', '')
        .split(',');

    // Parse latitude and longitude into double
    double latitude = double.tryParse(coordinates[0].trim()) ?? 0.0;
    double longitude = double.tryParse(coordinates[1].trim()) ?? 0.0;

    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    final latLng = _parseLocation(ticket.lastSeenLocation);

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.itemName),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Use SingleChildScrollView for better scrolling behavior
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Displaying the image using CachedNetworkImage
              if (ticket.imageUrl.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // Ensure the CachedNetworkImage takes up all the space
                        CachedNetworkImage(
                          imageUrl: ticket.imageUrl,
                          fit: BoxFit.cover,  // Ensure the image covers the container
                          width: double.infinity, // Ensure the image spans the full width
                          height: double.infinity, // Ensure the image spans the full height
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                        if (ticket.itemType != 'Lost')
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Apply blur effect
                              child: Container(
                                color: Colors.black.withOpacity(0.1), // Optional dark overlay
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              // Item name
              Text('Item Name: ${ticket.itemName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Description
              Text('Description: ${ticket.description}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              // Date and time
              Text('Date & Time: ${ticket.dateTime}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              // Contact Name
              Text('Contact Name: ${ticket.contactName}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              // Contact Number
              Text('Contact Number: ${ticket.contactNumber}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              // Email
              Text('Email: ${ticket.email}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),

              // Conditionally display Last Seen Location and Map only if item type is 'Lost'
              if (ticket.itemType == 'Lost') ...[
                // Last Seen Location with clickable functionality
                GestureDetector(
                  onTap: () {
                    // You can add an onTap action here if needed
                  },
                  child: Text(
                    'Last Seen Location: ${ticket.lastSeenLocation}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Map displaying the location
                SizedBox(
                  height: 300,  // Height of the map container
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: latLng,  // Center the map on the ticket's location
                      initialZoom: 18,  // Adjust zoom level
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",  // OpenStreetMap tiles
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,  // Marker at the last seen location
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
