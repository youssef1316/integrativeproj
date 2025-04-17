import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventmangment/main.dart';
import 'package:eventmangment/pages/viewevents.dart';

// You might want central constants, but defining some locally for clarity if needed
class _UserHomeStyles {
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const double buttonSpacing = 20.0;
}

class UserHomePage extends StatelessWidget {
  // Add const constructor - this should fix the error in main.dart
  const UserHomePage({super.key});

  // Helper method for navigation
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  // Logout Function (Same as in AdminHomePage)
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to Login screen and remove all previous routes
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login, // Navigate to the login route
              (Route<dynamic> route) => false, // Remove all routes behind it
        );
      }
    } catch (e) {
      print("Error during logout: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error, // Use theme error color
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      // Use theme background color if defined, otherwise default
      // backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Home'), // Simple title for user home
        centerTitle: true,
        automaticallyImplyLeading: false, // No back button on home screen
        // Use theme's AppBar style or define explicitly
        // backgroundColor: theme.appBarTheme.backgroundColor,
        // titleTextStyle: theme.appBarTheme.titleTextStyle,
        actions: [
          // Logout Button in AppBar
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.error), // Use theme error color
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: _UserHomeStyles.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Center content vertically
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch button
            children: [
              // --- View Events Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.event_available),
                label: const Text('View Available Events'),
                // Style using ElevatedButtonTheme from main.dart or define here
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary, // Use theme primary color
                  foregroundColor: theme.colorScheme.onPrimary, // Use theme text color for button
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  // Padding/Shape likely comes from theme, but can override:
                  // padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _navigateTo(context, AppRoutes.viewEvents),
              ),

              const SizedBox(height: _UserHomeStyles.buttonSpacing),

              // --- Placeholder for future "My Tickets" Button ---
              // OutlinedButton.icon(
              //   icon: const Icon(Icons.confirmation_num_outlined),
              //   label: const Text('My Tickets'),
              //   onPressed: () {
              //     // TODO: Navigate to My Tickets screen
              //     print("Navigate to My Tickets (Not Implemented)");
              //   },
              // ),
              // ----------------------------------------------------
            ],
          ),
        ),
      ),
    );
  }
}