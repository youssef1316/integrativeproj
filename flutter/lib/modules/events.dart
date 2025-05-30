import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';

class Events {
  String eventId;
  String name;
  String loc;
  int slotnum;
  List<Artist> artists;
  List<Catering> catering;
  List<Map<String, dynamic>> ticketLevels;
  DateTime? eventDate;
  final double totalRevenue;
  final int totalTicketsSold;

  Events({
    required this.eventId,
    required this.name,
    required this.loc,
    required this.slotnum,
    required this.artists,
    required this.catering,
    required this.ticketLevels,
    this.eventDate,
    required this.totalRevenue,
    required this.totalTicketsSold,
  });

  factory Events.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    List<Artist> parsedArtists = [];
    List<Catering> parsedCatering = [];
    List<Map<String, dynamic>> parsedTicketLevels = List<Map<String, dynamic>>.from(data['ticketLevels'] ?? []);

    return Events(
      eventId: data['eventId'] ?? doc.id,
      name: data['name'] ?? 'Unnamed Event',
      loc: data['loc'] ?? '',
      slotnum: data['slotnum'] ?? 0,
      artists: parsedArtists,
      catering: parsedCatering,
      ticketLevels: parsedTicketLevels,
      eventDate: (data['eventDate'] as Timestamp?)?.toDate(),
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalTicketsSold: (data['totalTicketsSold'] as num?)?.toInt() ?? 0,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'name': name,
      'loc': loc,
      'slotnum': slotnum,
      'ticketLevels': ticketLevels,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'totalRevenue': totalRevenue,
      'totalTicketsSold': totalTicketsSold,
    };
  }
}