import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for logout
// Make sure these imports point to the correct page files
import 'package:eventmangment/pages/eventcreation.dart';
import 'package:eventmangment/pages/viewevents.dart';
// Import main.dart or your routes file to access AppRoutes constants
import 'package:eventmangment/main.dart';

// --- Constants (Copied from original HomeScreen - Keep or Centralize) ---
class _AppSpacings {
  static const double verticalButtonSpacing = 20.0;
  static const double bottomButtonSpacing = 40.0; // Added spacing before logout
}

class _AppPadding {
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 32);
  static const EdgeInsets logoutButtonPadding = EdgeInsets.symmetric(vertical: 10, horizontal: 28);
}

class _AppRadius {
  static const double buttonRadius = 12.0;
}

class _AppElevation {
  static const double buttonElevation = 4.0;
}

class _AppTextStyles {
  static const TextStyle buttonText = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle appBarTitle = TextStyle(
    color: Colors.black,
  );
  static const TextStyle logoutButtonText = TextStyle( // Style for logout button
    color: Colors.redAccent,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}

class _AppColors {
  static const Color primaryBackground = Colors.white;
  static const Color appBarBackground = Colors.white;
  static const Color createButtonBackground = Colors.red;
  static const Color viewButtonBackground = Colors.blue;
  static const Color logoutButtonBorder = Colors.redAccent; // Color for logout border
}
// --- End Constants ---


// --- RENAMED Widget to AdminHomePage ---
class AdminHomePage extends StatelessWidget {
  // Ensure it has a const constructor
  const AdminHomePage({super.key});

  // Helper method for navigation
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  // --- Logout Function ---
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to Login screen and remove all previous routes
      // so the user cannot press 'back' to get into the admin area.
      if (context.mounted) { // Check if the widget is still mounted
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login, // Navigate to the login route
              (Route<dynamic> route) => false, // Remove all routes behind it
        );
      }
    } catch (e) {
      print("Error during logout: $e");
      // Optionally show a SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // Helper method for the main action buttons
  Widget _buildStyledButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String text,
    required Color backgroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: _AppPadding.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_AppRadius.buttonRadius),
        ),
        elevation: _AppElevation.buttonElevation,
      ),
      child: Text(text, style: _AppTextStyles.buttonText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.primaryBackground,
      appBar: AppBar(
        // --- Changed AppBar Title ---
        title: const Text(
          'Admin Dashboard', // Appropriate title
          style: _AppTextStyles.appBarTitle,
        ),
        backgroundColor: _AppColors.appBarBackground,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back button on AppBar
      ),
      body: Center(
        child: Padding( // Added padding around the column for better spacing
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Keep content centered vertically
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally
            children: [
              // Button for Create Event
              _buildStyledButton(
                context: context,
                text: 'Create Event',
                backgroundColor: _AppColors.createButtonBackground,
                onPressed: () => _navigateTo(context, AppRoutes.createEvent),
              ),
              const SizedBox(height: _AppSpacings.verticalButtonSpacing),

              // Button for View Events
              _buildStyledButton(
                context: context,
                text: 'View All Events', // Changed text slightly
                backgroundColor: _AppColors.viewButtonBackground,
                onPressed: () => _navigateTo(context, AppRoutes.viewEvents),
              ),

              // --- Added Spacing and Logout Button ---
              const SizedBox(height: _AppSpacings.bottomButtonSpacing), // More space before logout
              OutlinedButton.icon( // Using OutlinedButton for visual difference
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Logout', style: _AppTextStyles.logoutButtonText),
                style: OutlinedButton.styleFrom(
                  padding: _AppPadding.logoutButtonPadding,
                  side: const BorderSide(color: _AppColors.logoutButtonBorder, width: 1.5), // Red border
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_AppRadius.buttonRadius),
                  ),
                ),
                onPressed: () => _logout(context), // Call the logout function
              ),
              // --------------------------------------
            ],
          ),
        ),
      ),
    );
  }
}