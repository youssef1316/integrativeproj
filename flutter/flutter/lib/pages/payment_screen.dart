import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID
import 'package:cloud_firestore/cloud_firestore.dart'; // To update tickets and store payment
import 'package:eventmangment/main.dart';


class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingTotal = true;
  double _totalAmount = 0.0;

  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  String _eventId = 'N/A';
  Map<String, int> _ticketsToBuy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractArgumentsAndCalculateTotal();
    });
  }

  void _extractArgumentsAndCalculateTotal() {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      if (!mounted) return;
      setState(() {
        _eventId = arguments['eventId'] ?? 'N/A';
        _ticketsToBuy = arguments['tickets'] as Map<String, int>? ?? {};
      });
      _calculateTotalAmount();
    } else {
      print("Error: Payment screen loaded without necessary arguments.");
      if (!mounted) return;
      setState(() { _isLoadingTotal = false; });
      _showErrorSnackBar("Error loading payment details.");
    }
  }


  Future<void> _calculateTotalAmount() async {
    if (!mounted) return;
    if (_eventId == 'N/A' || _ticketsToBuy.isEmpty) {
      setState(() => _isLoadingTotal = false);
      return;
    }

    setState(() => _isLoadingTotal = true);

    try {
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(_eventId)
          .get();

      if (!mounted) return;

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
          orElse: () => {},
        );
        if (levelData.isNotEmpty) {
          final price = (levelData['price'] as num?)?.toDouble() ?? 0.0;
          calculatedTotal += (price * quantity);
        } else {
          print("Warning: Price for level '$levelName' not found in event data.");
        }
      });

      if (!mounted) return;
      setState(() {
        _totalAmount = calculatedTotal;
        _isLoadingTotal = false;
      });

    } catch (e) {
      print("Error calculating total: $e");
      if (!mounted) return;
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

  // --- Payment Processing (Simulation) ---
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() { _isLoading = true; });

    // Simulate payment gateway interaction
    await Future.delayed(const Duration(seconds: 2));
    bool paymentSuccess = true; // Assume success for simulation

    bool backendUpdateSuccess = false;
    if (paymentSuccess) {
      // Pass payment details needed for storage to the backend function
      final String cardLast4 = _cardNumberController.text.length >= 4
          ? _cardNumberController.text.substring(_cardNumberController.text.length - 4)
          : '****';
      final String cardHolderName = _cardHolderNameController.text;

      backendUpdateSuccess = await _assignTicketsAndRecordPayment(
        eventId: _eventId,
        ticketsToBuy: _ticketsToBuy,
        totalAmount: _totalAmount,
        cardLast4: cardLast4,
        cardHolderName: cardHolderName,
      );
    }

    if (mounted) { // Check context is still valid before updating UI
      setState(() { _isLoading = false; });

      if (paymentSuccess && backendUpdateSuccess) {
        _showReceiptDialog();
      } else if (!backendUpdateSuccess && paymentSuccess){
        _showErrorSnackBar("Payment processed (simulated), but failed to update records. Contact support.");
      } else {
        _showErrorSnackBar("Payment failed (simulated). Please try again.");
      }
    }
  }

  // --- Firestore Transaction: Assign Tickets, Record Payment, Update Event Totals, Update Event Payment Log ---
  Future<bool> _assignTicketsAndRecordPayment({
    required String eventId,
    required Map<String, int> ticketsToBuy,
    required double totalAmount,
    required String cardLast4,
    required String cardHolderName,
  }) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("Error: User not logged in for ticket assignment.");
      return false;
    }
    final firestore = FirebaseFirestore.instance;
    final DocumentReference eventRef = firestore.collection('events').doc(eventId);
    // *** Reference to the specific event's payment log document ***
    final DocumentReference paymentLogRef = firestore.collection('event_payment_logs').doc(eventId);

    try {
      final paymentRecordRef = firestore.collection('payments').doc();

      await firestore.runTransaction((transaction) async {
        List<Future<QuerySnapshot>> availabilityChecks = [];
        Map<String, List<DocumentSnapshot>> availableDocsPerLevel = {};

        // 1. Check availability
        ticketsToBuy.forEach((levelName, quantity) {
          final query = firestore
              .collection('tickets')
              .where('eventId', isEqualTo: eventId)
              .where('levelName', isEqualTo: levelName)
              .where('status', isEqualTo: 'available')
              .limit(quantity);
          availabilityChecks.add(query.get());
        });
        final List<QuerySnapshot> results = await Future.wait(availabilityChecks);

        // Verify counts & collect docs
        bool sufficientTickets = true;
        int totalQuantitySoldThisTx = 0;
        int checkIndex = 0;
        for (var entry in ticketsToBuy.entries) {
          final levelName = entry.key;
          final quantity = entry.value;
          final snapshot = results[checkIndex];
          if (snapshot.docs.length < quantity) {
            sufficientTickets = false;
            print("Error: Not enough tickets available for $levelName. Needed: $quantity, Found: ${snapshot.docs.length}");
            break;
          }
          availableDocsPerLevel[levelName] = snapshot.docs;
          totalQuantitySoldThisTx += quantity;
          checkIndex++;
        }

        if (!sufficientTickets) {
          throw FirebaseException(plugin: 'App', code: 'unavailable-tickets', message: 'Not enough tickets available for one or more levels.');
        }

        // Consistent Timestamp
        final Timestamp now = Timestamp.now();

        // 2. Update tickets
        availableDocsPerLevel.forEach((levelName, docsToUpdate) {
          for (var doc in docsToUpdate) {
            transaction.update(doc.reference, {
              'status': 'sold',
              'userId': userId,
              'purchaseTimestamp': now,
            });
          }
        });

        // 3. Create individual payment record (optional but good for detail)
        final paymentData = {
          'paymentId': paymentRecordRef.id, // Use pre-generated ref ID
          'userId': userId,
          'eventId': eventId,
          'amount': totalAmount,
          'paymentTimestamp': now,
          'cardLast4': cardLast4,
          'cardHolderName': cardHolderName,
          'ticketsPurchased': ticketsToBuy,
          'status': 'success',
        };
        transaction.set(paymentRecordRef, paymentData);

        // 4. Update Event Aggregate Totals
        transaction.update(eventRef, {
          'totalRevenue': FieldValue.increment(totalAmount),
          'totalTicketsSold': FieldValue.increment(totalQuantitySoldThisTx),
          'lastTransactionTimestamp': now,
        });

        // **** 5. Update Event Payment Log (Add to Array) ****
        final paymentLogEntry = {
          'userId': userId,
          'amount': totalAmount,
          'paymentTimestamp': now,
          'paymentRecordId': paymentRecordRef.id, // Link to the detailed record
          'tickets': ticketsToBuy, // Optionally store tickets summary here too
        };
        // Use arrayUnion to add the new map to the 'payments' array
        transaction.update(paymentLogRef, {
          'payments': FieldValue.arrayUnion([paymentLogEntry])
        });

      }); // End of transaction block

      print("Firestore transaction successful - Tickets assigned, payment recorded, event updated, payment log updated.");
      return true;

    } catch (e) {
      print("Firestore transaction failed: $e");
      if (mounted) {
        // Check if the error is because the payment log document doesn't exist (should have been created with the event)
        if (e is FirebaseException && e.code == 'not-found') {
          _showErrorSnackBar("Failed to complete purchase. Payment log for event not found. Error: ${e.toString()}");
        } else {
          _showErrorSnackBar("Failed to complete purchase. Please try again. Error: ${e.toString()}");
        }
      }
      return false;
    }
  }
  // --- END OF FIRESTORE LOGIC ---


  // --- Receipt Dialog (No changes needed here) ---
  void _showReceiptDialog() {
    // ... (Receipt dialog code remains the same as previous version) ...
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
                if (mounted) {
                  Navigator.pop(context); // Pop the payment screen itself
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Build method remains the same as your last provided version ---
    final theme = Theme.of(context);

    List<Widget> ticketSummaryWidgets = _ticketsToBuy.entries.map((entry) {
      return Text('  - ${entry.key}: ${entry.value} ticket(s)');
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter card number';
                      String cleaned = value.replaceAll(' ', '');
                      if (cleaned.length != 16) return 'Enter a valid 16-digit card number';
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
                            _ExpiryDateInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter expiry';
                            if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(value)) {
                              return 'Use MM/YY format';
                            }
                            final parts = value.split('/');
                            final month = int.tryParse(parts[0]);
                            final year = int.tryParse('20${parts[1]}');
                            final now = DateTime.now();
                            if (month == null || year == null) return 'Invalid date';
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
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter CVV';
                            if (value.length < 3 || value.length > 4) return 'Invalid CVV';
                            return null;
                          },
                          obscureText: true,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // --- Payment Button ---
            Center(
              child: ElevatedButton.icon(
                icon: _isLoading ? Container() : const Icon(Icons.lock_outline),
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text('Pay \$${_totalAmount.toStringAsFixed(2)}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: (_isLoading || _isLoadingTotal) ? null : _processPayment,
              ),
            ),
            const SizedBox(height: 20), // Add some padding at the bottom
          ],
        ),
      ),
    );
  }
}


// --- Custom Input Formatters ---
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
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