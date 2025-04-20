// lib/pages/admin_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for logout
// Make sure these imports point to the correct page files
import 'package:eventmangment/pages/eventcreation.dart';
import 'package:eventmangment/pages/viewevents.dart';
// Import main.dart or your routes file to access AppRoutes constants
import 'package:eventmangment/main.dart'; // Ensure AppRoutes.viewUsers will be defined here

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
    // Changed text color to white for better contrast on colored buttons
    color: Colors.white,
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
  // *** ADDED: Color for the new View Users button ***
  static const Color viewUsersButtonBackground = Colors.green; // Example color
  static const Color logoutButtonBorder = Colors.redAccent; // Color for logout border
}
// --- End Constants ---


// --- RENAMED Widget to AdminHomePage ---
class AdminHomePage extends StatelessWidget {
  // Ensure it has a const constructor
  const AdminHomePage({super.key});

  // Helper method for navigation
  void _navigateTo(BuildContext context, String routeName) {
    // Add basic check if route exists before pushing? Optional.
    // Example: if (AppRoutes.routes.containsKey(routeName)) ...
    Navigator.pushNamed(context, routeName);
  }

  // --- Logout Function ---
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
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
      // Ensure button text uses the updated style with white color
      child: Text(text, style: _AppTextStyles.buttonText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: _AppTextStyles.appBarTitle,
        ),
        backgroundColor: _AppColors.appBarBackground,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Button for Create Event
              _buildStyledButton(
                context: context,
                text: 'Create Event',
                backgroundColor: _AppColors.createButtonBackground,
                // Ensure AppRoutes.createEvent is correctly defined in your routes
                onPressed: () => _navigateTo(context, AppRoutes.createEvent),
              ),
              const SizedBox(height: _AppSpacings.verticalButtonSpacing),

              // Button for View Events
              _buildStyledButton(
                context: context,
                text: 'View All Events',
                backgroundColor: _AppColors.viewButtonBackground,
                // Ensure AppRoutes.viewEvents is correctly defined in your routes
                onPressed: () => _navigateTo(context, AppRoutes.viewEvents),
              ),
              const SizedBox(height: _AppSpacings.verticalButtonSpacing), // Spacing

              // *** ADDED: Button for View Users ***
              _buildStyledButton(
                context: context,
                text: 'View Users', // Button Label
                backgroundColor: _AppColors.viewUsersButtonBackground, // Use new color
                // Ensure AppRoutes.viewUsers is defined in your routes (main.dart)
                onPressed: () => _navigateTo(context, AppRoutes.viewUsers),
              ),
              // ************************************

              const SizedBox(height: _AppSpacings.bottomButtonSpacing), // Spacing before logout
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Logout', style: _AppTextStyles.logoutButtonText),
                style: OutlinedButton.styleFrom(
                  padding: _AppPadding.logoutButtonPadding,
                  side: const BorderSide(color: _AppColors.logoutButtonBorder, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_AppRadius.buttonRadius),
                  ),
                ),
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}