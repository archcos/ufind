import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:untitled/display/create_ticket.dart';
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
                if (value == "lost" || value == "found" || value == "All") {
                  typeFilter = value;
                } else if (value == "Ascending") {
                  isDescending = false; // Set to ascending
                } else if (value == "Descending") {
                  isDescending = true;  // Set to descending
                } else {
                  selectedFilter = value;  // Change sort criteria (e.g. by time or alphabetically)
                  if (value == "Alphabetical") {
                    isDescending = false;  // Ensure it's sorted in ascending order when Alphabetical is selected
                  }
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Time", child: Text("Sort by Time")),
              const PopupMenuItem(value: "Alphabetical", child: Text("Sort Alphabetically")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: "lost", child: Text("Show Only Lost")),
              const PopupMenuItem(value: "found", child: Text("Show Only Found")),
              const PopupMenuItem(value: "All", child: Text("Show All")),
              const PopupMenuItem(value: "Ascending", child: Text("Sort Ascending")),
              const PopupMenuItem(value: "Descending", child: Text("Sort Descending")),
            ],
          )

        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .orderBy("dateTime", descending: isDescending)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Map Firestore documents to Ticket models
          final tickets = snapshot.data!.docs
              .map((doc) => Ticket.fromDocument(doc))
              .where((ticket) =>
          (ticket.name.toLowerCase().contains(searchQuery) ||
              ticket.description.toLowerCase().contains(searchQuery)) &&
              (typeFilter == "All" || ticket.status == typeFilter) &&
              ticket.ticket != "success" && // Exclude tickets with status 'Completed'
              isItemRecent(DateTime.parse(ticket.dateTime))) // Filter by recent date
              .toList();

          // Apply client-side sorting for "Alphabetical"
          if (selectedFilter == "Alphabetical") {
            tickets.sort((a, b) {
              int comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              return isDescending ? -comparison : comparison; // Reverse if descending
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
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                if (ticket.status != 'lost')
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                        child: Container(
                                          color: Colors.black.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
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
                                ticket.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                ticket.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ticket.status == 'found' ? Colors.green : Colors.red,
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
                              const Spacer(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailsPage(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        tooltip: 'Add New Ticket', // You can change the color to match your design
        child: const Icon(
          Icons.add, // You can change the icon to something like a plus sign or a ticket icon
          color: Colors.white,
        ), // This shows a hint when the user hovers over or taps the button
      ),
    );
  }
}
