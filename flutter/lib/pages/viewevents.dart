// lib/pages/viewevents.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //
import 'package:eventmangment/main.dart'; // For AppRoutes
import 'package:intl/intl.dart';


// Import the Ticket model if needed for type safety (optional here)
// import 'package:eventmangment/modules/tickets.dart';

class ViewEventsPage extends StatelessWidget { //
  const ViewEventsPage({super.key}); //

  // --- Helper Method to Build the Event Card ---
  // Returns the StatefulWidget version of the card
  Widget _buildEventCard(BuildContext context, DocumentSnapshot doc) { //
    // Pass the document snapshot to the stateful card widget
    return _EventCard(doc: doc);
  }

  // --- Helper for consistent detail rows within Card ---
  Widget _buildDetailRow(BuildContext context, IconData icon, String text) { //
    return Padding( //
      padding: const EdgeInsets.symmetric(vertical: 4.0), //
      child: Row( //
        crossAxisAlignment: CrossAxisAlignment.start, //
        children: [ //
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary), //
          const SizedBox(width: 12), //
          Expanded( //
              child: Text( //
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4), //
              )
          ),
        ],
      ),
    );
  }

  // --- Helper for section titles within Card ---
  Widget _buildSectionTitle(ThemeData theme, String title) { //
    return Padding( //
      padding: const EdgeInsets.only(bottom: 6.0), //
      child: Text( //
        title,
        style: theme.textTheme.titleMedium?.copyWith( //
          fontWeight: FontWeight.w600, //
          color: theme.colorScheme.onBackground.withOpacity(0.8), //
        ),
      ),
    );
  }

  // --- Helper to build a tile for an artist within Card ---
  Widget _buildArtistTile(BuildContext context, dynamic artistData) { //
    // Still uses map access, but provides defaults
    final String name = artistData is Map ? artistData['name'] as String? ?? 'N/A' : 'Invalid'; //
    final String id = artistData is Map ? artistData['artistID'] as String? ?? 'N/A' : 'Invalid'; //
    final int slot = artistData is Map ? (artistData['slot'] as num?)?.toInt() ?? 0 : 0; //

    return ListTile( //
      dense: true, //
      contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0), //
      leading: Icon(Icons.person_outline, size: 18, color: Theme.of(context).colorScheme.secondary), //
      title: Text("$name (ID: $id)", style: Theme.of(context).textTheme.bodyMedium), //
      subtitle: Text("Slot: $slot", style: Theme.of(context).textTheme.bodySmall), //
      minLeadingWidth: 10, //
    );
  }

  // --- Helper to build a tile for a catering company within Card ---
  Widget _buildCateringTile(BuildContext context, dynamic catData) { //
    // Still uses map access, but provides defaults
    final String name = catData is Map ? catData['CompName'] as String? ?? 'N/A' : 'Invalid'; //

    return ListTile( //
      dense: true, //
      contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0), //
      leading: Icon(Icons.restaurant_menu_outlined, size: 18, color: Theme.of(context).colorScheme.secondary), //
      title: Text(name, style: Theme.of(context).textTheme.bodyMedium), //
      minLeadingWidth: 10, //
    );
  }


  @override
  Widget build(BuildContext context) { //
    final theme = Theme.of(context); //

    return Scaffold( //
      appBar: AppBar( //
        title: const Text( // Use const
          'All Events',
          style: TextStyle(color: Colors.black), //
        ),
        centerTitle: true, //
        backgroundColor: Colors.white, //
        iconTheme: const IconThemeData(color: Colors.black), // Use const
      ),
      backgroundColor: Colors.white, //
      body: StreamBuilder<QuerySnapshot>( //
        stream: FirebaseFirestore.instance.collection('events')
            .orderBy('createdAt', descending: true) // Example order
            .snapshots(), //
        builder: (context, snapshot) { //
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) { //
            return const Center( //
                child: Column( //
                  mainAxisAlignment: MainAxisAlignment.center, //
                  children: [ //
                    CircularProgressIndicator(), //
                    SizedBox(height: 10), //
                    Text("Loading events...") //
                  ],
                ));
          }
          // --- Error State ---
          if (snapshot.hasError) { //
            print("StreamBuilder Error: ${snapshot.error}"); //
            return Center( //
              child: Padding( //
                padding: const EdgeInsets.all(20.0), //
                child: Column( //
                  mainAxisAlignment: MainAxisAlignment.center, //
                  children: [ //
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50), //
                    const SizedBox(height: 10), //
                    Text( //
                      "Error Fetching Events",
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error), //
                      textAlign: TextAlign.center, //
                    ),
                    const SizedBox(height: 5), //
                    Text( //
                      "Could not load events. Please check your connection or try again later.", //
                      textAlign: TextAlign.center, //
                      style: theme.textTheme.bodyMedium, //
                    ),
                  ],
                ),
              ),
            );
          }
          // --- Empty State ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { //
            return const Center( //
                child: Column( //
                  mainAxisAlignment: MainAxisAlignment.center, //
                  children: [ //
                    Icon(Icons.event_busy_outlined, color: Colors.grey, size: 50), //
                    SizedBox(height: 10), //
                    Text("No events found."), //
                  ],
                ));
          }

          // --- Build List View ---
          final eventDocs = snapshot.data!.docs; // Get docs list once
          return ListView.builder( // Use ListView.builder for efficiency
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), //
            itemCount: eventDocs.length, // Set item count
            itemBuilder: (context, index) { // Build each item
              final doc = eventDocs[index];
              // Use the helper which returns the stateful _EventCard
              return _buildEventCard(context, doc); //
            },
          );
        },
      ),
    );
  }
}


