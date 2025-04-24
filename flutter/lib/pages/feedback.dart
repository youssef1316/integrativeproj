import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID
import 'package:cloud_firestore/cloud_firestore.dart'; // To interact with Firestore

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingSubmit = false; // For submit button loading state
  bool _isLoadingEvents = true; // For fetching events loading state

  // Controller for feedback text
  final _feedbackTextController = TextEditingController();

  // State for the rating slider
  double _currentRating = 5.0; // Default rating

  // State for event dropdown
  List<Map<String, String>> _purchasedEvents = []; // List of {'id': eventId, 'name': eventName}
  String? _selectedEventId; // Currently selected event ID from dropdown

  @override
  void initState() {
    super.initState();
    // Fetch events when the screen initializes
    _fetchPurchasedEvents();
  }

  @override
  void dispose() {
    _feedbackTextController.dispose();
    super.dispose();
  }

  // Helper to show SnackBars
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  // --- Function to fetch events user bought tickets for ---
  Future<void> _fetchPurchasedEvents() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar("Error: User not logged in.");
      if (!mounted) return;
      setState(() { _isLoadingEvents = false; });
      return;
    }

    setState(() { _isLoadingEvents = true; }); // Start loading

    try {
      // 1. Find tickets bought by the user
      final ticketSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'sold')
          .get();

      if (ticketSnapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _purchasedEvents = [];
          _isLoadingEvents = false;
        });
        return; // No tickets found
      }

      // 2. Extract unique event IDs
      final eventIds = ticketSnapshot.docs.map((doc) => doc.data()['eventId'] as String?).where((id) => id != null).toSet().toList();

      if (eventIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _purchasedEvents = [];
          _isLoadingEvents = false;
        });
        return; // No valid event IDs found
      }

      // 3. Fetch event details for those IDs
      // Firestore 'whereIn' query requires a non-empty list and has a limit of 30 elements per query
      // Handle potential partitioning if eventIds list is very large (though unlikely for purchased tickets)
      if (eventIds.length > 30) {
        print("Warning: Querying more than 30 event IDs, potential performance issue or need for partitioning.");
        // Handle partitioning if necessary, for now proceed with potentially multiple queries if needed, or just the first 30
      }

      final eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where(FieldPath.documentId, whereIn: eventIds) // Use FieldPath.documentId
          .get();

      // 4. Map results to the state list
      final List<Map<String, String>> eventsList = eventSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String? ?? 'Unknown Event', // Handle missing name
        };
      }).toList();

      // Sort events alphabetically by name for better dropdown display
      eventsList.sort((a, b) => a['name']!.compareTo(b['name']!));

      if (!mounted) return;
      setState(() {
        _purchasedEvents = eventsList;
        _isLoadingEvents = false;
      });

    } catch (e) {
      print("Error fetching purchased events: $e");
      _showSnackBar("Failed to load your event list. Error: ${e.toString()}");
      if (!mounted) return;
      setState(() { _isLoadingEvents = false; });
    }
  }


  // --- Function to handle feedback submission ---
  Future<void> _submitFeedback() async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      // Validation messages shown by FormFields, maybe add a general snackbar
      // _showSnackBar("Please fill in all required fields correctly.");
      return;
    }

    // Check if user is logged in
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar("Error: You must be logged in to submit feedback.");
      return;
    }

    // We validated that _selectedEventId is not null via the DropdownButtonFormField validator
    final String selectedEventId = _selectedEventId!;
    // Find the corresponding event name from the fetched list
    final selectedEvent = _purchasedEvents.firstWhere(
            (event) => event['id'] == selectedEventId,
        orElse: () => {'id': selectedEventId, 'name': 'Unknown Event'} // Fallback
    );
    final String selectedEventName = selectedEvent['name']!;


    if (!mounted) return;
    setState(() { _isLoadingSubmit = true; });

    try {
      // Prepare data for Firestore
      final feedbackData = {
        'eventId': selectedEventId, // Store the ID
        'eventName': selectedEventName, // Store the name for easier reading
        'feedbackText': _feedbackTextController.text.trim(),
        'rating': _currentRating.round(), // Store rating as an integer (1-10)
        'userId': userId,
        'submittedAt': FieldValue.serverTimestamp(), // Use server time
      };

      // Add data to Firestore collection 'feedback'
      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      // Success
      _showSnackBar("Feedback submitted successfully!", isError: false);

      // Optionally clear the form or navigate back after success
      _formKey.currentState?.reset(); // Resets form fields including dropdown
      _feedbackTextController.clear();
      if (!mounted) return;
      setState(() {
        _selectedEventId = null; // Explicitly reset dropdown state variable
        _currentRating = 5.0; // Reset slider
      });
      // Consider Navigator.pop(context);

    } catch (e) {
      print("Error submitting feedback: $e");
      _showSnackBar("Failed to submit feedback. Please try again. Error: ${e.toString()}");
    } finally {
      if (!mounted) return;
      setState(() { _isLoadingSubmit = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Give Feedback"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "We appreciate your feedback!",
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              // --- Event Selection Dropdown ---
              _isLoadingEvents
                  ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(),
              ))
                  : _purchasedEvents.isEmpty
                  ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      "You haven't purchased tickets for any events yet.",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  )
              )
                  : DropdownButtonFormField<String>(
                value: _selectedEventId,
                decoration: const InputDecoration(
                  labelText: 'Select Event',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_note), // Changed icon
                ),
                items: _purchasedEvents.map((event) {
                  return DropdownMenuItem<String>(
                    value: event['id'],
                    child: Text(event['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select the event';
                  }
                  return null;
                },
                // Make dropdown expanded to prevent overflow if names are long
                isExpanded: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 20),

              // --- Feedback Text Field ---
              TextFormField(
                controller: _feedbackTextController,
                decoration: const InputDecoration(
                  labelText: 'Your Feedback',
                  hintText: 'Share your thoughts about the event...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 25),

              // --- Rating Section ---
              Text(
                'Rate the Event (1 - 10): ${_currentRating.round()}',
                style: theme.textTheme.titleMedium,
              ),
              Slider(
                value: _currentRating,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: _currentRating.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _currentRating = value;
                  });
                },
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              ElevatedButton(
                // Disable if loading events OR submitting OR no events available
                onPressed: (_isLoadingSubmit || _isLoadingEvents || _purchasedEvents.isEmpty)
                    ? null
                    : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: _isLoadingSubmit
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                )
                    : const Text('Submit Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}