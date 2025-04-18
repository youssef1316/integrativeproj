import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmangment/main.dart'; //
// import 'package:eventmangment/pages/viewevents.dart';

// --- Styles Class (Keep as is) ---
class _UserHomeStyles { //
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0); //
  static const double buttonSpacing = 20.0; //
}
// ---------------------------------

class UserHomePage extends StatelessWidget { //
  const UserHomePage({super.key}); //

  // Helper method for navigation
  void _navigateTo(BuildContext context, String routeName) { //
    Navigator.pushNamed(context, routeName); //
  }

  // Logout Function
  Future<void> _logout(BuildContext context) async { //
    try { //
      await FirebaseAuth.instance.signOut(); //
      if (context.mounted) { //
        Navigator.pushNamedAndRemoveUntil( //
          context,
          AppRoutes.login, //
              (Route<dynamic> route) => false, //
        );
      }
    } catch (e) { //
      print("Error during logout: $e"); //
      if (context.mounted) { //
        ScaffoldMessenger.of(context).showSnackBar( //
          SnackBar( //
            content: Text("Logout failed: ${e.toString()}"), //
            backgroundColor: Theme.of(context).colorScheme.error, //
          ),
        );
      }
    }
  }

  void _showUserProfileDialog(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // Should not happen if user is on this screen, but handle anyway
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error: User not logged in."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true, // User can tap outside to close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('User Profile'),
          // Use a FutureBuilder to fetch data when dialog opens
          content: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              // Handle Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 100, // Give it a size while loading
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Handle Error state
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              // Handle No Data / Document doesn't exist
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text('Profile data not found.');
              }

              // --- Data successfully fetched ---
              Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = userData['name'] ?? 'N/A';
              String email = userData['email'] ?? 'N/A';


              return SingleChildScrollView( // In case content overflows
                child: ListBody( // Use ListBody for simple vertical layout
                  children: <Widget>[
                    _buildProfileRow('Name:', name),
                    _buildProfileRow('Email:', email),

                    // Add other fields from your 'users' document here
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
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
  // --- End Added ---


  @override
  Widget build(BuildContext context) { //
    final theme = Theme.of(context); //

    return Scaffold( //
      appBar: AppBar( //
        title: const Text('Home'), //
        centerTitle: true, //
        automaticallyImplyLeading: false, //
        actions: [ //
          IconButton( //
            icon: Icon(Icons.logout, color: theme.colorScheme.error), //
            tooltip: 'Logout', //
            onPressed: () => _logout(context), //
          ),
        ],
      ),
      body: Center( //
        child: Padding( //
          padding: _UserHomeStyles.screenPadding, //
          child: Column( //
            mainAxisSize: MainAxisSize.min, //
            crossAxisAlignment: CrossAxisAlignment.stretch, //
            children: [
              // --- View Events Button ---
              ElevatedButton.icon( //
                icon: const Icon(Icons.event_available), //
                label: const Text('View Available Events'), //
                style: ElevatedButton.styleFrom( //
                  backgroundColor: theme.colorScheme.primary, //
                  foregroundColor: theme.colorScheme.onPrimary, //
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), //
                ),
                onPressed: () => _navigateTo(context, AppRoutes.viewEvents), //
              ),

              const SizedBox(height: _UserHomeStyles.buttonSpacing), //

              // --- ADDED: View Profile Button ---
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('View Profile Info'),
                style: OutlinedButton.styleFrom(
                  // Use theme's outline button style or customize
                  foregroundColor: theme.colorScheme.secondary, // Example color
                  side: BorderSide(color: theme.colorScheme.secondary),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onPressed: () => _showUserProfileDialog(context), // Call the dialog function
              ),
              // ---------------------------------

              const SizedBox(height: _UserHomeStyles.buttonSpacing), //

              // --- Placeholder for "My Tickets" Button --- (Keep commented out)
              // OutlinedButton.icon( ... ), //
              // ----------------------------------------------------
            ],
          ),
        ),
      ),
    );
  }
}