// ##################################################################
// #                  Stateful Event Card Widget                    #
// ##################################################################
class _EventCard extends StatefulWidget {
  final DocumentSnapshot doc; // Pass the document snapshot

  const _EventCard({required this.doc});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  Map<String, dynamic>? eventData;
  String eventId = '';
  bool _isCardInvalid = false; // Flag for data structure errors

  @override
  void initState() {
    super.initState();
    // Extract data once and handle potential casting errors
    try {
      if (widget.doc.data() == null) {
        throw Exception("Document data is null");
      }
      eventData = widget.doc.data() as Map<String, dynamic>; // Direct cast
      eventId = eventData!['eventId'] as String? ?? widget.doc.id; // Use null-aware after cast
    } catch (e) {
      print("Error casting event data in card: ${widget.doc.id}, $e");
      eventData = null; // Ensure eventData is null on error
      _isCardInvalid = true; // Set flag to show error card
    }
  }

  // --- Function to show the Ticket Selection Dialog ---
  void _showTicketSelectionDialog(BuildContext context) {
    // Check if event data is valid before proceeding
    if (_isCardInvalid || eventData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot select tickets: Event data is invalid."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Safely extract ticket levels definition
    final List<dynamic> ticketLevelsRaw = eventData!['ticketLevels'] as List<dynamic>? ?? [];
    // Convert raw list, filtering out any non-map items and ensuring type safety
    final List<Map<String, dynamic>> ticketLevels = List<Map<String, dynamic>>.from(
        ticketLevelsRaw.whereType<Map>().map((item) => Map<String, dynamic>.from(item))
    );

    // Check if there are any valid ticket levels defined
    if (ticketLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No ticket levels defined for this event."), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    // Show the actual dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must explicitly Cancel or Proceed
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Select Tickets for ${eventData!['name'] ?? 'Event'}'),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0), // Adjust padding
          // Use the dedicated stateful widget for the dialog's main content
          content: _TicketSelectionDialogContent(
            eventId: eventId,
            ticketLevels: ticketLevels,
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            // The 'Proceed to Payment' button is INSIDE _TicketSelectionDialogContent
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- Build Error Card if data was invalid during initState ---
    if (_isCardInvalid) {
      return Card( //
        color: Colors.red[50], //
        margin: const EdgeInsets.symmetric(vertical: 8), //
        child: ListTile( //
          leading: Icon(Icons.warning_amber_rounded, color: Colors.red[700]), //
          title: Text("Invalid event data structure", style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)), //
          subtitle: Text("Document ID: ${widget.doc.id}", style: TextStyle(color: Colors.red[800])), //
        ),
      );
    }

    // --- Build Normal Event Card (Data is assumed valid here) ---
    // Access data using null-aware operators as a fallback
    final String eventName = eventData?['name'] as String? ?? 'Unnamed Event'; //
    // eventId is set in initState
    final String location = eventData?['loc'] as String? ?? 'No location'; //
    final int slots = (eventData?['slotnum'] as num?)?.toInt() ?? 0; //
    final List<dynamic> artistsRaw = eventData?['artists'] as List<dynamic>? ?? []; //
    final List<dynamic> cateringRaw = eventData?['catering'] as List<dynamic>? ?? []; //
    final Timestamp? eventDateRaw = eventData?['eventDate'] as Timestamp?; // Extract date if present

    return Card( //
      elevation: 4, //
      color: Colors.white, // Explicitly white //
      margin: const EdgeInsets.symmetric(vertical: 10.0), //
      shape: RoundedRectangleBorder( //
        borderRadius: BorderRadius.circular(15.0), //
      ),
      clipBehavior: Clip.antiAlias, //
      child: Padding( //
        padding: const EdgeInsets.all(16.0), //
        child: Column( //
          crossAxisAlignment: CrossAxisAlignment.start, //
          children: [
            // --- Event Header ---
            Text( //
              eventName, //
              style: theme.textTheme.titleLarge?.copyWith( //
                fontWeight: FontWeight.bold, //
                color: theme.colorScheme.primary, //
              ),
            ),
            if (eventId.isNotEmpty) //
              Padding( //
                padding: const EdgeInsets.only(top: 2.0), //
                child: Text( //
                  "ID: $eventId", //
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]), //
                ),
              ),
            const SizedBox(height: 12), //

            // --- Event Details with Icons ---
            ViewEventsPage()._buildDetailRow(context, Icons.location_on_outlined, location), //
            // Display Date if available
            if (eventDateRaw != null)
              ViewEventsPage()._buildDetailRow(
                  context,
                  Icons.calendar_today_outlined,
                  DateFormat('EEE, MMM d, yyyy').format(eventDateRaw.toDate()) // Format the date nicely
              ),
            ViewEventsPage()._buildDetailRow(context, Icons.confirmation_number_outlined, "$slots Tickets"), //


            const Divider(height: 24, thickness: 1), //

            // --- Artists Section ---
            ViewEventsPage()._buildSectionTitle(theme, "Artists"), //
            if (artistsRaw.isNotEmpty) //
              ...artistsRaw.map((artistData) => ViewEventsPage()._buildArtistTile(context, artistData)) //
            else
              const Padding( //
                padding: EdgeInsets.only(left: 8.0, top: 4.0), //
                child: Text("No artists listed.", style: TextStyle(fontStyle: FontStyle.italic)), //
              ),

            const SizedBox(height: 16), //

            // --- Catering Section ---
            ViewEventsPage()._buildSectionTitle(theme, "Catering Companies"), //
            if (cateringRaw.isNotEmpty) //
              ...cateringRaw.map((catData) => ViewEventsPage()._buildCateringTile(context, catData)) //
            else
              const Padding( //
                padding: EdgeInsets.only(left: 8.0, top: 4.0), //
                child: Text("No catering companies listed.", style: TextStyle(fontStyle: FontStyle.italic)), //
              ),

            const SizedBox(height: 20), // Space before button //

            // --- Buy Tickets Button ---
            Center( //
              child: ElevatedButton.icon( //
                icon: const Icon(Icons.shopping_cart_checkout), //
                label: const Text("Buy Tickets"), //
                style: ElevatedButton.styleFrom( //
                  backgroundColor: theme.colorScheme.secondary, // Use secondary color //
                  foregroundColor: theme.colorScheme.onSecondary, //
                ),
                onPressed: () => _showTicketSelectionDialog(context), // Trigger dialog
              ),
            ),
            // ------------------------------
          ],
        ),
      ),
    );
  }
}

