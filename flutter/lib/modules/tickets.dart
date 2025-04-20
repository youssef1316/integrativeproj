import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Ticket {
  // Use final for fields that don't change after creation
  final String ticketId; // Unique ID for this specific ticket (e.g., eventId-Level-001)
  final String eventId;  // ID of the event this ticket belongs to
  final String levelName;// Name of the ticket level (e.g., "Gold", "Regular")
  final double price;    // Price of this ticket level
  final String status;   // e.g., "available", "sold", "checked_in", "cancelled"
  final String? userId;  // UID of the user who bought it (null if available)
  final Timestamp? purchaseTimestamp; // When it was bought (null if available)

  Ticket({
    required this.ticketId,
    required this.eventId,
    required this.levelName,
    required this.price,
    this.status = 'available', // Default status
    this.userId,
    this.purchaseTimestamp,
  });

  // Helper method to convert Ticket object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'eventId': eventId,
      'levelName': levelName,
      'price': price,
      'status': status,
      'userId': userId, // Will be null initially
      'purchaseTimestamp': purchaseTimestamp, // Will be null initially
      // You might add lastUpdated timestamp here too
    };
  }
  factory Ticket.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle potential null data
    return Ticket(
      // Use doc.id if 'ticketId' isn't stored within the document itself
      ticketId: data['ticketId'] ?? doc.id,
      eventId: data['eventId'] ?? '',
      levelName: data['levelName'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0, // Safe conversion
      status: data['status'] ?? 'unknown',
      userId: data['userId'] as String?,
      purchaseTimestamp: data['purchaseTimestamp'] as Timestamp?,
    );
  }
}