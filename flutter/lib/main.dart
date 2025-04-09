import 'package:eventmangment/pages/homePage.dart';
import 'package:flutter/material.dart';
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:eventmangment/modules/feedback.dart';
import 'package:eventmangment/modules/financial.dart';

void main() {
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