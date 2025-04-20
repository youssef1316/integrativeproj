// lib/pages/view_users.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For formatting timestamp

class ViewUsers extends StatefulWidget {
  const ViewUsers({super.key});

  @override
  State<ViewUsers> createState() => _ViewUsersScreen();
}

class _ViewUsersScreen extends State<ViewUsers> {
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
      // 1. Fetch ALL users (NO server-side filtering)
      // WARNING: Reads all user documents! Consider adding .limit() for safety on large dbs.
      final usersFuture = _firestore.collection('users').get();
      // final usersFuture = _firestore.collection('users').limit(500).get(); // Example limit

      // 2. Fetch ALL tickets (NO server-side filtering)
      // WARNING: Reads all ticket documents! Consider adding .limit() for safety.
      final ticketsFuture = _firestore.collection('tickets').get();
      // final ticketsFuture = _firestore.collection('tickets').limit(2000).get(); // Example limit


      // Wait for both fetches
      final results = await Future.wait([usersFuture, ticketsFuture]);

      final allUserSnapshot = results[0] as QuerySnapshot;
      final allTicketSnapshot = results[1] as QuerySnapshot;

      // --- 3. LOCAL PROCESSING ---

      // Filter out admin users locally and sort
      final List<QueryDocumentSnapshot> nonAdminUsers = allUserSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['role'] != 'admin'; // Local filter for role
      }).toList();
      // Sort the filtered list
      nonAdminUsers.sort((a, b) {
        final nameA = (a.data() as Map<String, dynamic>?)?['name'] as String? ?? '';
        final nameB = (b.data() as Map<String, dynamic>?)?['name'] as String? ?? '';
        return nameA.compareTo(nameB);
      });


      // Filter for 'sold' tickets locally
      final List<QueryDocumentSnapshot> soldTickets = allTicketSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['status'] == 'sold'; // Local filter for status
      }).toList();


      // Group filtered 'sold' tickets by userId locally
      final Map<String, List<QueryDocumentSnapshot>> ticketsMap = {};
      for (var doc in soldTickets) { // Iterate only over locally filtered sold tickets
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final userId = data['userId'] as String?;
        if (userId != null) {
          if (!ticketsMap.containsKey(userId)) {
            ticketsMap[userId] = [];
          }
          ticketsMap[userId]!.add(doc);
          // Sort tickets within the user's list (descending by purchase time)
          ticketsMap[userId]!.sort((a, b) {
            final tsA = (a.data() as Map<String, dynamic>?)?['purchaseTimestamp'] as Timestamp?;
            final tsB = (b.data() as Map<String, dynamic>?)?['purchaseTimestamp'] as Timestamp?;
            if (tsA == null && tsB == null) return 0;
            if (tsA == null) return 1; // Nulls last
            if (tsB == null) return -1; // Nulls last
            return tsB.compareTo(tsA); // Descending
          });
        }
      }
      // --- End of Local Processing ---


      // Update state with locally processed data
      if (!mounted) return;
      setState(() {
        _usersList = nonAdminUsers; // Store filtered non-admin users
        _soldTicketsList = soldTickets; // Store filtered sold tickets
        _ticketsByUserMap = ticketsMap; // Store grouped tickets
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  // --- Function to Release a Ticket (Updates Firestore and Local State) ---
  Future<void> _releaseTicket(String ticketId) async {
    if (ticketId.isEmpty) return;

    // Find the ticket locally to get userId BEFORE updating Firestore
    // Search within the locally filtered _soldTicketsList
    final ticketIndex = _soldTicketsList.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) {
      // Should not happen if button is clicked on displayed ticket, but good check
      _showSnackBar("Error: Ticket $ticketId not found in local list.", isError: true);
      return;
    }
    final ticketDoc = _soldTicketsList[ticketIndex];
    final ticketData = ticketDoc.data() as Map<String, dynamic>? ?? {};
    final ownerUserId = ticketData['userId'] as String?;


    try {
      // 1. Update Firestore
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': 'available',
        'userId': FieldValue.delete(),
        'purchaseTimestamp': FieldValue.delete(),
      });

      // 2. Update Local State immediately for better UX
      if (mounted) {
        setState(() {
          // Remove from the local list of sold tickets
          _soldTicketsList.removeAt(ticketIndex);
          // Remove from the user-specific map
          if(ownerUserId != null && _ticketsByUserMap.containsKey(ownerUserId)) {
            _ticketsByUserMap[ownerUserId]!.removeWhere((t) => t.id == ticketId);
            // Optional: Clean up map entry if user has no more tickets
            // if (_ticketsByUserMap[ownerUserId]!.isEmpty) {
            //    _ticketsByUserMap.remove(ownerUserId);
            // }
          }
          // Note: _usersList doesn't need update here as we only modified ticket data
        });
        _showSnackBar("Ticket $ticketId released successfully.", isError: false);
      }

    } catch (e) {
      print("Error releasing ticket $ticketId: $e");
      _showSnackBar("Failed to release ticket. Error: ${e.toString()}");
      // Note: If Firestore update fails, local state is NOT reverted here.
      // More complex logic would be needed for rollback if required.
    }
  }

  // --- Confirmation Dialog for Releasing Ticket (No changes needed) ---
  void _confirmReleaseTicket(BuildContext context, String ticketId, String? eventId) {
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
                _releaseTicket(ticketId); // Proceed with releasing
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
      appBar: AppBar(
          title: const Text("Users & Tickets"), // Updated title for clarity
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: _fetchAndProcessDataLocally, // Call fetch again
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
          child: Text("Error: $_error", style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    // Use the locally filtered _usersList
    if (_usersList.isEmpty) {
      return const Center(child: Text("No non-admin users found."));
    }

    // Data is ready, build the list using locally filtered/processed data
    return ListView.builder(
      itemCount: _usersList.length, // Count of non-admin users
      itemBuilder: (context, index) {
        final userDoc = _usersList[index]; // Already filtered user
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final userName = userData['name'] ?? 'N/A';
        final userEmail = userData['email'] ?? 'N/A';
        final userRole = userData['role'] ?? 'N/A';
        final userId = userDoc.id;

        // Get the tickets for this user from the pre-processed map
        final userTickets = _ticketsByUserMap[userId] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ExpansionTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Email: $userEmail\nRole: $userRole"),
            childrenPadding: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 8.0),
            children: <Widget>[
              // Display tickets from the map
              if (userTickets.isEmpty)
                const ListTile(title: Text("No tickets purchased by this user."))
              else
                Column( // Use Column for the list of tickets
                  children: userTickets.map((ticketDoc) { // Iterate over locally stored tickets for user
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
                        icon: const Icon(Icons.delete, color: Colors.red, size: 22),
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
    );
  }
}