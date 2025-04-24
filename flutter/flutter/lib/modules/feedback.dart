// lib/modules/feedback.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Make sure this import is present

// --- RENAMED Class ---
class FeedbackItem {
  final String id;
  final String eventId;
  final String? eventName;
  final String comment;
  final double rating;
  final String userId;
  final Timestamp? submittedAt;

  FeedbackItem({
    required this.id,
    required this.eventId,
    this.eventName,
    required this.comment,
    required this.rating,
    required this.userId,
    this.submittedAt,
  });

  // Factory constructor to create instance from Firestore data
  factory FeedbackItem.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Extract data based on screenshot fields
    return FeedbackItem(
      id: doc.id, // Use the document ID
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] as String?, // Can be null
      comment: data['feedbackText'] ?? '', // Map from 'feedbackText'
      // Handle rating which might be stored as int or double in Firestore
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      userId: data['userId'] ?? '', // Get the userId
      submittedAt: data['submittedAt'] as Timestamp?, // Get the timestamp
    );
  }
}