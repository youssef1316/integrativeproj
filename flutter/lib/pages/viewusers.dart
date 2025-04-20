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
    // ... (fetch logic remains the same as your last provided version) ...
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

      final List<QueryDocumentSnapshot> nonAdminUsers = allUserSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['role'] != 'admin';
      }).toList();
      nonAdminUsers.sort((a, b) {
        final nameA = (a.data() as Map<String, dynamic>?)?['name'] as String? ?? '';
        final nameB = (b.data() as Map<String, dynamic>?)?['name'] as String? ?? '';
        return nameA.compareTo(nameB);
      });

      final List<QueryDocumentSnapshot> soldTickets = allTicketSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['status'] == 'sold';
      }).toList();

      final Map<String, List<QueryDocumentSnapshot>> ticketsMap = {};
      for (var doc in soldTickets) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final userId = data['userId'] as String?;
        if (userId != null) {
          if (!ticketsMap.containsKey(userId)) {
            ticketsMap[userId] = [];
          }
          ticketsMap[userId]!.add(doc);
          ticketsMap[userId]!.sort((a, b) {
            final tsA = (a.data() as Map<String, dynamic>?)?['purchaseTimestamp'] as Timestamp?;
            final tsB = (b.data() as Map<String, dynamic>?)?['purchaseTimestamp'] as Timestamp?;
            if (tsA == null && tsB == null) return 0;
            if (tsA == null) return 1;
            if (tsB == null) return -1;
            return tsB.compareTo(tsA);
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _usersList = nonAdminUsers;
        _soldTicketsList = soldTickets;
        _ticketsByUserMap = ticketsMap;
        _isLoading = false;
      });

    } catch (e) {
      print("Error fetching/processing data: $e");
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
    // ... (snackbar logic remains the same) ...
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  // --- Function to Release a Ticket ---
  Future<void> _releaseTicket(String ticketId) async {
    // ... (release ticket logic remains the same) ...
    if (ticketId.isEmpty) return;

    final ticketIndex = _soldTicketsList.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) {
      _showSnackBar("Error: Ticket $ticketId not found in local list.", isError: true);
      return;
    }
    final ticketDoc = _soldTicketsList[ticketIndex];
    final ticketData = ticketDoc.data() as Map<String, dynamic>? ?? {};
    final ownerUserId = ticketData['userId'] as String?;


    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': 'available',
        'userId': FieldValue.delete(),
        'purchaseTimestamp': FieldValue.delete(),
      });

      if (mounted) {
        setState(() {
          _soldTicketsList.removeAt(ticketIndex);
          if(ownerUserId != null && _ticketsByUserMap.containsKey(ownerUserId)) {
            _ticketsByUserMap[ownerUserId]!.removeWhere((t) => t.id == ticketId);
          }
        });
        _showSnackBar("Ticket $ticketId released successfully.", isError: false);
      }

    } catch (e) {
      print("Error releasing ticket $ticketId: $e");
      _showSnackBar("Failed to release ticket. Error: ${e.toString()}");
    }
  }

  // --- Confirmation Dialog for Releasing Ticket ---
  void _confirmReleaseTicket(BuildContext context, String ticketId, String? eventId) {
    // ... (confirm dialog logic remains the same) ...
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Release"),
          content: Text("Are you sure you want to release ticket '$ticketId' for event '${eventId ?? 'N/A'}' and make it available again?"),
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
                Navigator.of(dialogContext).pop();
                _releaseTicket(ticketId);
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
      // *** ADDED: Set background color for the Scaffold ***
      backgroundColor: Colors.white,
      // ****************************************************
      appBar: AppBar(
          title: const Text("Users & Tickets"), // Updated title
          centerTitle: true,
          // Ensure AppBar background is also white if desired, or contrasts
          backgroundColor: Colors.white, // Set AppBar background to white
          foregroundColor: Colors.black, // Ensure title/icons are visible
          elevation: 1.0, // Add slight elevation for separation
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: _fetchAndProcessDataLocally,
            )
          ]
      ),
      body: _buildBody(), // Body content builder remains the same
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
          child: Text("Error: $_error", style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_usersList.isEmpty) {
      return const Center(child: Text("No non-admin users found."));
    }

    // Data is ready, build the list
    return Container( // Wrap ListView in a Container if Scaffold bg isn't enough
      color: Colors.white, // Ensure container background is white
      child: ListView.builder(
        itemCount: _usersList.length,
        itemBuilder: (context, index) {
          final userDoc = _usersList[index];
          final userData = userDoc.data() as Map<String, dynamic>? ?? {};
          final userName = userData['name'] ?? 'N/A';
          final userEmail = userData['email'] ?? 'N/A';
          final userRole = userData['role'] ?? 'N/A';
          final userId = userDoc.id;

          final userTickets = _ticketsByUserMap[userId] ?? [];

          // Use Card for better visual separation on white background
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            elevation: 1.5, // Add slight elevation to cards
            color: Colors.white, // Ensure card background is white
            child: ExpansionTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer, // Add bg color
              ),
              title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Email: $userEmail\nRole: $userRole"),
              childrenPadding: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 8.0),
              // Expansion tile children background defaults to theme, might need explicit coloring if needed
              // backgroundColor: Colors.white, // Optional: If expansion area needs explicit white
              children: <Widget>[
                // Display tickets from the map
                if (userTickets.isEmpty)
                  const ListTile(
                      dense: true, // Make it less prominent
                      title: Text("No tickets purchased by this user.", style: TextStyle(fontStyle: FontStyle.italic))
                  )
                else
                  Column(
                    children: userTickets.map((ticketDoc) {
                      final ticketData = ticketDoc.data() as Map<String, dynamic>? ?? {};
                      final ticketId = ticketDoc.id;
                      final eventId = ticketData['eventId'] ?? 'N/A';
                      final levelName = ticketData['levelName'] ?? 'N/A';
                      final purchaseTs = ticketData['purchaseTimestamp'] as Timestamp?;
                      String purchaseDate = 'N/A';
                      if (purchaseTs != null) {
                        try {
                          purchaseDate = DateFormat('yyyy-MM-dd hh:mm a').format(purchaseTs.toDate());
                        } catch(e){ purchaseDate = 'Invalid Date'; }
                      }

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.confirmation_num_outlined, size: 20),
                        title: Text("Event: $eventId", style: Theme.of(context).textTheme.bodyMedium),
                        subtitle: Text("Level: $levelName\nID: $ticketId\nPurchased: $purchaseDate", style: Theme.of(context).textTheme.bodySmall),
                        isThreeLine: true,
                        trailing: IconButton(
                          // Changed icon to delete for clarity
                          icon: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 22),
                          tooltip: 'Make Ticket Available Again',
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