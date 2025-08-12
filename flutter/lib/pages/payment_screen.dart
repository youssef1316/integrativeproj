import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID
import 'package:cloud_firestore/cloud_firestore.dart'; // To update tickets and store payment
import 'package:eventmangment/main.dart';
import 'package:eventmangment/firebase_options.dart';
import 'package:eventmangment/pages/otp.dart';
import 'package:eventmangment/onlinestatus.dart';
import 'package:eventmangment/offlineredirect.dart';


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

  
  // otp controllers/variables
  final _phoneController = TextEditingController();
  bool _isPhoneVerified = false; 
  String? _otpVerificationId; 
  bool _otpSending = false; 
  bool _otpVerifying = false; 
  int? _resendToken; 
  FirebaseApp? _otpApp;
  FirebaseAuth? _otpAuth;

  //discount codes controllers/variables
  final _promocontroller = TextEditingController();
  String? _appliedCodeId;     // Firestore doc ID of the discount
  String? _appliedCodeUpper;  // e.g., SUMMER25
  int? _appliedPercent;       // 1..100
  double _appliedAmount = 0;  // computed discount value

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
    _phoneController.dispose();
    _promocontroller.dispose();
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

  double get _finalTotal =>((_totalAmount - _appliedAmount).clamp(0.0, double.infinity) as double);

  // temp app function for otp
  Future<FirebaseApp> _ensureTempOtpApp() async {
    try {
      _otpApp = Firebase.app('otpTemp');
    } catch (_) {
      _otpApp = await Firebase.initializeApp(
        name: 'otpTemp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _otpAuth = FirebaseAuth.instanceFor(app: _otpApp!);
    return _otpApp!;
  }

  Future<void> _startPhoneVerification() async {
    if (!_formKey.currentState!.validate()) { return; }
    final phone = _phoneController.text.trim();
    setState(() { _otpSending = true; });

    try {
      final tempApp = await _ensureTempOtpApp();
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      await tempAuth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final auth = _otpAuth ?? FirebaseAuth.instanceFor(app: _otpApp!);
            await auth.signInWithCredential(credential);
            if (mounted) setState(() => _isPhoneVerified = true);
            await auth.signOut();
            await _otpApp?.delete(); _otpApp = null; _otpAuth = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone auto-verified')),
                );
              }
            });
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message ?? e.code}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          _otpVerificationId = verificationId;
          _resendToken = resendToken;
          final bool? ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const OtpVerifyPage(),
            settings: RouteSettings(
              arguments: (String code) => _verifyOtpForPayment(code),
            ),
          ),
        );

        if (ok == true) {
          if (!mounted) return;
          setState(() { _isPhoneVerified = true; });
          // Post-frame snackbar to avoid build-scope issues
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone verification successful for this payment')),
            );
          });
        }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _otpVerificationId = verificationId;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start verification: $e')),
      );
    } finally {
      if (mounted) setState(() { _otpSending = false; });
    }
  }


  //otp verification function
  Future<void> _verifyOtpForPayment(String smsCode) async {
    if (_otpVerificationId == null) {
      throw Exception('No OTP session in progress.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _otpVerificationId!, 
      smsCode: smsCode,                      
    );

    final tempApp = await _ensureTempOtpApp();                 
    final tempAuth = _otpAuth ?? FirebaseAuth.instanceFor(app: tempApp);

    try {
      await tempAuth.signInWithCredential(credential);
      _isPhoneVerified = true;
    } on FirebaseAuthException catch (e) {
      throw Exception('OTP verification failed: ${e.message ?? e.code}');
    } finally {
      await tempAuth.signOut();
      await _otpApp?.delete();
      _otpApp = null;
      _otpAuth = null;
    }
  }


// --- Payment Processing (Simulation) ---
  Future<void> _processPayment() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone number via OTP before paying.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() { _isLoading = true; });
    
    //discount applied to total
    final double finalTotal = _finalTotal;

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
        totalAmount: finalTotal,
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

  Future<void> _applyDiscount() async {
    final raw = _promocontroller.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a code')));
      return;
    }
    final code = raw.toUpperCase();

    try {
      // find by codeUpper + active true
      final q = await FirebaseFirestore.instance
        .collection('discount_codes')
        .where('codeUpper', isEqualTo: code)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

      if (q.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or inactive code')));
        return;
      }
      final d = q.docs.first;
      final data = d.data();

      // event match (global if null)
      final eventId = data['eventId'] as String?;
      if (eventId != null && eventId != _eventId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code not valid for this event')));
        return;
      }

      // time window
      final now = Timestamp.now();
      final startsAt = data['startsAt'] as Timestamp?;
      final expiresAt = data['expiresAt'] as Timestamp?;
      if (startsAt != null && now.compareTo(startsAt) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code not active yet')));
        return;
      }
      if (expiresAt != null && now.compareTo(expiresAt) > 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code has expired')));
        return;
      }

      // one-time (check redemption)
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final redemRef = d.reference.collection('redemptions').doc(uid);
      final used = await redemRef.get();
      if (used.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You already used this code')));
        return;
      }

      // compute amount
      final percent = (data['percent'] as num).toInt().clamp(1, 100);
      final disc = (_totalAmount * percent / 100).clamp(0, _totalAmount);

      setState(() {
        _appliedCodeId = d.id;
        _appliedCodeUpper = code;
        _appliedPercent = percent;
        _appliedAmount = disc.toDouble();
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code applied')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
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

        //redeem discount code
        if (_appliedCodeId != null) {
          final redemRef = firestore
              .collection('discount_codes')
              .doc(_appliedCodeId!)
              .collection('redemptions')
              .doc(userId);
          transaction.set(redemRef, {
            'createdAt': now,
          });
        }

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
          //store dicount details
          'originalAmount': _totalAmount,      
          if (_appliedCodeId != null)
            'discount': {
              'codeId': _appliedCodeId,
              'codeUpper': _appliedCodeUpper,
              'percent': _appliedPercent,
              'amount': _appliedAmount,        
            },
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
                  'Total Amount Paid: \$${_finalTotal.toStringAsFixed(2)}',
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
      body: Stack(
        children: [
          const OfflineRedirector(
            homeRoute: AppRoutes.userHome,
            reason: 'Payment requires internet. You were redirected.',
          ),
          SingleChildScrollView(
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
                        '\$${_finalTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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

                // Phone / OTP
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (e.g. +201234567890)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
                    final ok = RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value.trim());
                    if (!ok) return 'e.g. +201234567890';
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _otpSending
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.sms),
                        onPressed: _otpSending ? null : _startPhoneVerification,
                        label: const Text('Send OTP'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isPhoneVerified)
                      const Icon(Icons.verified, color: Colors.green),
                  ],
                ),

                // Discount code
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promocontroller,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Discount code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_offer_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyDiscount,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                if (_appliedPercent != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text('$_appliedCodeUpper - $_appliedPercent%'),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          setState(() {
                            _appliedCodeId = null;
                            _appliedCodeUpper = null;
                            _appliedPercent = null;
                            _appliedAmount = 0;
                          });
                        },
                      ),
                      const Spacer(),
                      Text('-${_appliedAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                // --- Payment Button ---
                Center(
                  child: ElevatedButton.icon(
                    icon: _isLoading ? Container() : const Icon(Icons.lock_outline),
                    label: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : Text('Pay \$${_finalTotal.toStringAsFixed(2)}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: (_isLoading || _isLoadingTotal) ? null : _processPayment,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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