import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Page Imports ---
import 'package:eventmangment/pages/login.dart';
import 'package:eventmangment/pages/sign_up.dart';
import 'package:eventmangment/pages/user_home.dart';
import 'package:eventmangment/pages/admin_home.dart';
import 'package:eventmangment/pages/eventcreation.dart';
import 'package:eventmangment/pages/viewevents.dart';
import 'package:eventmangment/pages/payment_screen.dart';
import 'package:eventmangment/pages/feedback.dart';
import 'package:eventmangment/pages/viewusers.dart';
import 'package:eventmangment/pages/reports.dart'; // Import ReportsScreen

// --- Module Imports (Keep if needed by pages) ---
// ... (your module imports)


// --- Define All Application Routes ---
class AppRoutes {
  // Core Navigation
  static const String login = '/login';
  static const String signUp = '/sign_up';
  static const String userHome = '/user_home';
  static const String adminHome = '/admin_home';
  static const String createEvent = '/createEvent';
  static const String viewEvents = '/viewEvents';
  static const String payment = '/payment_screen';
  static const String feedback = '/feedback';
  static const String viewUsers = '/viewUsers';
  static const String Reports = '/reports'; // Keep the route name


  // --- Configure routes WITHOUT Reports ---
  static Map<String, WidgetBuilder> configureRoutes() {
    return {
      login: (context) => LoginScreen(),
      signUp: (context) => SignUpScreen(),
      userHome: (context) => const UserHomePage(),
      adminHome: (context) => const AdminHomePage(),
      createEvent: (context) => EventCreationPage(),
      viewEvents: (context) => const ViewEventsPage(),
      payment: (context) => const PaymentScreen(),
      feedback: (context) => const FeedbackScreen(),
      viewUsers: (context) => const ViewUsers(),
      // Remove the Reports route from here
      // Reports: (context) => const ReportsScreen(eventId: selectedEventId), // REMOVED
    };
  }

  // --- NEW: Function to handle route generation with arguments ---
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Reports: // Check if the route name matches AppRoutes.Reports
      // Extract arguments safely
        final args = settings.arguments;
        if (args is String) { // Check if the argument is the expected type (String for eventId)
          return MaterialPageRoute(
            builder: (context) => ReportsScreen(eventId: args), // Pass the eventId
          );
        }
        // If arguments are not a String or are null, return an error route
        return _errorRoute("Invalid arguments for Reports route: Expected String eventId");

    // Add cases for other routes that might need arguments

      default:
      // If the route name doesn't match any case handled by onGenerateRoute,
      // it might be handled by the 'routes' map or it's an unknown route.
      // You can return null to let 'routes' handle it, or return an error route.
      // Let the routes map handle known routes without arguments
        if (configureRoutes().containsKey(settings.name)) {
          // This allows routes defined in configureRoutes() to still work
          return null; // Let MaterialApp's 'routes' handle this
        }
        // Otherwise, it's an unknown route
        return _errorRoute("Unknown route: ${settings.name}");
    }
  }

  // --- Helper function for error route ---
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('ROUTE ERROR: $message')),
      );
    });
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANT: Load Firebase options securely, e.g., using flutterfire_cli
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Recommended way
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyD9yydqQa7fF6O1fr69iA-GLdx5-JjINKY", // Replace with secure loading method
        authDomain: "eventmangmentsystem-c8674.firebaseapp.com",
        projectId: "eventmangmentsystem-c8674",
        storageBucket: "eventmangmentsystem-c8674.appspot.com",
        messagingSenderId: "376211026978",
        appId: "eventmangmentsystem-c8674"
    ),
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              )
          )
      ),
      initialRoute: AppRoutes.login,

      // --- Use routes AND onGenerateRoute ---
      routes: AppRoutes.configureRoutes(),   // Handles routes WITHOUT arguments
      onGenerateRoute: AppRoutes.generateRoute, // Handles routes WITH arguments (like Reports)

    );
  }
}