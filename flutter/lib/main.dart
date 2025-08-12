import 'package:eventmangment/pages/homePage.dart';
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:eventmangment/modules/feedback.dart';
import 'package:eventmangment/modules/financial.dart';

void main() {
=======
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
import 'package:eventmangment/pages/reports.dart';
import 'package:eventmangment/pages/otp.dart';
import 'package:eventmangment/pages/discountcreation.dart';
import 'package:eventmangment/pages/viewdiscounts.dart';
import 'package:eventmangment/onlinestatus.dart';

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
  static const String Reports = '/reports';
  static const String createDiscount = '/createDiscount';
  static const String viewDiscounts = '/viewDiscounts';


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
      createDiscount: (context) => const CreateDiscountPage(),
      viewDiscounts: (context) => const DiscountListPage(),
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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true,);
  await OnlineStatus.instance.init();
>>>>>>> Stashed changes
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
<<<<<<< Updated upstream
      home: HomePage(),
=======
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

      //banner that shows up when offline
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            ValueListenableBuilder<bool>(
              valueListenable: OnlineStatus.instance.isOnline,
              builder: (_, online, __) {
                if (online) return const SizedBox.shrink();
                return Positioned(
                  left: 0, right: 0, top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: const Color(0xFFB00020), // red-ish
                    child: const SafeArea(
                      bottom: false,
                      child: Text(
                        'You’re offline. Some actions are disabled.',
                        style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
>>>>>>> Stashed changes
    );
  }
}