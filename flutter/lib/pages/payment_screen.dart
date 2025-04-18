// lib/pages/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID
import 'package:cloud_firestore/cloud_firestore.dart'; // To update tickets
import 'package:eventmangment/main.dart'; // For AppRoutes (if navigating away)

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // For the payment button processing state
  bool _isLoadingTotal = true; // For fetching prices initially
  double _totalAmount = 0.0;

  // Controllers for payment fields
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController(); // Added

  // Data passed from previous screen
  String _eventId = 'N/A';
  Map<String, int> _ticketsToBuy = {};

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available for ModalRoute
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractArgumentsAndCalculateTotal();
    });
  }

  void _extractArgumentsAndCalculateTotal() {
    // Retrieve arguments after the first frame
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      setState(() { // Store arguments in state variables
        _eventId = arguments['eventId'] ?? 'N/A';
        _ticketsToBuy = arguments['tickets'] as Map<String, int>? ?? {};
      });
      _calculateTotalAmount(); // Start calculation
    } else {
      // Handle error: Arguments are missing
      print("Error: Payment screen loaded without necessary arguments.");
      setState(() { _isLoadingTotal = false; }); // Stop loading indicator
      _showErrorSnackBar("Error loading payment details.");
      // Optionally navigate back
      // Navigator.pop(context);
    }
  }


  Future<void> _calculateTotalAmount() async {
    if (_eventId == 'N/A' || _ticketsToBuy.isEmpty) {
      setState(() => _isLoadingTotal = false);
      return;
    }

    try {
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(_eventId)
          .get();

      if (!eventDoc.exists || eventDoc.data() == null) {
        throw Exception("Event not found");
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final List<dynamic> ticketLevelsRaw = eventData['ticketLevels'] as List<dynamic>? ?? [];
      final List<Map<String, dynamic>> ticketLevels = List<Map<String, dynamic>>.from(
          ticketLevelsRaw.whereType<Map>().map((item) => Map<String, dynamic>.from(item))
      );

      double calculatedTotal = 0;
      _ticketsToBuy.forEach((levelName, quantity) {
        final levelData = ticketLevels.firstWhere(
              (level) => level['levelName'] == levelName,
          orElse: () => {}, // Return empty map if level not found
        );
        if (levelData.isNotEmpty) {
          final price = (levelData['price'] as num?)?.toDouble() ?? 0.0;
          calculatedTotal += (price * quantity);
        } else {
          print("Warning: Price for level '$levelName' not found in event data.");
        }
      });

      setState(() {
        _totalAmount = calculatedTotal;
        _isLoadingTotal = false;
      });

    } catch (e) {
      print("Error calculating total: $e");
      setState(() { _isLoadingTotal = false; });
      _showErrorSnackBar("Error calculating total amount.");
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // --- !!! THIS IS A SIMULATION - DO NOT USE FOR REAL PAYMENTS !!! ---
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if card info is invalid
    }

    setState(() { _isLoading = true; });

    await Future.delayed(const Duration(seconds: 2));
    bool paymentSuccess = true; // Assume success for simulation

    // ** 2. BACKEND TICKET ASSIGNMENT (SHOULD BE IN CLOUD FUNCTION) **
    bool backendUpdateSuccess = false;
    if (paymentSuccess) {
      backendUpdateSuccess = await _assignTicketsInFirestore();
    }

    if (mounted) { // Check context is still valid
      setState(() { _isLoading = false; });

      if (paymentSuccess && backendUpdateSuccess) {
        // Show Receipt Dialog on success
        _showReceiptDialog();
      } else if (!backendUpdateSuccess && paymentSuccess){
        _showErrorSnackBar("Payment processed (simulated), but failed to assign tickets. Contact support.");
      } else {
        _showErrorSnackBar("Payment failed (simulated). Please try again.");
      }
    }
  }

  Future<bool> _assignTicketsInFirestore() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("Error: User not logged in for ticket assignment.");
      return false;
    }
    final firestore = FirebaseFirestore.instance;

    // Use a Transaction to ensure atomicity
    try {
      await firestore.runTransaction((transaction) async {
        List<Future<QuerySnapshot>> availabilityChecks = [];
        Map<String, List<DocumentSnapshot>> availableDocsPerLevel = {};

        // 1. Check availability for ALL requested tickets first
        _ticketsToBuy.forEach((levelName, quantity) {
          final query = firestore
              .collection('tickets')
              .where('eventId', isEqualTo: _eventId)
              .where('levelName', isEqualTo: levelName)
              .where('status', isEqualTo: 'available')
              .limit(quantity);
          availabilityChecks.add(query.get()); // Add future to list
        });

        // Wait for all availability checks
        final List<QuerySnapshot> results = await Future.wait(availabilityChecks);

        // Verify counts and collect docs
        bool sufficientTickets = true;
        int checkIndex = 0;
        for (var entry in _ticketsToBuy.entries) {
          final levelName = entry.key;
          final quantity = entry.value;
          final snapshot = results[checkIndex];

          if (snapshot.docs.length < quantity) {
            sufficientTickets = false;
            print("Error: Not enough tickets available for $levelName. Needed: $quantity, Found: ${snapshot.docs.length}");
            // Optionally store specific error message
            break; // Stop checking if one level fails
          }
          availableDocsPerLevel[levelName] = snapshot.docs; // Store docs to update
          checkIndex++;
        }

        if (!sufficientTickets) {
          // Throwing an error inside the transaction automatically aborts it
          throw FirebaseException(plugin: 'App', code: 'unavailable-tickets', message: 'Not enough tickets available for one or more levels.');
        }

        // 2. If all checks passed, update the tickets
        final now = FieldValue.serverTimestamp();
        availableDocsPerLevel.forEach((levelName, docsToUpdate) {
          for (var doc in docsToUpdate) {
            transaction.update(doc.reference, {
              'status': 'sold',
              'userId': userId,
              'purchaseTimestamp': now,
            });
          }
        });
      });
      // Transaction successful
      print("Firestore transaction successful - Tickets assigned.");
      return true;
    } catch (e) {
      print("Firestore transaction failed: $e");
      // Show specific error based on exception if needed
      return false;
    }
  }
  // --- END OF BACKEND LOGIC ---


  // --- Receipt Dialog ---
  void _showReceiptDialog() {
    // Prepare receipt details
    List<Widget> receiptTicketWidgets = _ticketsToBuy.entries.map((entry) {
      return Text('  - ${entry.key}: ${entry.value}');
    }).toList();

    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must explicitly close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Payment Successful'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Thank you for your purchase!'),
                const SizedBox(height: 15),
                Text('Event ID: $_eventId'),
                const SizedBox(height: 5),
                const Text('Tickets Purchased:'),
                ...receiptTicketWidgets,
                const SizedBox(height: 15),
                Text(
                  'Total Amount Paid: \$${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Card ending in: **** **** **** ${_cardNumberController.text.length >= 4 ? _cardNumberController.text.substring(_cardNumberController.text.length - 4) : '****'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // Navigate back to user home or maybe a 'My Tickets' screen
                Navigator.pop(context); // Pop the payment screen itself
                // OR Navigator.pushNamedAndRemoveUntil(context, AppRoutes.userHome, (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build a simple display for the passed data
    List<Widget> ticketSummaryWidgets = _ticketsToBuy.entries.map((entry) {
      // Find price for display (optional but nice)
      // This assumes event data with ticketLevels was fetched successfully in _calculateTotalAmount
      // If _calculateTotalAmount failed, prices might not show correctly here.
      double price = 0;
      // TODO: Get price from fetched event data if available to show subtotal
      return Text('  - ${entry.key}: ${entry.value} ticket(s)');
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'), // Changed title
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Allow scrolling
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Order Summary ---
            Text('Order Summary', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Event ID: $_eventId', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 5),
            if (_ticketsToBuy.isNotEmpty) ...[
              const Text('Selected Tickets:'),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ticketSummaryWidgets),
              ),
            ],
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_isLoadingTotal)
                  const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text(
                      '\$${_totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
                  ),
              ],
            ),
            const Divider(height: 30, thickness: 1),

            // --- Payment Form ---
            Text('Payment Details', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 15),
            const Text(
              "WARNING: This is for demonstration only. DO NOT enter real card details.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 15),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Holder Name
                  TextFormField(
                    controller: _cardHolderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter cardholder name' : null,
                    textCapitalization: TextCapitalization.words,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 12),

                  // Card Number
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      hintText: 'XXXX XXXX XXXX XXXX',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16), // Limit length
                      _CardNumberInputFormatter(), // Add spacing
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter card number';
                      String cleaned = value.replaceAll(' ', '');
                      if (cleaned.length != 16) return 'Enter a valid 16-digit card number';
                      // Add more sophisticated checks (Luhn algorithm) in real app
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Expiry Date
                      Expanded(
                        child: TextFormField(
                          controller: _expiryDateController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            hintText: 'MM/YY',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryDateInputFormatter(), // Add MM/YY slash
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter expiry';
                            if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(value)) {
                              return 'Use MM/YY format';
                            }
                            // Basic check if expiry is in the past
                            final parts = value.split('/');
                            final month = int.tryParse(parts[0]);
                            final year = int.tryParse('20${parts[1]}'); // Assume 20xx
                            final now = DateTime.now();
                            if (month == null || year == null) return 'Invalid date';
                            // Check if year is past or current year and month is past
                            if (year < now.year || (year == now.year && month < now.month)) {
                              return 'Card expired';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // CVV
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                            prefixIcon: Icon(Icons.password_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4), // Allow 3 or 4 digits
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter CVV';
                            if (value.length < 3 || value.length > 4) return 'Invalid CVV';
                            return null;
                          },
                          obscureText: true, // Hide CVV
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35), // More space before button

            // --- Payment Button ---
            Center(
              child: ElevatedButton.icon(
                icon: _isLoading ? Container() : const Icon(Icons.lock_outline), // Hide icon when loading
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text('Pay \$${_totalAmount.toStringAsFixed(2)}'), // Show amount
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Disable button while calculating total or processing payment
                onPressed: (_isLoading || _isLoadingTotal) ? null : _processPayment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Custom Input Formatters (Place at bottom or in separate file) ---

// Formatter for Card Number (adds spaces)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', ''); // Remove existing spaces
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' '); // Add space after every 4 digits
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}

// Formatter for Expiry Date (adds '/')
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) { // Add slash after MM
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}