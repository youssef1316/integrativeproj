// lib/pages/feedback_screen.dart
import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Give Feedback")),
      body: const Center(child: Text("Feedback form will go here.")),
    );
  }
}