// selecting desired tickets

class _TicketSelectionDialogContent extends StatefulWidget {
  final String eventId;
  final List<Map<String, dynamic>> ticketLevels; // Definitions passed from event doc

  const _TicketSelectionDialogContent({
    required this.eventId,
    required this.ticketLevels,
  });

  @override
  State<_TicketSelectionDialogContent> createState() => _TicketSelectionDialogContentState();
}

class _TicketSelectionDialogContentState extends State<_TicketSelectionDialogContent> {
  // State for selected quantities, keyed by levelName
  Map<String, int> _selectedQuantities = {};
  // State for available counts, keyed by levelName
  Map<String, int> _availableCounts = {};
  // State for loading availability, keyed by levelName
  Map<String, bool> _isLoadingAvailability = {};
  // State for overall processing/proceeding
  bool _isProcessing = false;
  // State for displaying error messages
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize state maps based on the passed ticket levels
    for (var level in widget.ticketLevels) {
      // Use a unique but predictable key if levelName is missing (shouldn't happen ideally)
      final levelName = level['levelName'] as String? ?? 'UnknownLevel_${level.hashCode}';
      _selectedQuantities[levelName] = 0; // Start with 0 selected
      _isLoadingAvailability[levelName] = true; // Mark as loading initially
      _availableCounts[levelName] = 0; // Assume 0 available until fetched
    }
    // Fetch initial availability counts asynchronously
    _fetchAvailabilityCounts();
  }

  /// Fetches the current count of available tickets for each level from Firestore.
  Future<void> _fetchAvailabilityCounts({bool showSnackBarOnError = false}) async {
    if (!mounted) return; // Don't proceed if widget is disposed

    // Set loading state for all levels being fetched again
    setState(() {
      _errorMessage = null; // Clear previous errors
      widget.ticketLevels.forEach((level) {
        final levelName = level['levelName'] as String? ?? 'UnknownLevel_${level.hashCode}';
        _isLoadingAvailability[levelName] = true;
      });
    });

    try {
      final firestore = FirebaseFirestore.instance;
      Map<String, int> updatedCounts = {};
      Map<String, bool> updatedLoading = Map.from(_isLoadingAvailability);

      // Create a list of Futures to fetch counts in parallel
      List<Future<void>> fetchFutures = [];

      for (var level in widget.ticketLevels) {
        final levelName = level['levelName'] as String? ?? 'UnknownLevel_${level.hashCode}';
        if (levelName.startsWith('UnknownLevel')) continue; // Skip levels without a valid name

        final query = firestore
            .collection('tickets')
            .where('eventId', isEqualTo: widget.eventId)
            .where('levelName', isEqualTo: levelName)
            .where('status', isEqualTo: 'available');

        // Add the future for fetching the count to the list
        fetchFutures.add(
            query.count().get().then((countSnapshot) {
              if (mounted) { // Check mounted again inside async callback
                updatedCounts[levelName] = countSnapshot.count ?? 0;
                updatedLoading[levelName] = false;
              }
            }).catchError((error) {
              print("Error fetching count for $levelName: $error");
              if(mounted){
                updatedLoading[levelName] = false; // Stop loading even on error for this level
              }
            })
        );
      }

      // Wait for all count fetches to complete
      await Future.wait(fetchFutures);

      // Update state once after all fetches are done (or attempted)
      if(mounted){
        setState(() {
          _availableCounts = updatedCounts;
          _isLoadingAvailability = updatedLoading;
          // If any updatedLoading entry is still true here, it means an error occurred for it.
          bool anyLoadingError = updatedLoading.values.any((isLoading) => isLoading);
          if(anyLoadingError && _errorMessage == null){
            _errorMessage = "Could not verify availability for all levels.";
          }
        });
      }

    } catch (e) {
      // Catch broader errors (e.g., network issues)
      print("Error fetching availability counts: $e");
      if(mounted) {
        setState(() {
          _isLoadingAvailability.updateAll((key, value) => false); // Stop all loading indicators
          _errorMessage = "Could not fetch ticket availability.";
        });
        // Show error in SnackBar only if triggered by user action (refresh/proceed)
        if(showSnackBarOnError && context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.orangeAccent,
          ));
        }
      }
    }
  }

  /// Performs a final check on availability before navigating to payment.
  Future<bool> _checkFinalAvailability() async {
    // Refresh counts just before confirming
    await _fetchAvailabilityCounts(showSnackBarOnError: true);
    // If fetching failed or widget disposed, availability is not confirmed
    if (_errorMessage != null || !mounted) return false;

    bool allSufficient = true;
    String? firstErrorMsg;

    _selectedQuantities.forEach((levelName, selectedQuantity) {
      if (selectedQuantity > 0) { // Only check levels user wants to buy
        int actuallyAvailable = _availableCounts[levelName] ?? 0;
        if (selectedQuantity > actuallyAvailable) {
          allSufficient = false;
          // Provide a more specific error message
          firstErrorMsg ??= "Only $actuallyAvailable ticket(s) left for '$levelName'. Please reduce quantity.";
        }
      }
    });

    // If not all quantities are available, update the error message on screen
    if (!allSufficient && mounted) {
      setState(() {
        _errorMessage = firstErrorMsg;
      });
    }
    return allSufficient;
  }

  /// Increases the selected quantity for a given ticket level.
  void _incrementQuantity(String levelName) {
    int currentCount = _selectedQuantities[levelName] ?? 0;
    int maxAvailable = _availableCounts[levelName] ?? 0;
    // Prevent incrementing beyond available count
    if (currentCount < maxAvailable) {
      setState(() {
        _selectedQuantities[levelName] = currentCount + 1;
        _errorMessage = null; // Clear potential previous errors
      });
    } else {
      // Provide feedback that no more tickets are available for this level
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No more "$levelName" tickets available.'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  /// Decreases the selected quantity for a given ticket level.
  void _decrementQuantity(String levelName) {
    int currentCount = _selectedQuantities[levelName] ?? 0;
    if (currentCount > 0) {
      setState(() {
        _selectedQuantities[levelName] = currentCount - 1;
        _errorMessage = null; // Clear potential previous errors
      });
    }
  }

  /// Validates selection, re-checks availability, and navigates to payment.
  void _proceedToPayment() async {
    // Check if at least one ticket is selected
    final totalSelected = _selectedQuantities.values.fold(0, (sum, item) => sum + item);
    if (totalSelected <= 0){
      setState(() { _errorMessage = "Please select at least one ticket."; });
      return;
    }

    // Set processing state and clear errors
    setState(() { _isProcessing = true; _errorMessage = null; });

    // Perform final availability check
    bool available = await _checkFinalAvailability();

    // Only proceed if tickets are still available and widget is mounted
    if (available && mounted) {
      // Prepare data payload for payment screen
      final Map<String, int> ticketsToPurchase = Map.from(_selectedQuantities)
        ..removeWhere((key, value) => value == 0); // Remove levels with 0 quantity

      // Close the dialog *before* navigating to prevent context issues
      Navigator.of(context).pop(); // Close the selection dialog
      // Navigate to the Payment Screen with arguments
      Navigator.pushNamed(
        context,
        AppRoutes.payment, // Use route name from central definition
        arguments: {
          'eventId': widget.eventId,
          'tickets': ticketsToPurchase, // Pass the map {levelName: quantity}
        },
      );
    } else {
      // Error message should have been set by _checkFinalAvailability
      // Reset processing state if staying on dialog due to error
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
    // Ensure processing is reset even if navigation fails for some reason (though unlikely)
    if (mounted && _isProcessing){
      setState(() { _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Calculate total selected tickets
    final totalSelected = _selectedQuantities.values.fold(0, (sum, item) => sum + item);

    return SizedBox( // Constrain the size of the dialog content
      width: double.maxFinite, // Try to use available width
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make column height fit content
        children: [
          // --- Refresh Button ---
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text("Refresh Availability"),
                  onPressed: _isProcessing ? null : _fetchAvailabilityCounts, // Disable while processing
                  style: TextButton.styleFrom(
                    textStyle: theme.textTheme.labelSmall,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                )
              ],
            ),
          ),
          // --- Error Message Area ---
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          // --- Scrollable List of Ticket Levels ---
          Flexible( // Allows the ListView to take available space and scroll
            child: ListView.builder(
              shrinkWrap: true, // Make ListView fit its content size
              itemCount: widget.ticketLevels.length,
              itemBuilder: (context, index) {
                final level = widget.ticketLevels[index];
                // Safely extract data for this level
                final levelName = level['levelName'] as String? ?? 'UnknownLevel_${index}';
                final price = (level['price'] as num?)?.toDouble() ?? 0.0;
                final isLoading = _isLoadingAvailability[levelName] ?? true;
                final available = _availableCounts[levelName] ?? 0;
                final selected = _selectedQuantities[levelName] ?? 0;

                // Skip rendering if level name is invalid
                if (levelName.startsWith('UnknownLevel')) return const SizedBox.shrink();

                // Build row for each ticket level
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Level Info (Name, Price, Availability)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(levelName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                            Text('\$${price.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 2),
                            if (isLoading)
                              const Row(
                                children: [
                                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
                                  SizedBox(width: 4),
                                  Text('Checking...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              )
                            else
                              Text('Available: $available', style: TextStyle(color: available > 0 ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      // Quantity Selector (+/- buttons)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            iconSize: 24, // Slightly larger icons
                            color: selected > 0 ? theme.colorScheme.primary : Colors.grey.shade400,
                            padding: EdgeInsets.zero, // Reduce padding
                            constraints: BoxConstraints(), // Reduce padding
                            tooltip: 'Decrease quantity',
                            // Disable if 0 selected or processing
                            onPressed: selected > 0 && !_isProcessing ? () => _decrementQuantity(levelName) : null,
                          ),
                          // Display selected quantity
                          SizedBox( // Give quantity text fixed width for alignment
                            width: 24,
                            child: Text(
                              '$selected',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            iconSize: 24,
                            color: selected < available ? theme.colorScheme.primary : Colors.grey.shade400,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            tooltip: 'Increase quantity',
                            // Disable if max available reached or processing
                            onPressed: selected < available && !_isProcessing ? () => _incrementQuantity(levelName) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20), // Space before button
          // --- Proceed Button ---
          ElevatedButton(
            // Disable button if processing or if nothing is selected
            onPressed: _isProcessing || totalSelected == 0 ? null : _proceedToPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44), // Make button slightly taller and full width
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }
}