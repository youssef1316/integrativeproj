import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

// --- Page Imports ---
import 'package:eventmangment/pages/login.dart';             // Correct: Contains LoginScreen
import 'package:eventmangment/pages/sign_up.dart';          // Contains SignUpScreen
import 'package:eventmangment/pages/user_home.dart';         // Contains UserHomePage
import 'package:eventmangment/pages/admin_home.dart';        // Contains AdminHomePage
import 'package:eventmangment/pages/eventcreation.dart'; // Should provide EventCreationPage
import 'package:eventmangment/pages/viewevents.dart';    // Should provide ViewEventsPage   // Contains ViewEventsPage
import 'package:eventmangment/pages/payment_screen.dart';

// --- Module Imports (Keep if needed by pages) ---
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:eventmangment/modules/feedback.dart';
import 'package:eventmangment/modules/financial.dart';


// --- Define All Application Routes ---
class AppRoutes {
  // Core Navigation
  static const String login = '/login';       // Route for LoginScreen in login.dart
  static const String signUp = '/sign_up';    // Route for SignUpScreen in sign_up.dart
  static const String userHome = '/user_home';  // Route for UserHomePage
  static const String adminHome = '/admin_home'; // Route for AdminHomePage

  // Other Necessary Routes (Keep if still used from within User/Admin areas)
  static const String createEvent = '/createEvent';
  static const String viewEvents = '/viewEvents';
  static const String payment = '/payment_screen';


  // --- Configure ALL necessary routes ---
  static Map<String, WidgetBuilder> configureRoutes() {
    return {
      login: (context) => LoginScreen(),
      signUp: (context) => SignUpScreen(),
      userHome: (context) => const UserHomePage(),
      adminHome: (context) => const AdminHomePage(),
      createEvent: (context) => EventCreationPage(),
      viewEvents: (context) => const ViewEventsPage(),
      payment: (context) => const PaymentScreen(),
    };
  }
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyD9yydqQa7fF6O1fr69iA-GLdx5-JjINKY", // Replace with secure loading method
        authDomain: "eventmangmentsystem-c8674.firebaseapp.com",
        projectId: "eventmangmentsystem-c8674",
        storageBucket: "eventmangmentsystem-c8674.appspot.com",
        messagingSenderId: "376211026978",
        appId: "eventmangmentsystem-c8674" // Replace with secure loading method if different
    ),
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No changes needed inside the MyApp build method itself for this request.
    // It already correctly uses initialRoute and routes.
    return MaterialApp(
      title: 'Event Management App',
      debugShowCheckedModeBanner: false,

      // Theme Data (Copied from your code)
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

      // --- Initial Route ---
      // This correctly starts the app at the '/login' route,
      // which maps to LoginScreen from login.dart via configureRoutes.
      initialRoute: AppRoutes.login,

      // --- Routes Configuration ---
      // This uses the updated configureRoutes method which no longer includes '/'.
      routes: AppRoutes.configureRoutes(),

    );
  }
}