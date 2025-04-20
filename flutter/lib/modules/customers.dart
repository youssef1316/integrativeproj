// modules/customer.dart (or your user model file)
import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id; // Document ID (usually same as userId)
  final String name;
  final String email;

  Customer({
    required this.id,
    required this.name,
    required this.email,
  });

  // Factory constructor to create instance from Firestore data
  factory Customer.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Customer(
      id: doc.id, // Use the document ID from Firestore
      // Ensure 'name' and 'email' match your field names in Firestore
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? '', // Provide default empty string if email is missing
    );
  }
}