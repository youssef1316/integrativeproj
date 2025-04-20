import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import your data models
import 'package:eventmangment/modules/events.dart';
// Ticket model no longer needed for this screen's core logic
// import 'package:eventmangment/modules/tickets.dart';
import 'package:eventmangment/modules/feedback.dart';
import 'package:eventmangment/modules/customers.dart'; // Import your Customer model

class ReportsScreen extends StatefulWidget {
  final String eventId;

  const ReportsScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  Events? _eventDetails; // Stores fetched event data (includes financial totals)

  // Feedback Data
  List<FeedbackItem> _eventFeedback = [];

  // --- NEW: Store fetched user data ---
  Map<String, Customer> _userDataMap = {}; // Map<userId, Customer>

  // --- REMOVED: Calculated variables (now fetched directly) ---
  // int _ticketsSold = 0;
  // double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchReportData(widget.eventId);
  }

  // --- RENAMED and REWRITTEN: Fetch required data ---
  Future<void> _fetchReportData(String eventId) async {
    if (eventId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = "No Event ID provided.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _eventDetails = null;
      _eventFeedback = [];
      _userDataMap = {}; // Clear user data map
    });

    try {
      // --- Step 1: Fetch Event Document (contains financial data) ---
      final eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (!eventDoc.exists || eventDoc.data() == null) {
        throw FirebaseException(plugin: 'Firestore', message: 'Event not found.');
      }
      // Parse event details (includes totalRevenue, totalTicketsSold)
      _eventDetails = Events.fromSnapshot(eventDoc);

      // --- Step 2: Fetch Feedback for the Event ---
      final feedbackSnapshot = await _firestore
          .collection('feedback')
          .where('eventId', isEqualTo: eventId)
          .get();

      _eventFeedback = feedbackSnapshot.docs
          .map((doc) => FeedbackItem.fromSnapshot(doc))
          .toList();

      // --- Step 3: Fetch User Details for Feedback Submitters ---
      if (_eventFeedback.isNotEmpty) {
        // Get unique user IDs from feedback
        final userIds = _eventFeedback.map((fb) => fb.userId).toSet().toList();

        // Fetch user documents if there are IDs
        if (userIds.isNotEmpty) {
          // Assuming your users collection uses the userId as the document ID
          // Adjust collection name ('users') and field check if necessary
          final userDocsSnapshot = await _firestore
              .collection('users') // Make sure 'users' is your user collection name
              .where(FieldPath.documentId, whereIn: userIds)
              .get();

          for (var userDoc in userDocsSnapshot.docs) {
            // Assuming Customer.fromSnapshot exists
            _userDataMap[userDoc.id] = Customer.fromSnapshot(userDoc);
          }
        }
      }

      // --- REMOVED: _processFetchedData() is no longer needed ---
      // Data is now used directly from _eventDetails and _eventFeedback/_userDataMap

    } catch (e, stacktrace) {
      print("Error fetching report data: $e");
      print("Stacktrace: $stacktrace");
      setState(() {
        _error = "Failed to load report data. Please try again.";
        if (e is FirebaseException && e.message != null && e.message!.contains('Event not found')) {
          _error = "Selected event could not be found.";
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Use financial data directly from _eventDetails
    final int ticketsSold = _eventDetails?.totalTicketsSold ?? 0;
    final double totalRevenue = _eventDetails?.totalRevenue ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_eventDetails?.name ?? "Event Report"),
      ),
      body: _buildBody(ticketsSold, totalRevenue), // Pass financial data
    );
  }

  // Accept financial data as parameters
  Widget _buildBody(int ticketsSold, double totalRevenue) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      // Error handling remains the same...
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () => _fetchReportData(widget.eventId), // Retry specific event fetch
                  child: const Text("Retry")
              )
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchReportData(widget.eventId),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Pass fetched financial data to the section builder
          _buildFinancialSection(ticketsSold, totalRevenue),
          const SizedBox(height: 20),
          _buildFeedbackSection(), // Feedback uses state variables _eventFeedback and _userDataMap
        ],
      ),
    );
  }


  // Accept financial data as parameters
  Widget _buildFinancialSection(int ticketsSold, double totalRevenue) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Financial Summary",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Event:",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _eventDetails?.name ?? 'N/A',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tickets Sold:", // Directly from event data
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  ticketsSold.toString(), // Use passed value
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Revenue:", // Directly from event data
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormatter.format(totalRevenue), // Use passed value
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: totalRevenue >= 0 ? Colors.green[700] : Colors.red[700]
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "User Feedback",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (_eventFeedback.isEmpty)
          const Center( /* ... No feedback message ... */ )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _eventFeedback.length,
            itemBuilder: (context, index) {
              final feedback = _eventFeedback[index];
              // --- Get user data from the map ---
              final userData = _userDataMap[feedback.userId];
              return FeedbackCard(
                feedback: feedback,
                userData: userData, // Pass user data
              );
            },
          ),
      ],
    );
  }
}


// --- MODIFIED FeedbackCard to accept and display user data ---
class FeedbackCard extends StatelessWidget {
  final FeedbackItem feedback;
  final Customer? userData; // Accept nullable Customer data

  const FeedbackCard({
    super.key,
    required this.feedback,
    this.userData, // Make optional
  });

  @override
  Widget build(BuildContext context) {
    // Determine user name to display
    String userName = userData?.name ?? "Unknown User";
    // Optionally display email or other info if needed
    // String userEmail = userData?.email ?? "No email";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Display User Name ---
            Text(
              userName, // Display fetched/default user name
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // --- Rating Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rating:",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18,),
                    const SizedBox(width: 4),
                    Text(
                      feedback.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 15),

            // --- Comment Section ---
            Text(
              feedback.comment.isNotEmpty ? feedback.comment : "No comment provided.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: feedback.comment.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                  color: feedback.comment.isNotEmpty ? null : Colors.grey[600]
              ),
            ),
            // --- Optional: Display submission time ---
            /*
             if (feedback.submittedAt != null) ...[
                 const SizedBox(height: 8),
                 Text(
                    "Submitted: ${DateFormat.yMd().add_jm().format(feedback.submittedAt!.toDate())}", // Format timestamp
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                 ),
             ]
            */
          ],
        ),
      ),
    );
  }
}