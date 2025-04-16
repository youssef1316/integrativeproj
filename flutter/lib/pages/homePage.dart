import 'package:flutter/material.dart';
import 'package:eventmangment/pages/eventcreation.dart'; // Corrected typo: eventcreation
import 'package:eventmangment/pages/viewevents.dart';

// --- Constants ---
// It's often better to put these in a separate constants.dart file
class _AppSpacings {
  static const double verticalButtonSpacing = 20.0;
}

class _AppPadding {
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 32);
}

class _AppRadius {
  static const double buttonRadius = 12.0;
}

class _AppElevation {
  static const double buttonElevation = 4.0;
}

class _AppTextStyles {
  static const TextStyle buttonText = TextStyle(
    color: Colors.black, // Consider defining app-specific colors
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle appBarTitle = TextStyle(
    color: Colors.black, // Consider defining app-specific colors
  );
}

class _AppColors {
  // Define your app's color palette here for consistency
  static const Color primaryBackground = Colors.white;
  static const Color appBarBackground = Colors.white;
  static const Color createButtonBackground = Colors.red; // Or theme.colorScheme.primary
  static const Color viewButtonBackground = Colors.blue; // Or theme.colorScheme.secondary
}

// --- Route Names (for Named Navigation - Recommended Practice) ---
class AppRoutes {
  static const String createEvent = '/createEvent';
  static const String viewEvents = '/viewEvents';
  // Add other routes here...

  // You would configure these routes in your MaterialApp's `routes` or `onGenerateRoute`
  static Map<String, WidgetBuilder> configureRoutes() {
    return {
      createEvent: (context) => EventCreationPage(),
      viewEvents: (context) => ViewEventsPage(),
      // Add other route builders...
    };
  }
}


// --- HomeScreen Widget ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // Add const constructor and key

  // Helper method for navigation (using named routes)
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  // Helper method or separate widget for styled buttons
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
    // Access theme data if you set it up in MaterialApp
    // final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _AppColors.primaryBackground, // Use constant
      appBar: AppBar(
        title: const Text(
          'Home', // Consider localization for strings
          style: _AppTextStyles.appBarTitle, // Use constant style
        ),
        backgroundColor: _AppColors.appBarBackground, // Use constant
        elevation: 1, // Keep as is or make constant if used elsewhere
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStyledButton(
              context: context,
              text: 'Create Event', // Consider localization
              backgroundColor: _AppColors.createButtonBackground, // Use constant
              onPressed: () => _navigateTo(context, AppRoutes.createEvent),
              // Alternatively, if not using named routes:
              // onPressed: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => EventCreationPage()),
              //   );
              // },
            ),
            const SizedBox(height: _AppSpacings.verticalButtonSpacing), // Use constant
            _buildStyledButton(
              context: context,
              text: 'View Events', // Consider localization
              backgroundColor: _AppColors.viewButtonBackground, // Use constant
              onPressed: () => _navigateTo(context, AppRoutes.viewEvents),
              // Alternatively, if not using named routes:
              // onPressed: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => ViewEventsPage()),
              //   );
              // },
            ),
          ],
        ),
      ),
    );
  }
}