import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() { _isLoading = true; });

    await Future.delayed(const Duration(seconds: 2));
    bool paymentSuccess = true;

    bool backendUpdateSuccess = false;
    if (paymentSuccess) {
      final String cardLast4 = _cardNumberController.text.length >= 4
          ? _cardNumberController.text.substring(_cardNumberController.text.length - 4)
          : '**';
      final String cardHolderName = _cardHolderNameController.text;

      backendUpdateSuccess = await _assignTicketsAndRecordPayment(
        eventId: _eventId,
        ticketsToBuy: _ticketsToBuy,
        totalAmount: _totalAmount,
        cardLast4: cardLast4,
        cardHolderName: cardHolderName,
      );
    }

    if (mounted) {
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
    final DocumentReference paymentLogRef = firestore.collection('event_payment_logs').doc(eventId);

    try {
      final paymentRecordRef = firestore.collection('payments').doc();

      await firestore.runTransaction((transaction) async {
        List<Future<QuerySnapshot>> availabilityChecks = [];
        Map<String, List<DocumentSnapshot>> availableDocsPerLevel = {};

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

        final Timestamp now = Timestamp.now();

        availableDocsPerLevel.forEach((levelName, docsToUpdate) {
          for (var doc in docsToUpdate) {
            transaction.update(doc.reference, {
              'status': 'sold',
              'userId': userId,
              'purchaseTimestamp': now,
            });
          }
        });

        final paymentData = {
          'paymentId': paymentRecordRef.id,
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

        transaction.update(eventRef, {
          'totalRevenue': FieldValue.increment(totalAmount),
          'totalTicketsSold': FieldValue.increment(totalQuantitySoldThisTx),
          'lastTransactionTimestamp': now,
        });

        final paymentLogEntry = {
          'userId': userId,
          'amount': totalAmount,
          'paymentTimestamp': now,
          'paymentRecordId': paymentRecordRef.id,
          'tickets': ticketsToBuy,
        };
        transaction.update(paymentLogRef, {
          'payments': FieldValue.arrayUnion([paymentLogEntry])
        });
      });

      print("Firestore transaction successful");
      return true;

    } catch (e) {
      print("Firestore transaction failed: $e");
      if (mounted) {
        if (e is FirebaseException && e.code == 'not-found') {
          _showErrorSnackBar("Failed to complete purchase. Payment log for event not found. Error: ${e.toString()}");
        } else {
          _showErrorSnackBar("Failed to complete purchase. Please try again. Error: ${e.toString()}");
        }
      }
      return false;
    }
  }

  void _showReceiptDialog() {
    List<Widget> receiptTicketWidgets = _ticketsToBuy.entries.map((entry) {
      return Text('  - ${entry.key}: ${entry.value}');
    }).toList();

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.check_mark_circled, color: CupertinoColors.systemGreen),
              SizedBox(width: 8),
              Text('Payment Successful'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const Text('Thank you for your purchase!'),
                const SizedBox(height: 16),
                Text('Event ID: $_eventId'),
                const SizedBox(height: 8),
                const Text('Tickets Purchased:'),
                ...receiptTicketWidgets,
                const SizedBox(height: 16),
                Text(
                  'Total Amount Paid: \$${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Card ending in: ** ** ** ${_cardNumberController.text.length >= 4 ? _cardNumberController.text.substring(_cardNumberController.text.length - 4) : '**'}',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: CupertinoColors.systemRed,
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Complete Payment'),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CupertinoFormSection.insetGrouped(
                    header: const Text('ORDER SUMMARY'),
                    children: [
                      CupertinoListTile(
                        title: const Text('Event ID'),
                        trailing: Text(_eventId),
                      ),
                      if (_ticketsToBuy.isNotEmpty) ...[
                        const CupertinoListTile(
                          title: Text('Selected Tickets'),
                        ),
                        ..._ticketsToBuy.entries.map((entry) => CupertinoListTile(
                          title: Text(entry.key),
                          trailing: Text('${entry.value} ticket(s)'),
                        )).toList(),
                      ],
                      CupertinoListTile(
                        title: const Text('Total Amount'),
                        trailing: _isLoadingTotal
                            ? const CupertinoActivityIndicator()
                            : Text(
                          '\$${_totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: CupertinoTheme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  CupertinoFormSection.insetGrouped(
                    header: const Text('PAYMENT DETAILS'),
                    footer: const Text(
                      "WARNING: This is for demonstration only. DO NOT enter real card details.",
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                    children: [
                      CupertinoTextFormFieldRow(
                        controller: _cardHolderNameController,
                        prefix: const Text('Name'),
                        placeholder: 'Cardholder Name',
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Required' : null,
                        textCapitalization: TextCapitalization.words,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      CupertinoTextFormFieldRow(
                        controller: _cardNumberController,
                        prefix: const Text('Number'),
                        placeholder: 'XXXX XXXX XXXX XXXX',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                          _CardNumberInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          String cleaned = value.replaceAll(' ', '');
                          if (cleaned.length != 16) return 'Invalid card number';
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoTextFormFieldRow(
                              controller: _expiryDateController,
                              prefix: const Text('Expiry'),
                              placeholder: 'MM/YY',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _ExpiryDateInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(value)) {
                                  return 'Invalid format';
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: CupertinoTextFormFieldRow(
                              controller: _cvvController,
                              prefix: const Text('CVV'),
                              placeholder: '123',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
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

                  const SizedBox(height: 32),

                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    onPressed: (_isLoading || _isLoadingTotal) ? null : _processPayment,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : Text('Pay \$${_totalAmount.toStringAsFixed(2)}'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
