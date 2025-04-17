// lib/modules/events.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp if using from/toJson
import 'package:eventmangment/modules/Artists.dart'; // [cite: flutter/lib/modules/events.dart]
import 'package:eventmangment/modules/catering.dart'; // [cite: flutter/lib/modules/events.dart]

class Events { // [cite: flutter/lib/modules/events.dart]
  String eventId; // [cite: flutter/lib/modules/events.dart]
  String name; // [cite: flutter/lib/modules/events.dart]
  String loc; // [cite: flutter/lib/modules/events.dart]
  int slotnum; // [cite: flutter/lib/modules/events.dart]
  List<Artist> artists; // [cite: flutter/lib/modules/events.dart]
  List<Catering> catering; // [cite: flutter/lib/modules/events.dart]
  List<Map<String, dynamic>> ticketLevels;
  // --- ADDED: Event Date field ---
  DateTime? eventDate; // Use DateTime for picker compatibility, convert to Timestamp for Firestore

  Events({ // [cite: flutter/lib/modules/events.dart]
    required this.eventId, // [cite: flutter/lib/modules/events.dart]
    required this.name, // [cite: flutter/lib/modules/events.dart]
    required this.loc, // [cite: flutter/lib/modules/events.dart]
    required this.slotnum, // [cite: flutter/lib/modules/events.dart]
    required this.artists, // [cite: flutter/lib/modules/events.dart]
    required this.catering, // [cite: flutter/lib/modules/events.dart]
    required this.ticketLevels,
    this.eventDate, // Add to constructor (optional here, validated in form)
  }); // [cite: flutter/lib/modules/events.dart]

  // --- (Optional) Update toJson if you use it ---
  Map<String, dynamic> toJson() { // Example if you need serialization
    return {
      'eventId': eventId,
      'name': name,
      'loc': loc,
      'slotnum': slotnum,
      // 'artists': artists.map((a) => a.toJson()).toList(), // Requires toJson in Artist
      // 'catering': catering.map((c) => c.toJson()).toList(), // Requires toJson in Catering
      'ticketLevels': ticketLevels,
      // Convert DateTime to Timestamp for Firestore serialization
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      // 'createdAt': FieldValue.serverTimestamp(), // Add other fields if needed
    };
  }
}