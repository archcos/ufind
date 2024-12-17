import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/ticket_model.dart';
import 'item_details.dart';
import 'package:intl/intl.dart';

class ItemsListPage extends StatefulWidget {
  @override
  _ItemsListPageState createState() => _ItemsListPageState();
}

class _ItemsListPageState extends State<ItemsListPage> {
  String searchQuery = "";
  bool isSearching = false;
  String selectedFilter = "Time";  // Default sorting to 'Time' (Newest first)
  String typeFilter = "All";       // Default filter
  bool isDescending = true;        // Default to descending (Newest first)

  // Function to check if the item is recent (within the last `daysAgo` days)
  bool isItemRecent(DateTime itemDate, {int daysAgo = 30}) {
    final now = DateTime.now();
    final daysDifference = now.difference(itemDate).inDays;
    return daysDifference <= daysAgo; // Return true if item is within the last `daysAgo` days
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
          decoration: const InputDecoration(
            hintText: "Search items...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black12),
          ),
          style: const TextStyle(color: Colors.black54),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        )
            : const Text("Items Feed"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) searchQuery = "";
                isSearching = !isSearching;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == "Lost" || value == "Found" || value == "All") {
                  typeFilter = value;
                } else if (value == "Ascending") {
                  isDescending = false; // Set to ascending
                } else if (value == "Descending") {
                  isDescending = true;  // Set to descending
                } else {
                  selectedFilter = value;  // Change sort criteria (e.g. by time or alphabetically)
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Time", child: Text("Sort by Time")),
              const PopupMenuItem(value: "Alphabetical", child: Text("Sort Alphabetically")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: "Lost", child: Text("Show Only Lost")),
              const PopupMenuItem(value: "Found", child: Text("Show Only Found")),
              const PopupMenuItem(value: "All", child: Text("Show All")),
              const PopupMenuItem(value: "Ascending", child: Text("Sort Ascending")),
              const PopupMenuItem(value: "Descending", child: Text("Sort Descending")),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .orderBy(
          selectedFilter == "Time" ? "dateTime" : "itemName",
          descending: selectedFilter == "Time" ? isDescending : false,  // Sort by dateTime descending for default
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = snapshot.data!.docs
              .map((doc) => Ticket.fromDocument(doc))
              .where((ticket) =>
          (ticket.itemName.toLowerCase().contains(searchQuery) ||
              ticket.description.toLowerCase().contains(searchQuery)) &&
              (typeFilter == "All" || ticket.itemType == typeFilter) &&
              ticket.status != "Completed" && // Exclude tickets with status 'Completed'
              isItemRecent(DateTime.parse(ticket.dateTime)) // Filter by recent date
          )
              .toList();

          // If Alphabetical is selected, perform client-side sorting
          if (selectedFilter == "Alphabetical") {
            tickets.sort((a, b) {
              // Compare the item names alphabetically, considering ascending/descending order
              int comparison = a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
              return isDescending ? -comparison : comparison;  // Reverse if descending
            });
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 2,
              childAspectRatio: 0.44,
            ),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsPage(ticket: ticket),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.imageUrl.isNotEmpty)
                        Container(
                          height: 120, // Adjust the height of the image container
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8), // Ensure clipping matches the border radius
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: ticket.imageUrl,
                                  fit: BoxFit.cover,
                                  height: double.infinity,
                                  width: double.infinity,
                                  placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.itemName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                ticket.itemType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ticket.itemType == 'Found' ? Colors.green : Colors.red, // Conditional color based on itemType
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Spacer(), // This will push the following widget to the bottom
                              Text(
                                DateFormat('MM-dd-yy h:mm a').format(DateTime.parse(ticket.dateTime)),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
