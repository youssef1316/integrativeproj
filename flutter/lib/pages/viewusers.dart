// lib/pages/view_users.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For formatting timestamp

// Renamed class to follow Dart conventions
class ViewUsers extends StatefulWidget {
  const ViewUsers({super.key});

  @override
  // Renamed state class to follow Dart conventions
  State<ViewUsers> createState() => _ViewUsersScreenState();
}

// Renamed state class to follow Dart conventions
class _ViewUsersScreenState extends State<ViewUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  List<QueryDocumentSnapshot> _usersList = []; // Stores ONLY non-admin users after local filter
  List<QueryDocumentSnapshot> _soldTicketsList = []; // Stores ONLY sold tickets after local filter
  Map<String, List<QueryDocumentSnapshot>> _ticketsByUserMap = {};

  @override
  void initState() {
    super.initState();
    _fetchAndProcessDataLocally(); // Fetch and process data
  }

  // --- Fetch ALL Users and ALL Tickets, then Filter/Process Locally ---
  Future<void> _fetchAndProcessDataLocally() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usersFuture = _firestore.collection('users').get();
      final ticketsFuture = _firestore.collection('tickets').get();

      final results = await Future.wait([usersFuture, ticketsFuture]);

      final allUserSnapshot = results[0] as QuerySnapshot;
      final allTicketSnapshot = results[1] as QuerySnapshot;

      // Filter out admin users
      final List<QueryDocumentSnapshot> nonAdminUsers = allUserSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['role'] != 'admin';
      }).toList();
      // Sort users by name
      nonAdminUsers.sort((a, b) {
        final nameA = (a.data() as Map<String, dynamic>?)?['name'] as String? ?? '';
        final nameB = (b.data() as Map<String, dynamic>?)?['name'] as String? ?? '';
        return nameA.compareTo(nameB);
      });

      // Filter for sold tickets
      final List<QueryDocumentSnapshot> soldTickets = allTicketSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        // Ensure case-insensitivity if needed: (data['status'] as String?)?.toLowerCase() == 'sold'
        return data['status'] == 'sold';
      }).toList();

      // Group sold tickets by userId
      final Map<String, List<QueryDocumentSnapshot>> ticketsMap = {};
      for (var doc in soldTickets) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final userId = data['userId'] as String?;
        if (userId != null) {
          if (!ticketsMap.containsKey(userId)) {
            ticketsMap[userId] = [];
          }
          ticketsMap[userId]!.add(doc);
          // Sort tickets for each user by purchase date (newest first)
          ticketsMap[userId]!.sort((a, b) {
            final tsA = (a.data() as Map<String, dynamic>?)?['purchaseTimestamp'] as Timestamp?;
            final tsB = (b.data() as Map<String, dynamic>?)?['purchaseTimestamp'] as Timestamp?;
            if (tsA == null && tsB == null) return 0;
            if (tsA == null) return 1; // Treat nulls as older
            if (tsB == null) return -1;
            return tsB.compareTo(tsA); // Newest first
          });
        }
      }

      // Update state once all processing is done
      if (!mounted) return;
      setState(() {
        _usersList = nonAdminUsers;
        _soldTicketsList = soldTickets; // Keep the list of sold tickets
        _ticketsByUserMap = ticketsMap;
        _isLoading = false;
      });

    } catch (e, stacktrace) {
      print("Error fetching/processing data: $e");
      print("Stacktrace: $stacktrace");
      if (!mounted) return;
      setState(() {
        _error = "Failed to load data: ${e.toString()}";
        _isLoading = false;
      });
      _showSnackBar(_error!, isError: true);
    }
  }


  // Helper to show SnackBars
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  // --- Function to Release a Ticket (UPDATED with Event Update via Transaction) ---
  Future<void> _releaseTicket(String ticketId) async {
    if (ticketId.isEmpty) return;

    // Find the ticket locally first to get its data BEFORE the transaction
    final ticketIndex = _soldTicketsList.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) {
      _showSnackBar("Error: Ticket $ticketId not found in local list.", isError: true);
      return;
    }
    final ticketDocSnapshot = _soldTicketsList[ticketIndex];
    final ticketData = ticketDocSnapshot.data() as Map<String, dynamic>? ?? {};
    final ownerUserId = ticketData['userId'] as String?;
    final eventId = ticketData['eventId'] as String?;
    final ticketPrice = (ticketData['price'] as num?)?.toDouble(); // Get price

    // Validate necessary data before transaction
    if (eventId == null || eventId.isEmpty) {
      _showSnackBar("Error: Cannot release ticket $ticketId - Event ID is missing.", isError: true);
      return;
    }
    if (ticketPrice == null) {
      _showSnackBar("Error: Cannot release ticket $ticketId - Ticket price is missing.", isError: true);
      return;
    }


    // Use a Firestore transaction to update both ticket and event
    try {
      await _firestore.runTransaction((transaction) async {
        // Define document references
        final ticketRef = _firestore.collection('tickets').doc(ticketId);
        final eventRef = _firestore.collection('events').doc(eventId);

        // 1. Update the Ticket Document
        transaction.update(ticketRef, {
          'status': 'available', // Change status
          'userId': FieldValue.delete(), // Remove user association
          'purchaseTimestamp': FieldValue.delete(), // Remove purchase time
        });

        // 2. Update the Event Document
        //    Decrement sold count and revenue using FieldValue.increment
        //    Ensure your field names 'totalTicketsSold' and 'totalRevenue' are correct
        transaction.update(eventRef, {
          'totalTicketsSold': FieldValue.increment(-1), // Decrement count by 1
          'totalRevenue': FieldValue.increment(-ticketPrice), // Decrement revenue by ticket price
        });

      }); // Transaction commits automatically if no errors

      // If transaction succeeds, update local state
      if (mounted) {
        setState(() {
          _soldTicketsList.removeAt(ticketIndex); // Remove from local sold list
          if(ownerUserId != null && _ticketsByUserMap.containsKey(ownerUserId)) {
            // Remove from the user's ticket map in the UI
            _ticketsByUserMap[ownerUserId]!.removeWhere((t) => t.id == ticketId);
            // Optional: Remove the user map entry if list becomes empty
            if (_ticketsByUserMap[ownerUserId]!.isEmpty) {
              _ticketsByUserMap.remove(ownerUserId);
            }
          }
        });
        _showSnackBar("Ticket $ticketId released successfully. Event totals updated.", isError: false);
      }

    } catch (e) {
      print("Error during transaction for releasing ticket $ticketId: $e");
      _showSnackBar("Failed to release ticket. Error: ${e.toString()}", isError: true);
      // Note: If the transaction fails, local state is not changed, reflecting DB state.
    }
  }

  // --- Confirmation Dialog for Releasing Ticket ---
  void _confirmReleaseTicket(BuildContext context, String ticketId, String? eventId) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Release"),
          // Improved confirmation message
          content: Text("Release ticket '$ticketId' for event '${eventId ?? 'Unknown'}'?\n\nThis makes the ticket available again and updates event totals."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Release Ticket"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _releaseTicket(ticketId); // Perform the release action
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure scaffold background is white
      appBar: AppBar(
          title: const Text("Users & Tickets"),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1.0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: _isLoading ? null : _fetchAndProcessDataLocally, // Disable while loading
            )
          ]
      ),
      body: _buildBody(),
    );
  }

  // Helper method to build the body based on state
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column( // Added column for better layout with retry button
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Error: $_error", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: _fetchAndProcessDataLocally,
                    child: const Text("Retry")
                )
              ],
            )
        ),
      );
    }
    // Check if list is empty AFTER filtering non-admins
    if (_usersList.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column( // Added column for better layout with refresh button
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("No non-admin users found."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: _fetchAndProcessDataLocally,
                      child: const Text("Refresh")
                  )
                ],
              )
          )
      );
    }

    // Data is ready, build the list
    return Container(
      color: Colors.white, // Ensure container background is white
      child: ListView.builder(
        itemCount: _usersList.length,
        itemBuilder: (context, index) {
          final userDoc = _usersList[index];
          final userData = userDoc.data() as Map<String, dynamic>? ?? {};
          final userName = userData['name'] ?? 'N/A';
          final userEmail = userData['email'] ?? 'N/A';
          final userRole = userData['role'] ?? 'N/A'; // Should not be admin here
          final userId = userDoc.id;

          final userTickets = _ticketsByUserMap[userId] ?? []; // Get tickets for this user

          // Use Card for better visual separation on white background
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            elevation: 1.5,
            color: Colors.white,
            shape: RoundedRectangleBorder( // Added slightly rounded corners
                borderRadius: BorderRadius.circular(6.0)
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                // Display initials if possible, fallback to icon
                // child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: TextStyle(color: Colors.white)),
                child: const Icon(Icons.person), // Simpler icon approach
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
              title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              // Simpler subtitle
              subtitle: Text(userEmail),
              childrenPadding: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 8.0),
              children: <Widget>[
                // Display tickets for this user
                if (userTickets.isEmpty)
                  const ListTile(
                      dense: true,
                      title: Text("No tickets purchased by this user.", style: TextStyle(fontStyle: FontStyle.italic))
                  )
                else
                  Column( // Use column to list tickets
                    children: userTickets.map((ticketDoc) {
                      final ticketData = ticketDoc.data() as Map<String, dynamic>? ?? {};
                      final ticketId = ticketDoc.id;
                      final eventId = ticketData['eventId'] ?? 'N/A';
                      final levelName = ticketData['levelName'] ?? 'N/A';
                      final ticketPrice = (ticketData['price'] as num?)?.toDouble() ?? 0.0; // Get price for potential display
                      final purchaseTs = ticketData['purchaseTimestamp'] as Timestamp?;
                      String purchaseDate = 'N/A';
                      if (purchaseTs != null) {
                        try {
                          // Use a standard date format
                          purchaseDate = DateFormat.yMd().add_jm().format(purchaseTs.toDate());
                        } catch(e){ purchaseDate = 'Invalid Date'; }
                      }

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.confirmation_num_outlined, size: 20),
                        title: Text("Event: $eventId", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        // More detailed subtitle
                        subtitle: Text("Level: $levelName\nID: $ticketId\nPurchased: $purchaseDate", style: Theme.of(context).textTheme.bodySmall),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 24), // Changed icon to represent "release"
                          tooltip: 'Release Ticket (Make Available)', // Updated tooltip
                          onPressed: () {
                            _confirmReleaseTicket(context, ticketId, eventId);
                          },
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}