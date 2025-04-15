import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ViewEventsPage extends StatelessWidget {
  const ViewEventsPage({super.key}); // Add const constructor

  // --- Helper Method to Build the Event Card ---
  // Keeps the StreamBuilder cleaner without changing the core data logic per card
  Widget _buildEventCard(BuildContext context, DocumentSnapshot doc) {
    final theme = Theme.of(context); // Get theme data for styling
    Map<String, dynamic>? event; // Make nullable

    try {
      // Keep the original data fetching logic
      event = doc.data() as Map<String, dynamic>?; // Allow null check

      // Handle case where data is null or not a map (though Firestore usually prevents this)
      if (event == null) {
        throw Exception("Event data is null or invalid");
      }

      // --- Safely access data with null checks and defaults ---
      // Provides *some* safety without changing the core logic significantly
      final String eventName = event['name'] as String? ?? 'Unnamed Event';
      final String eventId = event['eventId'] as String? ?? doc.id; // Use doc.id as fallback
      final String location = event['loc'] as String? ?? 'No location';
      final int slots = (event['slotnum'] as num?)?.toInt() ?? 0; // Handle potential num/int
      final List<dynamic> artistsRaw = event['artists'] as List<dynamic>? ?? [];
      final List<dynamic> cateringRaw = event['catering'] as List<dynamic>? ?? [];
      // You could add a timestamp field similarly if it exists


      return Card(
        // Use theme defaults or define explicitly
        // elevation: theme.cardTheme.elevation ?? 4,
        // margin: theme.cardTheme.margin ?? const EdgeInsets.symmetric(vertical: 8),
        // shape: theme.cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: Colors.white54,
        margin: const EdgeInsets.symmetric(vertical: 10.0),// Slightly more margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),

        clipBehavior: Clip.antiAlias, // Clip content to rounded shape
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Event Header ---
              Text(
                eventName, // Use safe variable
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary, // Use primary color
                ),
              ),
              if (eventId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    "ID: $eventId",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 12),

              // --- Event Details with Icons ---
              _buildDetailRow(context, Icons.location_on_outlined, location),
              _buildDetailRow(context, Icons.confirmation_number_outlined, "$slots Slots"),

              const Divider(height: 24, thickness: 1),

              // --- Artists Section ---
              _buildSectionTitle(theme, "Artists"),
              if (artistsRaw.isNotEmpty)
                ...artistsRaw.map((artistData) => _buildArtistTile(context, artistData))
              else
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text("No artists listed.", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ),

              const SizedBox(height: 16),

              // --- Catering Section ---
              _buildSectionTitle(theme, "Catering Companies"),
              if (cateringRaw.isNotEmpty)
                ...cateringRaw.map((catData) => _buildCateringTile(context, catData))
              else
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text("No catering companies listed.", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Keep original error handling for this specific document
      print("Error processing document ${doc.id}: $e"); // Log error
      return Card( // Display error stylishly within a Card
        color: Colors.red[50],
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
          title: Text("Invalid event data", style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
          subtitle: Text("Document ID: ${doc.id}\nError: $e", style: TextStyle(color: Colors.red[800])),
        ),
      );
    }
  }

  // Helper for consistent detail rows
  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Increased padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary), // Use secondary color
          const SizedBox(width: 12), // Increased spacing
          Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4), // Improved line height
              )
          ),
        ],
      ),
    );
  }

  // Helper for section titles
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // More space below title
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onBackground.withOpacity(0.8), // Slightly subdued title color
        ),
      ),
    );
  }

  // Helper to build a visually improved tile for an artist
  Widget _buildArtistTile(BuildContext context, dynamic artistData) {
    // Still uses map access, but provides defaults
    final String name = artistData is Map ? artistData['name'] as String? ?? 'N/A' : 'Invalid';
    final String id = artistData is Map ? artistData['artistID'] as String? ?? 'N/A' : 'Invalid';
    final int slot = artistData is Map ? (artistData['slot'] as num?)?.toInt() ?? 0 : 0;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0), // Adjusted padding
      leading: Icon(Icons.person_outline, size: 18, color: Theme.of(context).colorScheme.secondary),
      title: Text("$name (ID: $id)", style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text("Slot: $slot", style: Theme.of(context).textTheme.bodySmall),
      minLeadingWidth: 10, // Reduce space before leading icon
    );
  }

  // Helper to build a visually improved tile for a catering company
  Widget _buildCateringTile(BuildContext context, dynamic catData) {
    // Still uses map access, but provides defaults
    final String name = catData is Map ? catData['CompName'] as String? ?? 'N/A' : 'Invalid';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0),
      leading: Icon(Icons.restaurant_menu_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
      title: Text(name, style: Theme.of(context).textTheme.bodyMedium),
      minLeadingWidth: 10,
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme once

    return Scaffold(
      appBar: AppBar(
        // Use theme styling or keep explicit if preferred
        title: Text(
          'All Events',
          style: TextStyle(color: Colors.black), // Can rely on AppBarTheme
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // Can rely on AppBarTheme
        iconTheme: IconThemeData(color: Colors.black), // Can rely on AppBarTheme
      ),
      backgroundColor: Colors.white, // Can rely on Scaffold background Theme
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          // --- Enhanced Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Column( // Added text for clarity
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Loading events...")
                  ],
                ));
          }
          // --- Enhanced Error State ---
          if (snapshot.hasError) {
            print("StreamBuilder Error: ${snapshot.error}"); // Log the error
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column( // Added icon and more details
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "Error Fetching Events",
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Could not load events. Please check your connection or try again later.", // More user-friendly message
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          // --- Enhanced Empty State ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Column( // Added icon
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_outlined, color: Colors.grey, size: 50),
                    SizedBox(height: 10),
                    Text("No events found."),
                  ],
                ));
          }

          // --- Build List View ---
          // Keep original ListView logic, but call the helper method
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjusted padding
            children: snapshot.data!.docs.map((doc) {
              // Call the helper method to build each card
              return _buildEventCard(context, doc);
            }).toList(),
          );
        },
      ),
    );
  }
}