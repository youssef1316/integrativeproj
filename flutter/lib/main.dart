import 'package:eventmangment/pages/homePage.dart';
import 'package:flutter/material.dart';
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:eventmangment/modules/feedback.dart';
import 'package:eventmangment/modules/financial.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyD9yydqQa7fF6O1fr69iA-GLdx5-JjINKY",
        authDomain: "eventmangmentsystem-c8674.firebaseapp.com",
        projectId: "eventmangmentsystem-c8674",
        storageBucket: "eventmangmentsystem-c8674.appspot.com",
        messagingSenderId: "376211026978",
        appId: "1:376211026978:web:793872c7099d88ded4867b"
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
      home: HomePage(),
    );
  }
}