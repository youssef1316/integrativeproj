// lib/pages/user_home.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmangment/main.dart'; // For AppRoutes (Ensure this path is correct)
import 'package:intl/intl.dart'; // For date formatting
import 'package:qr_flutter/qr_flutter.dart'; // Import for QR code display
import 'venue_layout_page.dart';//to view the venue layout

// --- Styles Class ---
class _UserHomeStyles {
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const double buttonSpacing = 20.0;
}
// --------------------

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  // Helper method for navigation
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  // Logout Function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Navigate back to Login screen and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login, // Ensure AppRoutes.login is defined
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error during logout: $e");
      if (context.mounted) {
        _showErrorSnackBar(context, "Logout failed: ${e.toString()}");
      }
    }
  }

  // --- Function to show the User Profile Dialog ---
  void _showUserProfileDialog(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _showErrorSnackBar(context, "Error: User not logged in.");
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('User Profile'),
          content: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              // Handle Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Handle Error state
              if (snapshot.hasError) {
                print("Error fetching profile: ${snapshot.error}");
                return const Text('Error loading profile.');
              }
              // Handle No Data / Document doesn't exist
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text('Profile data not found.');
              }

              // Data successfully fetched
              Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = userData['name'] ?? 'N/A';
              String email = userData['email'] ?? 'N/A';
              String role = userData['role'] ?? 'N/A';

              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    _buildProfileRow('Name:', name),
                    _buildProfileRow('Email:', email),
                    _buildProfileRow('Role:', role),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper widget to build a row in the profile dialog
  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // --- Function to show the "My Tickets" Dialog (Using Local Filtering/Sorting) ---
  void _showMyTicketsDialog(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showErrorSnackBar(context, "Error: User not logged in.");
      return;
    }

    // Query: Fetch all tickets matching the user's ID
    final Stream<QuerySnapshot> userTicketsStream = FirebaseFirestore.instance
        .collection('tickets')
        .where('userId', isEqualTo: userId) // Only filter by user
        .snapshots(); // Use a stream for real-time updates

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("My Purchased Tickets"),
          content: SizedBox(
            width: double.maxFinite, // Use available width
            child: StreamBuilder<QuerySnapshot>(
              stream: userTicketsStream, // Stream of all user's tickets
              builder: (context, snapshot) {
                // Handle Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handle Errors (e.g., permissions, network)
                if (snapshot.hasError) {
                  print("Firestore Error loading user tickets: ${snapshot.error}"); // Log error
                  return Center(child: Text("Error loading tickets: ${snapshot.error}"));
                }

                // Handle No Data (User has no tickets associated with their account at all)
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No tickets found for this account."));
                }

                // --- Process Data Locally ---
                List<QueryDocumentSnapshot> allUserTickets = snapshot.data!.docs;

                // 1. Filter locally for 'sold' status
                List<QueryDocumentSnapshot> soldTickets = allUserTickets.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  // Ensure data exists and status is exactly 'sold'
                  return data != null && data['status'] == 'sold';
                }).toList();

                // 2. Sort the filtered 'sold' tickets locally by purchase timestamp
                soldTickets.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>? ?? {};
                  final dataB = b.data() as Map<String, dynamic>? ?? {};
                  final Timestamp? tsA = dataA['purchaseTimestamp'] as Timestamp?;
                  final Timestamp? tsB = dataB['purchaseTimestamp'] as Timestamp?;

                  // Handle cases where timestamps might be null
                  if (tsA == null && tsB == null) return 0; // Both null, equal
                  if (tsA == null) return 1; // Nulls go last
                  if (tsB == null) return -1; // Nulls go last

                  // Compare valid timestamps descending (newest first)
                  return tsB.compareTo(tsA);
                });
                // --- End of Local Processing ---

                // Handle No 'Sold' Tickets Found (after filtering)
                if (soldTickets.isEmpty) {
                  return const Center(child: Text("No tickets purchased yet."));
                }

                // Display the filtered and sorted list
                return ListView.builder(
                  itemCount: soldTickets.length, // Count of 'sold' tickets
                  shrinkWrap: true, // Important for ListView inside AlertDialog
                  itemBuilder: (context, index) {
                    // Get data from the processed list item
                    final ticketDoc = soldTickets[index];
                    final ticketData = ticketDoc.data() as Map<String, dynamic>? ?? {};

                    // Safely extract data with fallbacks
                    final eventId = ticketData['eventId'] as String? ?? 'N/A';
                    final levelName = ticketData['levelName'] as String? ?? 'N/A';
                    final ticketId = ticketData['ticketId'] as String? ?? ticketDoc.id; // Use document ID if field missing
                    final purchaseTs = ticketData['purchaseTimestamp'] as Timestamp?;

                    // Format timestamp if available
                    String purchaseDate = 'N/A';
                    if (purchaseTs != null) {
                      try {
                        purchaseDate = DateFormat('yyyy-MM-dd hh:mm a').format(purchaseTs.toDate());
                      } catch (e) {
                        print("Error formatting date: $e");
                        purchaseDate = "Invalid Date"; // Handle potential formatting errors
                      }
                    }

                    // Build the list tile for each ticket
                    return ListTile(
                      title: Text('Event: $eventId', style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Text(
                          'Level: $levelName\nPurchased: $purchaseDate\nID: $ticketId',
                          style: Theme.of(context).textTheme.bodySmall
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.qr_code_2),
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Show QR Code',
                        onPressed: () {
                          // Call the QR Code dialog function (defined below)
                          _showQrCodeDialog(context, ticketId);
                        },
                      ),
                      dense: true, // Make tile more compact
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close this dialog
              },
            ),
          ],
        );
      },
    );
  }

  // --- Function to show the QR Code Dialog ---
  void _showQrCodeDialog(BuildContext context, String ticketId) {
    // Basic check if ticketId is valid
    if (ticketId.isEmpty || ticketId == 'N/A') {
      _showErrorSnackBar(context, "Invalid Ticket ID for QR Code.");
      return;
    }

    showDialog<void>(
        context: context, // Pass context
        builder: (BuildContext qrDialogContext) {
          return AlertDialog(
            title: const Text('Ticket QR Code'),
            content: SizedBox(
              width: 220, // Give QR code area a size
              height: 220,
              child: Center(
                child: QrImageView( // Use QrImageView
                  data: ticketId, // Data is the unique ticket ID
                  version: QrVersions.auto,
                  size: 200.0, // Size of the QR code itself
                  gapless: false, // Keep gaps for readability
                  errorStateBuilder: (cxt, err) { // Handle QR generation errors
                    print("QR Error: $err"); // Log error
                    return const Center(
                      child: Text(
                        "Uh oh! Error generating QR code.",
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(qrDialogContext).pop(); // Close QR dialog
                },
              ),
            ],
          );
        }
    );
  }


  // Helper to show error snackbars easily
  void _showErrorSnackBar(BuildContext context, String message) {
    // Only show if context is still valid
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        automaticallyImplyLeading: false, // No back button
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.error),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: _UserHomeStyles.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
            children: [
              // --- View Events Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.event_available),
                label: const Text('View Available Events'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onPressed: () => _navigateTo(context, AppRoutes.viewEvents), // Ensure AppRoutes.viewEvents is defined
              ),

              const SizedBox(height: _UserHomeStyles.buttonSpacing),

              // --- View Profile Button ---
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('View Profile Info'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  side: BorderSide(color: theme.colorScheme.secondary),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onPressed: () => _showUserProfileDialog(context),
              ),
              // ---------------------------------

              const SizedBox(height: _UserHomeStyles.buttonSpacing),

              // --- View My Tickets Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.confirmation_num_outlined),
                label: const Text('View My Tickets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onPressed: () => _showMyTicketsDialog(context), // Calls the updated dialog function
              ),
              // -------------------------------------

              const SizedBox(height: _UserHomeStyles.buttonSpacing),

              // --- View Venue Layout Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.location_city), // You can change this icon
                label: const Text('View Venue Layout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VenueLayoutPage()), //
                  );
                },
              ),

              // --- Give Feedback Button ---
              OutlinedButton.icon(
                icon: const Icon(Icons.feedback_outlined),
                label: const Text('Give Feedback'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.tertiary,
                  side: BorderSide(color: theme.colorScheme.tertiary),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                // Ensure AppRoutes.feedback is defined in main.dart
                onPressed: () => _navigateTo(context, AppRoutes.feedback),
              ),
              // -----------------------------------

            ],
          ),
        ),
      ),
    );
  }
}
