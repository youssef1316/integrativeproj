// --- Make sure this import points to the actual file containing EventCreationPage ---
import 'package:eventmangment/pages/eventcreation.dart';
// --- Add the import for your ViewEventsPage ---
import 'package:eventmangment/pages/viewevents.dart'; // <--- ADD THIS IMPORT (Adjust path if needed)
// --- Make sure this import points to the actual file containing HomeScreen ---
import 'package:eventmangment/pages/homepage.dart'; // Assuming HomeScreen is in homepage.dart

import 'package:flutter/material.dart';
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:eventmangment/modules/feedback.dart';
import 'package:eventmangment/modules/financial.dart';
import 'package:firebase_core/firebase_core.dart';

// --- Define AppRoutes here or import from another file ---
class AppRoutes {
  static const String home = '/';
  static const String createEvent = '/createEvent';
  static const String viewEvents = '/viewEvents';

  // --- Ensure the widget names match your actual page classes ---
  static Map<String, WidgetBuilder> configureRoutes() {
    return {
      home: (context) => const HomeScreen(), // Assuming HomeScreen is const constructible
      createEvent: (context) => EventCreationPage(), // Assuming EventCreationPage is const constructible
      viewEvents: (context) => ViewEventsPage(),   // Assuming ViewEventsPage is const constructible
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyD9yydqQa7fF6O1fr69iA-GLdx5-JjINKY", // Replace with env variable or config loading
        authDomain: "eventmangmentsystem-c8674.firebaseapp.com",
        projectId: "eventmangmentsystem-c8674",
        storageBucket: "eventmangmentsystem-c8674.appspot.com",
        messagingSenderId: "376211026978",
        appId: "YOUR_APP_ID" // Replace with env variable or config loading
    ),
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // --- Replace 'home' with 'initialRoute' and 'routes' ---
      // home: HomeScreen(), // Remove this line

      initialRoute: AppRoutes.home, // Set the starting route
      routes: AppRoutes.configureRoutes(), // Provide the map of named routes

      // --- Optional: Theme Data ---
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      //   // Add other theme configurations
      // ),
    );
  }
}