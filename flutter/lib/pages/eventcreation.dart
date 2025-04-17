// lib/pages/eventcreation.dart

import 'package:flutter/material.dart';
import 'package:eventmangment/modules/events.dart'; // Ensure Events model includes 'DateTime? eventDate;' [cite: flutter/lib/modules/events.dart]
import 'package:eventmangment/modules/Artists.dart'; // [cite: flutter/lib/modules/Artists.dart]
import 'package:eventmangment/modules/catering.dart'; // [cite: flutter/lib/modules/catering.dart]
import 'package:eventmangment/modules/tickets.dart'; // Ensure Ticket model is updated [cite: flutter/lib/modules/tickets.dart]
import 'package:cloud_firestore/cloud_firestore.dart'; // [cite: flutter/lib/pages/eventcreation.dart]
import 'package:flutter/services.dart'; // [cite: flutter/lib/pages/eventcreation.dart]
import 'package:intl/intl.dart'; // Import intl package for date formatting

// --- Constants --- (Copied from your provided code)
class _AppPaddings { // [cite: flutter/lib/pages/eventcreation.dart]
  static const EdgeInsets screen = EdgeInsets.all(16.0); // [cite: flutter/lib/pages/eventcreation.dart]
  static const EdgeInsets formField = EdgeInsets.symmetric(vertical: 8.0); // [cite: flutter/lib/pages/eventcreation.dart]
  static const EdgeInsets sectionSpacing = EdgeInsets.only(top: 16.0, bottom: 8.0); // [cite: flutter/lib/pages/eventcreation.dart]
  static const EdgeInsets button = EdgeInsets.symmetric(vertical: 12, horizontal: 24); // [cite: flutter/lib/pages/eventcreation.dart]
}

class _AppTextStyles { // [cite: flutter/lib/pages/eventcreation.dart]
  static const TextStyle button = TextStyle( // [cite: flutter/lib/pages/eventcreation.dart]
    fontSize: 18, // [cite: flutter/lib/pages/eventcreation.dart]
    fontWeight: FontWeight.bold, // [cite: flutter/lib/pages/eventcreation.dart]
    color: Colors.white, // [cite: flutter/lib/pages/eventcreation.dart]
  );
  static const TextStyle sectionHeader = TextStyle( // [cite: flutter/lib/pages/eventcreation.dart]
    fontSize: 18, // [cite: flutter/lib/pages/eventcreation.dart]
    fontWeight: FontWeight.bold, // [cite: flutter/lib/pages/eventcreation.dart]
    color: Colors.blueAccent, // [cite: flutter/lib/pages/eventcreation.dart]
  );
}

class _AppColors { // [cite: flutter/lib/pages/eventcreation.dart]
  static const Color primaryBackground = Colors.white; // [cite: flutter/lib/pages/eventcreation.dart]
  static const Color appBarBackground = Colors.white; // [cite: flutter/lib/pages/eventcreation.dart]
  static const Color appBarForeground = Colors.black; // [cite: flutter/lib/pages/eventcreation.dart]
  static const Color buttonBackground = Colors.red; // [cite: flutter/lib/pages/eventcreation.dart]
  static const Color buttonBorder = Colors.blueAccent; // [cite: flutter/lib/pages/eventcreation.dart]
}
// --- End Constants ---

class EventCreationPage extends StatefulWidget { // [cite: flutter/lib/pages/eventcreation.dart]
  const EventCreationPage({super.key}); // [cite: flutter/lib/pages/eventcreation.dart]

  @override
  _EventCreationPageState createState() => _EventCreationPageState(); // [cite: flutter/lib/pages/eventcreation.dart]
}

class _EventCreationPageState extends State<EventCreationPage> { // [cite: flutter/lib/pages/eventcreation.dart]
  final _formKey = GlobalKey<FormState>(); // [cite: flutter/lib/pages/eventcreation.dart]
  bool _isLoading = false; // [cite: flutter/lib/pages/eventcreation.dart]

  // --- Event Controllers ---
  final _eventIdController = TextEditingController(); // [cite: flutter/lib/pages/eventcreation.dart]
  final _nameController = TextEditingController(); // [cite: flutter/lib/pages/eventcreation.dart]
  final _locController = TextEditingController(); // [cite: flutter/lib/pages/eventcreation.dart]
  final _dateController = TextEditingController(); // Controller to DISPLAY the selected date // [cite: flutter/lib/pages/eventcreation.dart]
  final _slotnumController = TextEditingController(); // [cite: flutter/lib/pages/eventcreation.dart]

  // --- State variable to store the selected date ---
  DateTime? _selectedDate;

  // --- Artist Section State ---
  final _numofartistController = TextEditingController(); // [cite: flutter/lib/pages/eventcreation.dart]
  List<TextEditingController> _artistIdControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
  List<TextEditingController> _artistNameControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
  List<TextEditingController> _artistSlotControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
  int _currentNumArtists = 0; // [cite: flutter/lib/pages/eventcreation.dart]

  // --- Catering Section State ---
  final _numofcateringController = TextEditingController(); // [cite: flutter/lib/pages/eventcreation.dart]
  List<TextEditingController> _cateringController = []; // [cite: flutter/lib/pages/eventcreation.dart]
  int _currentNumCatering = 0; // [cite: flutter/lib/pages/eventcreation.dart]

  // --- Ticket Level Section State ---
  List<TextEditingController> _ticketLevelNameControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
  List<TextEditingController> _ticketLevelCountControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
  List<TextEditingController> _ticketLevelPriceControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]

  @override
  void initState() { // [cite: flutter/lib/pages/eventcreation.dart]
    super.initState();
    _addTicketLevel(); // Initialize with one ticket level row // [cite: flutter/lib/pages/eventcreation.dart]
  }

  @override
  void dispose() { // [cite: flutter/lib/pages/eventcreation.dart]
    // Dispose all controllers
    _eventIdController.dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _nameController.dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _locController.dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _dateController.dispose(); // Dispose the date controller // [cite: flutter/lib/pages/eventcreation.dart]
    _slotnumController.dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _numofartistController.dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _numofcateringController.dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _artistIdControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _artistNameControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _artistSlotControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _cateringController.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _ticketLevelNameControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _ticketLevelCountControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _ticketLevelPriceControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    super.dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
  }

  // --- Field Generation Logic for Artists ---
  void _generateArtistFields() { // [cite: flutter/lib/pages/eventcreation.dart]
    FocusScope.of(context).unfocus(); // [cite: flutter/lib/pages/eventcreation.dart]
    int? numArt = int.tryParse(_numofartistController.text); // [cite: flutter/lib/pages/eventcreation.dart]
    if (numArt == null || numArt < 0) { // Allow 0 artists
      _showSnackBar('Please enter a valid non-negative number of artists.');
      // Reset if invalid but allow 0
      if (numArt != 0) _numofartistController.clear();
      numArt = 0;
      // return; // Allow setting 0 artists
    }
    // Dispose old controllers
    _artistIdControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _artistNameControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    _artistSlotControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    // Create new controllers
    setState(() { // [cite: flutter/lib/pages/eventcreation.dart]
      _artistIdControllers = List.generate(numArt!, (_) => TextEditingController()); // [cite: flutter/lib/pages/eventcreation.dart]
      _artistNameControllers = List.generate(numArt, (_) => TextEditingController()); // [cite: flutter/lib/pages/eventcreation.dart]
      _artistSlotControllers = List.generate(numArt, (_) => TextEditingController()); // [cite: flutter/lib/pages/eventcreation.dart]
      _currentNumArtists = numArt; // [cite: flutter/lib/pages/eventcreation.dart]
    });
  }

  // --- Field Generation Logic for Catering ---
  void _generateCateringFields() { // [cite: flutter/lib/pages/eventcreation.dart]
    FocusScope.of(context).unfocus(); // [cite: flutter/lib/pages/eventcreation.dart]
    int? numCat = int.tryParse(_numofcateringController.text); // [cite: flutter/lib/pages/eventcreation.dart]
    if (numCat == null || numCat < 0) { // Allow 0 catering companies
      _showSnackBar('Please enter a valid non-negative number for catering companies.');
      if (numCat != 0) _numofcateringController.clear();
      numCat = 0;
      // return; // Allow setting 0
    }
    // Dispose old controllers
    _cateringController.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
    // Create new controllers
    setState(() { // [cite: flutter/lib/pages/eventcreation.dart]
      _cateringController = List.generate(numCat!, (_) => TextEditingController()); // [cite: flutter/lib/pages/eventcreation.dart]
      _currentNumCatering = numCat; // [cite: flutter/lib/pages/eventcreation.dart]
    });
  }

  // --- Ticket Level Field Management ---
  void _addTicketLevel() { // [cite: flutter/lib/pages/eventcreation.dart]
    setState(() { // [cite: flutter/lib/pages/eventcreation.dart]
      _ticketLevelNameControllers.add(TextEditingController()); // [cite: flutter/lib/pages/eventcreation.dart]
      _ticketLevelCountControllers.add(TextEditingController()); // [cite: flutter/lib/pages/eventcreation.dart]
      _ticketLevelPriceControllers.add(TextEditingController()); // [cite: flutter/lib/pages/eventcreation.dart]
    });
  }

  void _removeTicketLevel(int index) { // [cite: flutter/lib/pages/eventcreation.dart]
    _ticketLevelNameControllers[index].dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _ticketLevelCountControllers[index].dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    _ticketLevelPriceControllers[index].dispose(); // [cite: flutter/lib/pages/eventcreation.dart]
    setState(() { // [cite: flutter/lib/pages/eventcreation.dart]
      _ticketLevelNameControllers.removeAt(index); // [cite: flutter/lib/pages/eventcreation.dart]
      _ticketLevelCountControllers.removeAt(index); // [cite: flutter/lib/pages/eventcreation.dart]
      _ticketLevelPriceControllers.removeAt(index); // [cite: flutter/lib/pages/eventcreation.dart]
    });
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Allow today
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      // Manually trigger validation for the date field if needed immediately
      _formKey.currentState?.validate();
    }
  }

  // --- Form Submission Logic ---
  Future<void> _submitForm() async { // [cite: flutter/lib/pages/eventcreation.dart]
    // 1. Validate all form fields
    if (!_formKey.currentState!.validate()) { // [cite: flutter/lib/pages/eventcreation.dart]
      _showSnackBar('Please fix the errors in the form.'); // [cite: flutter/lib/pages/eventcreation.dart]
      return; // [cite: flutter/lib/pages/eventcreation.dart]
    }
    // Date is validated by its TextFormField validator checking _selectedDate

    // 2. Show Loading Indicator
    setState(() { _isLoading = true; }); // [cite: flutter/lib/pages/eventcreation.dart]

    final firestore = FirebaseFirestore.instance; // [cite: flutter/lib/pages/eventcreation.dart]
    final WriteBatch batch = firestore.batch(); // [cite: flutter/lib/pages/eventcreation.dart]

    try { // [cite: flutter/lib/pages/eventcreation.dart]
      // 3. Gather Event base data
      String eventId = _eventIdController.text.trim(); // [cite: flutter/lib/pages/eventcreation.dart]
      String eventName = _nameController.text.trim(); // [cite: flutter/lib/pages/eventcreation.dart]
      String eventLoc = _locController.text.trim(); // [cite: flutter/lib/pages/eventcreation.dart]
      int eventSlotnum = int.parse(_slotnumController.text.trim()); // [cite: flutter/lib/pages/eventcreation.dart]
      // Convert selected DateTime to Firestore Timestamp
      // The validator ensures _selectedDate is not null at this point
      Timestamp eventTimestamp = Timestamp.fromDate(_selectedDate!);

      // 3a. Gather Artist map data
      List<Map<String, dynamic>> artistsData = []; // [cite: flutter/lib/pages/eventcreation.dart]
      for (int i = 0; i < _currentNumArtists; i++) { // [cite: flutter/lib/pages/eventcreation.dart]
        // Validation now happens in the TextFormField's validator
        artistsData.add({ // [cite: flutter/lib/pages/eventcreation.dart]
          'artistID': _artistIdControllers[i].text.trim(), // [cite: flutter/lib/pages/eventcreation.dart]
          'name': _artistNameControllers[i].text.trim(), // [cite: flutter/lib/pages/eventcreation.dart]
          'slot': int.parse(_artistSlotControllers[i].text.trim()), // Parse validated string // [cite: flutter/lib/pages/eventcreation.dart]
        });
      }

      // 3b. Gather Catering map data
      List<Map<String, dynamic>> cateringData = []; // [cite: flutter/lib/pages/eventcreation.dart]
      for (int j = 0; j < _currentNumCatering; j++) { // [cite: flutter/lib/pages/eventcreation.dart]
        // Validation now happens in the TextFormField's validator
        cateringData.add({'CompName': _cateringController[j].text.trim()}); // [cite: flutter/lib/pages/eventcreation.dart]
      }

      // 3c. Gather and Validate Ticket Level definitions
      List<Map<String, dynamic>> ticketLevelsData = []; // [cite: flutter/lib/pages/eventcreation.dart]
      if (_ticketLevelNameControllers.isEmpty) { // [cite: flutter/lib/pages/eventcreation.dart]
        _showSnackBar('Please add at least one ticket level.'); // [cite: flutter/lib/pages/eventcreation.dart]
        setState(() { _isLoading = false; }); // [cite: flutter/lib/pages/eventcreation.dart]
        return; // [cite: flutter/lib/pages/eventcreation.dart]
      }
      for (int k = 0; k < _ticketLevelNameControllers.length; k++) { // [cite: flutter/lib/pages/eventcreation.dart]
        // Validation happens via TextFormField validators
        String levelName = _ticketLevelNameControllers[k].text.trim(); // [cite: flutter/lib/pages/eventcreation.dart]
        int ticketCount = int.parse(_ticketLevelCountControllers[k].text.trim()); // Use validated string // [cite: flutter/lib/pages/eventcreation.dart]
        double ticketPrice = double.parse(_ticketLevelPriceControllers[k].text.trim()); // Use validated string // [cite: flutter/lib/pages/eventcreation.dart]
        ticketLevelsData.add({ // [cite: flutter/lib/pages/eventcreation.dart]
          'levelName': levelName, // [cite: flutter/lib/pages/eventcreation.dart]
          'count': ticketCount, // [cite: flutter/lib/pages/eventcreation.dart]
          'price': ticketPrice, // [cite: flutter/lib/pages/eventcreation.dart]
        });
      }

      // 4. Prepare Event Document Data for Firestore
      Map<String, dynamic> eventDocData = { // [cite: flutter/lib/pages/eventcreation.dart]
        'eventId': eventId, // [cite: flutter/lib/pages/eventcreation.dart]
        'name': eventName, // [cite: flutter/lib/pages/eventcreation.dart]
        'loc': eventLoc, // [cite: flutter/lib/pages/eventcreation.dart]
        'eventDate': eventTimestamp, // Added event date
        'slotnum': eventSlotnum, // [cite: flutter/lib/pages/eventcreation.dart]
        'artists': artistsData, // [cite: flutter/lib/pages/eventcreation.dart]
        'catering': cateringData, // [cite: flutter/lib/pages/eventcreation.dart]
        'ticketLevels': ticketLevelsData, // [cite: flutter/lib/pages/eventcreation.dart]
        'createdAt': FieldValue.serverTimestamp(), // [cite: flutter/lib/pages/eventcreation.dart]
      };

      // 5. Add Event Document creation to the batch
      DocumentReference eventRef = firestore.collection('events').doc(eventId); // [cite: flutter/lib/pages/eventcreation.dart]
      batch.set(eventRef, eventDocData); // [cite: flutter/lib/pages/eventcreation.dart]

      // 6. Generate and Add Individual Ticket Documents to the batch
      for (var level in ticketLevelsData) { // [cite: flutter/lib/pages/eventcreation.dart]
        String levelName = level['levelName']; // [cite: flutter/lib/pages/eventcreation.dart]
        int count = level['count']; // [cite: flutter/lib/pages/eventcreation.dart]
        double price = level['price']; // [cite: flutter/lib/pages/eventcreation.dart]
        String levelNameFormatted = levelName.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w-]'), ''); // [cite: flutter/lib/pages/eventcreation.dart]

        for (int i = 1; i <= count; i++) { // [cite: flutter/lib/pages/eventcreation.dart]
          String ticketId = '$eventId-${levelNameFormatted.toUpperCase()}-${i.toString().padLeft(4, '0')}'; // Pad for sorting, maybe uppercase level // [cite: flutter/lib/pages/eventcreation.dart]
          Ticket newTicket = Ticket( // Use updated Ticket model // [cite: flutter/lib/pages/eventcreation.dart]
            ticketId: ticketId,
            eventId: eventId,
            levelName: levelName,
            price: price,
            status: 'available', // Initial status
            // userId and purchaseTimestamp are null by default
          );
          DocumentReference ticketRef = firestore.collection('tickets').doc(ticketId); // [cite: flutter/lib/pages/eventcreation.dart]
          batch.set(ticketRef, newTicket.toMap()); // Use toMap from model // [cite: flutter/lib/pages/eventcreation.dart]
        }
      }

      // 7. Commit the Batch
      await batch.commit(); // [cite: flutter/lib/pages/eventcreation.dart]

      _showSnackBar('Event and Tickets successfully created!', isError: false); // [cite: flutter/lib/pages/eventcreation.dart]

      // 8. Clear the form and reset state
      _formKey.currentState?.reset(); // [cite: flutter/lib/pages/eventcreation.dart]
      setState(() { // [cite: flutter/lib/pages/eventcreation.dart]
        _eventIdController.clear(); // Clear standard controllers too
        _nameController.clear();
        _locController.clear();
        _dateController.clear();
        _slotnumController.clear();
        _selectedDate = null;
        // Dispose and clear artist controllers
        _artistIdControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
        _artistNameControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
        _artistSlotControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
        _numofartistController.clear(); // [cite: flutter/lib/pages/eventcreation.dart]
        _artistIdControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
        _artistNameControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
        _artistSlotControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
        _currentNumArtists = 0; // [cite: flutter/lib/pages/eventcreation.dart]
        // Dispose and clear catering controllers
        _cateringController.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
        _numofcateringController.clear(); // [cite: flutter/lib/pages/eventcreation.dart]
        _cateringController = []; // [cite: flutter/lib/pages/eventcreation.dart]
        _currentNumCatering = 0; // [cite: flutter/lib/pages/eventcreation.dart]
        // Dispose and clear ticket level controllers
        _ticketLevelNameControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
        _ticketLevelCountControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
        _ticketLevelPriceControllers.forEach((c) => c.dispose()); // [cite: flutter/lib/pages/eventcreation.dart]
        _ticketLevelNameControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
        _ticketLevelCountControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
        _ticketLevelPriceControllers = []; // [cite: flutter/lib/pages/eventcreation.dart]
        // Add back one empty ticket level row
        _addTicketLevel(); // [cite: flutter/lib/pages/eventcreation.dart]
      });

    } catch (error) { // [cite: flutter/lib/pages/eventcreation.dart]
      print("Error during submission: $error"); // [cite: flutter/lib/pages/eventcreation.dart]
      _showSnackBar('Failed to create event/tickets: ${error.toString()}'); // [cite: flutter/lib/pages/eventcreation.dart]
    } finally { // [cite: flutter/lib/pages/eventcreation.dart]
      // 9. Reset loading state
      if (mounted) { setState(() { _isLoading = false; }); } // [cite: flutter/lib/pages/eventcreation.dart]
    }
  }

  // --- UI Helper Methods ---
  void _showSnackBar(String message, {bool isError = true}) { // [cite: flutter/lib/pages/eventcreation.dart]
    if (!mounted) return; // [cite: flutter/lib/pages/eventcreation.dart]
    ScaffoldMessenger.of(context).showSnackBar( // [cite: flutter/lib/pages/eventcreation.dart]
      SnackBar( // [cite: flutter/lib/pages/eventcreation.dart]
        content: Text(message), // [cite: flutter/lib/pages/eventcreation.dart]
        backgroundColor: isError ? Colors.redAccent : Colors.green, // [cite: flutter/lib/pages/eventcreation.dart]
      ),
    );
  }

  Widget _buildSectionHeader(String title) { // [cite: flutter/lib/pages/eventcreation.dart]
    return Padding( // [cite: flutter/lib/pages/eventcreation.dart]
      padding: _AppPaddings.sectionSpacing, // [cite: flutter/lib/pages/eventcreation.dart]
      child: Text(title, style: _AppTextStyles.sectionHeader), // [cite: flutter/lib/pages/eventcreation.dart]
    );
  }

  // Modified TextFormField builder to accept readOnly and onTap
  Widget _buildTextFormField({ // [cite: flutter/lib/pages/eventcreation.dart]
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false, // Added parameter
    VoidCallback? onTap,    // Added parameter
    Widget? suffixIcon,    // Added parameter
    String? hintText,     // Added hintText
  }) {
    return Padding( // [cite: flutter/lib/pages/eventcreation.dart]
      padding: _AppPaddings.formField, // [cite: flutter/lib/pages/eventcreation.dart]
      child: TextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
        controller: controller, // [cite: flutter/lib/pages/eventcreation.dart]
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration( // [cite: flutter/lib/pages/eventcreation.dart]
          labelText: label, // [cite: flutter/lib/pages/eventcreation.dart]
          hintText: hintText, // Use hintText
          suffixIcon: suffixIcon,
          border: OutlineInputBorder( // [cite: flutter/lib/pages/eventcreation.dart]
            borderRadius: BorderRadius.circular(8.0), // [cite: flutter/lib/pages/eventcreation.dart]
          ),
          filled: true, // [cite: flutter/lib/pages/eventcreation.dart]
          fillColor: Colors.grey[50], // [cite: flutter/lib/pages/eventcreation.dart]
        ),
        keyboardType: keyboardType, // [cite: flutter/lib/pages/eventcreation.dart]
        validator: validator ?? (value) { // Default non-empty validator // [cite: flutter/lib/pages/eventcreation.dart]
          if (value == null || value.trim().isEmpty) { // [cite: flutter/lib/pages/eventcreation.dart]
            // Use the label in the default error message
            return 'Please enter $label'; // [cite: flutter/lib/pages/eventcreation.dart]
          }
          return null; // [cite: flutter/lib/pages/eventcreation.dart]
        },
        maxLines: maxLines, // [cite: flutter/lib/pages/eventcreation.dart]
        inputFormatters: inputFormatters, // [cite: flutter/lib/pages/eventcreation.dart]
        autovalidateMode: AutovalidateMode.onUserInteraction, // [cite: flutter/lib/pages/eventcreation.dart]
      ),
    );
  }

  String? _validatePositiveInt(String? value, String fieldName) { // [cite: flutter/lib/pages/eventcreation.dart]
    if (value == null || value.trim().isEmpty) { // [cite: flutter/lib/pages/eventcreation.dart]
      return 'Please enter $fieldName'; // [cite: flutter/lib/pages/eventcreation.dart]
    }
    final number = int.tryParse(value.trim()); // [cite: flutter/lib/pages/eventcreation.dart]
    if (number == null) { // [cite: flutter/lib/pages/eventcreation.dart]
      return 'Please enter a valid integer'; // [cite: flutter/lib/pages/eventcreation.dart]
    }
    if (number <= 0) { // [cite: flutter/lib/pages/eventcreation.dart]
      return 'Please enter a positive integer'; // [cite: flutter/lib/pages/eventcreation.dart]
    }
    return null; // [cite: flutter/lib/pages/eventcreation.dart]
  }

  String? _validateNonNegativeNumber(String? value, String fieldName) { // [cite: flutter/lib/pages/eventcreation.dart]
    if (value == null || value.trim().isEmpty) { // [cite: flutter/lib/pages/eventcreation.dart]
      return 'Please enter $fieldName'; // [cite: flutter/lib/pages/eventcreation.dart]
    }
    final number = double.tryParse(value.trim()); // [cite: flutter/lib/pages/eventcreation.dart]
    if (number == null) { // [cite: flutter/lib/pages/eventcreation.dart]
      return 'Please enter a valid number'; // [cite: flutter/lib/pages/eventcreation.dart]
    }
    if (number < 0) { // [cite: flutter/lib/pages/eventcreation.dart]
      return 'Please enter a non-negative number'; // [cite: flutter/lib/pages/eventcreation.dart]
    }
    return null; // [cite: flutter/lib/pages/eventcreation.dart]
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) { // [cite: flutter/lib/pages/eventcreation.dart]
    return Scaffold( // [cite: flutter/lib/pages/eventcreation.dart]
      backgroundColor: _AppColors.primaryBackground, // [cite: flutter/lib/pages/eventcreation.dart]
      appBar: AppBar( // [cite: flutter/lib/pages/eventcreation.dart]
        backgroundColor: _AppColors.appBarBackground, // [cite: flutter/lib/pages/eventcreation.dart]
        elevation: 1, // [cite: flutter/lib/pages/eventcreation.dart]
        leading: IconButton( // [cite: flutter/lib/pages/eventcreation.dart]
          icon: Icon(Icons.arrow_back, color: _AppColors.appBarForeground), // [cite: flutter/lib/pages/eventcreation.dart]
          onPressed: () => Navigator.pop(context), // [cite: flutter/lib/pages/eventcreation.dart]
        ),
        title: Text( // [cite: flutter/lib/pages/eventcreation.dart]
          "Create Event",
          style: TextStyle(color: _AppColors.appBarForeground), // [cite: flutter/lib/pages/eventcreation.dart]
        ),
        centerTitle: true, // [cite: flutter/lib/pages/eventcreation.dart]
      ),
      body: Padding( // [cite: flutter/lib/pages/eventcreation.dart]
        padding: _AppPaddings.screen, // [cite: flutter/lib/pages/eventcreation.dart]
        child: Form( // [cite: flutter/lib/pages/eventcreation.dart]
          key: _formKey, // [cite: flutter/lib/pages/eventcreation.dart]
          child: ListView( // Use ListView for scrolling // [cite: flutter/lib/pages/eventcreation.dart]
            children: [
              _buildEventDetailsSection(), // Includes date field now // [cite: flutter/lib/pages/eventcreation.dart]
              const Divider(height: 30, thickness: 1), // [cite: flutter/lib/pages/eventcreation.dart]
              _buildArtistSection(), // [cite: flutter/lib/pages/eventcreation.dart]
              const Divider(height: 30, thickness: 1), // [cite: flutter/lib/pages/eventcreation.dart]
              _buildCateringSection(), // [cite: flutter/lib/pages/eventcreation.dart]
              const Divider(height: 30, thickness: 1), // [cite: flutter/lib/pages/eventcreation.dart]
              _buildTicketLevelsSection(), // Section for tickets // [cite: flutter/lib/pages/eventcreation.dart]
              const SizedBox(height: 30), // [cite: flutter/lib/pages/eventcreation.dart]
              _buildSubmitButton(), // [cite: flutter/lib/pages/eventcreation.dart]
              const SizedBox(height: 20), // Space at the bottom // [cite: flutter/lib/pages/eventcreation.dart]
            ],
          ),
        ),
      ),
    );
  }

  // --- Section Builder Methods ---

  Widget _buildEventDetailsSection() { // [cite: flutter/lib/pages/eventcreation.dart]
    // Builds the UI section for basic event details including the date picker
    return Column( // [cite: flutter/lib/pages/eventcreation.dart]
      crossAxisAlignment: CrossAxisAlignment.start, // [cite: flutter/lib/pages/eventcreation.dart]
      children: [ // [cite: flutter/lib/pages/eventcreation.dart]
        _buildSectionHeader("Event Details"), // [cite: flutter/lib/pages/eventcreation.dart]
        _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
          controller: _eventIdController, // [cite: flutter/lib/pages/eventcreation.dart]
          label: "Event ID (Unique)", // [cite: flutter/lib/pages/eventcreation.dart]
          validator: (value) { // [cite: flutter/lib/pages/eventcreation.dart]
            if (value == null || value.trim().isEmpty) { return 'Please enter a unique Event ID'; } // [cite: flutter/lib/pages/eventcreation.dart]
            return null; // [cite: flutter/lib/pages/eventcreation.dart]
          },
        ),
        _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
          controller: _nameController, // [cite: flutter/lib/pages/eventcreation.dart]
          label: "Event Name", // [cite: flutter/lib/pages/eventcreation.dart]
        ),
        _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
          controller: _locController, // [cite: flutter/lib/pages/eventcreation.dart]
          label: "Event Location", // [cite: flutter/lib/pages/eventcreation.dart]
        ),
        // --- Date Picker TextFormField ---
        _buildTextFormField(
          controller: _dateController, // Displays formatted date
          readOnly: true, // Prevents manual text input
          label: "Event Date",
          hintText: _selectedDate == null ? "Select Date" : null, // Show hint only if empty
          suffixIcon: const Icon(Icons.calendar_today_outlined), // Calendar Icon
          onTap: () => _selectDate(context), // Open picker on tap
          validator: (value) {
            // Validate based on the _selectedDate state variable
            if (_selectedDate == null) {
              return 'Please select an event date';
            }
            return null;
          },
        ),
        // -----------------------------
        _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
          controller: _slotnumController, // [cite: flutter/lib/pages/eventcreation.dart]
          label: "Event Capacity", // Clarified label // [cite: flutter/lib/pages/eventcreation.dart]
          keyboardType: TextInputType.number, // [cite: flutter/lib/pages/eventcreation.dart]
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // [cite: flutter/lib/pages/eventcreation.dart]
          validator: (value) => _validatePositiveInt(value, 'Event Capacity'), // [cite: flutter/lib/pages/eventcreation.dart]
        ),
      ],
    );
  }

  Widget _buildArtistSection() { // [cite: flutter/lib/pages/eventcreation.dart]
    // Builds the UI section for adding artists dynamically
    return Column( // [cite: flutter/lib/pages/eventcreation.dart]
      crossAxisAlignment: CrossAxisAlignment.start, // [cite: flutter/lib/pages/eventcreation.dart]
      children: [ // [cite: flutter/lib/pages/eventcreation.dart]
        _buildSectionHeader("Artists (Optional)"), // [cite: flutter/lib/pages/eventcreation.dart]
        Row( // [cite: flutter/lib/pages/eventcreation.dart]
          crossAxisAlignment: CrossAxisAlignment.start, // [cite: flutter/lib/pages/eventcreation.dart]
          children: [ // [cite: flutter/lib/pages/eventcreation.dart]
            Expanded( // [cite: flutter/lib/pages/eventcreation.dart]
              child: _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                  controller: _numofartistController, // [cite: flutter/lib/pages/eventcreation.dart]
                  label: "Number of Artists", // [cite: flutter/lib/pages/eventcreation.dart]
                  keyboardType: TextInputType.number, // [cite: flutter/lib/pages/eventcreation.dart]
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // [cite: flutter/lib/pages/eventcreation.dart]
                  validator: (value) { // Allow 0 // [cite: flutter/lib/pages/eventcreation.dart]
                    if (value == null || value.trim().isEmpty) return null; // [cite: flutter/lib/pages/eventcreation.dart]
                    final number = int.tryParse(value.trim()); // [cite: flutter/lib/pages/eventcreation.dart]
                    if (number == null) return 'Enter a valid number'; // [cite: flutter/lib/pages/eventcreation.dart]
                    if (number < 0) return 'Enter a non-negative number'; // [cite: flutter/lib/pages/eventcreation.dart]
                    return null; // [cite: flutter/lib/pages/eventcreation.dart]
                  }
              ),
            ),
            Padding( // [cite: flutter/lib/pages/eventcreation.dart]
              padding: const EdgeInsets.only(left: 8.0, top: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
              child: ElevatedButton( // [cite: flutter/lib/pages/eventcreation.dart]
                onPressed: _generateArtistFields, // [cite: flutter/lib/pages/eventcreation.dart]
                child: const Text("Set"), // [cite: flutter/lib/pages/eventcreation.dart]
              ),
            ),
          ],
        ),
        // Dynamically generate artist fields
        if (_currentNumArtists > 0) // [cite: flutter/lib/pages/eventcreation.dart]
          ListView.builder( // [cite: flutter/lib/pages/eventcreation.dart]
            shrinkWrap: true, // [cite: flutter/lib/pages/eventcreation.dart]
            physics: const NeverScrollableScrollPhysics(), // [cite: flutter/lib/pages/eventcreation.dart]
            itemCount: _currentNumArtists, // [cite: flutter/lib/pages/eventcreation.dart]
            itemBuilder: (context, index) => Card( // [cite: flutter/lib/pages/eventcreation.dart]
              margin: const EdgeInsets.symmetric(vertical: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
              elevation: 2.0, // [cite: flutter/lib/pages/eventcreation.dart]
              child: Padding( // [cite: flutter/lib/pages/eventcreation.dart]
                padding: const EdgeInsets.all(12.0), // [cite: flutter/lib/pages/eventcreation.dart]
                child: Column( // [cite: flutter/lib/pages/eventcreation.dart]
                  crossAxisAlignment: CrossAxisAlignment.start, // [cite: flutter/lib/pages/eventcreation.dart]
                  children: [ // [cite: flutter/lib/pages/eventcreation.dart]
                    Text("Artist ${index + 1}", style: Theme.of(context).textTheme.titleMedium), // [cite: flutter/lib/pages/eventcreation.dart]
                    const SizedBox(height: 8), // [cite: flutter/lib/pages/eventcreation.dart]
                    _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                      controller: _artistIdControllers[index], // [cite: flutter/lib/pages/eventcreation.dart]
                      label: "Artist ID", // [cite: flutter/lib/pages/eventcreation.dart]
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter Artist ID' : null, // [cite: flutter/lib/pages/eventcreation.dart]
                    ),
                    _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                      controller: _artistNameControllers[index], // [cite: flutter/lib/pages/eventcreation.dart]
                      label: "Artist Name", // [cite: flutter/lib/pages/eventcreation.dart]
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter Artist Name' : null, // [cite: flutter/lib/pages/eventcreation.dart]
                    ),
                    _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                      controller: _artistSlotControllers[index], // [cite: flutter/lib/pages/eventcreation.dart]
                      label: "Artist Slot", // [cite: flutter/lib/pages/eventcreation.dart]
                      keyboardType: TextInputType.number, // [cite: flutter/lib/pages/eventcreation.dart]
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // [cite: flutter/lib/pages/eventcreation.dart]
                      validator: (value) => _validatePositiveInt(value, 'Artist Slot'), // [cite: flutter/lib/pages/eventcreation.dart]
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_numofartistController.text.isNotEmpty && int.tryParse(_numofartistController.text) == 0) // [cite: flutter/lib/pages/eventcreation.dart]
          const Padding( // [cite: flutter/lib/pages/eventcreation.dart]
              padding: EdgeInsets.only(top: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
              child: Text('No artist fields to add.', style: TextStyle(color: Colors.grey)) // [cite: flutter/lib/pages/eventcreation.dart]
          )
        else if (_numofartistController.text.isNotEmpty) // [cite: flutter/lib/pages/eventcreation.dart]
            Padding( // [cite: flutter/lib/pages/eventcreation.dart]
                padding: const EdgeInsets.only(top: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
                child: Text('Press "Set" to add artist fields.', style: TextStyle(color: Colors.grey[600])) // [cite: flutter/lib/pages/eventcreation.dart]
            ),
      ],
    );
  }

  Widget _buildCateringSection() { // [cite: flutter/lib/pages/eventcreation.dart]
    // Builds the UI section for adding catering companies dynamically
    return Column( // [cite: flutter/lib/pages/eventcreation.dart]
      crossAxisAlignment: CrossAxisAlignment.start, // [cite: flutter/lib/pages/eventcreation.dart]
      children: [ // [cite: flutter/lib/pages/eventcreation.dart]
        _buildSectionHeader("Catering (Optional)"), // [cite: flutter/lib/pages/eventcreation.dart]
        Row( // [cite: flutter/lib/pages/eventcreation.dart]
          crossAxisAlignment: CrossAxisAlignment.start, // [cite: flutter/lib/pages/eventcreation.dart]
          children: [ // [cite: flutter/lib/pages/eventcreation.dart]
            Expanded( // [cite: flutter/lib/pages/eventcreation.dart]
              child:_buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                  controller: _numofcateringController, // [cite: flutter/lib/pages/eventcreation.dart]
                  label: "Number of Catering Companies", // [cite: flutter/lib/pages/eventcreation.dart]
                  keyboardType: TextInputType.number, // [cite: flutter/lib/pages/eventcreation.dart]
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // [cite: flutter/lib/pages/eventcreation.dart]
                  validator: (value) { // Allow 0 // [cite: flutter/lib/pages/eventcreation.dart]
                    if (value == null || value.trim().isEmpty) return null; // [cite: flutter/lib/pages/eventcreation.dart]
                    final number = int.tryParse(value.trim()); // [cite: flutter/lib/pages/eventcreation.dart]
                    if (number == null) return 'Enter a valid number'; // [cite: flutter/lib/pages/eventcreation.dart]
                    if (number < 0) return 'Enter a non-negative number'; // [cite: flutter/lib/pages/eventcreation.dart]
                    return null; // [cite: flutter/lib/pages/eventcreation.dart]
                  }
              ),
            ),
            Padding( // [cite: flutter/lib/pages/eventcreation.dart]
              padding: const EdgeInsets.only(left: 8.0, top: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
              child: ElevatedButton( // [cite: flutter/lib/pages/eventcreation.dart]
                onPressed: _generateCateringFields, // [cite: flutter/lib/pages/eventcreation.dart]
                child: const Text("Set"), // [cite: flutter/lib/pages/eventcreation.dart]
              ),
            ),
          ],
        ),
        // Dynamically generate catering fields
        if (_currentNumCatering > 0) // [cite: flutter/lib/pages/eventcreation.dart]
          ListView.builder( // [cite: flutter/lib/pages/eventcreation.dart]
            shrinkWrap: true, // [cite: flutter/lib/pages/eventcreation.dart]
            physics: const NeverScrollableScrollPhysics(), // [cite: flutter/lib/pages/eventcreation.dart]
            itemCount: _currentNumCatering, // [cite: flutter/lib/pages/eventcreation.dart]
            itemBuilder: (context, index) => _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
              controller: _cateringController[index], // [cite: flutter/lib/pages/eventcreation.dart]
              label: "Catering Company ${index + 1} Name", // [cite: flutter/lib/pages/eventcreation.dart]
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter Company Name' : null, // [cite: flutter/lib/pages/eventcreation.dart]
            ),
          )
        else if (_numofcateringController.text.isNotEmpty && int.tryParse(_numofcateringController.text) == 0) // [cite: flutter/lib/pages/eventcreation.dart]
          const Padding( // [cite: flutter/lib/pages/eventcreation.dart]
              padding: EdgeInsets.only(top: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
              child: Text('No catering fields to add.', style: TextStyle(color: Colors.grey)) // [cite: flutter/lib/pages/eventcreation.dart]
          )
        else if (_numofcateringController.text.isNotEmpty) // [cite: flutter/lib/pages/eventcreation.dart]
            Padding( // [cite: flutter/lib/pages/eventcreation.dart]
                padding: const EdgeInsets.only(top: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
                child: Text('Press "Set" to add catering fields.', style: TextStyle(color: Colors.grey[600])) // [cite: flutter/lib/pages/eventcreation.dart]
            ),
      ],
    );
  }

  Widget _buildTicketLevelsSection() { // [cite: flutter/lib/pages/eventcreation.dart]
    // Builds the UI section for adding ticket levels dynamically
    return Column( // [cite: flutter/lib/pages/eventcreation.dart]
      crossAxisAlignment: CrossAxisAlignment.start, // [cite: flutter/lib/pages/eventcreation.dart]
      children: [ // [cite: flutter/lib/pages/eventcreation.dart]
        _buildSectionHeader("Ticket Levels"), // [cite: flutter/lib/pages/eventcreation.dart]
        if (_ticketLevelNameControllers.isEmpty) // [cite: flutter/lib/pages/eventcreation.dart]
          const Padding( // [cite: flutter/lib/pages/eventcreation.dart]
            padding: EdgeInsets.symmetric(vertical: 16.0), // [cite: flutter/lib/pages/eventcreation.dart]
            child: Center(child: Text("Click 'Add Ticket Level' to start.")), // [cite: flutter/lib/pages/eventcreation.dart]
          )
        else
          ListView.builder( // [cite: flutter/lib/pages/eventcreation.dart]
            shrinkWrap: true, // [cite: flutter/lib/pages/eventcreation.dart]
            physics: const NeverScrollableScrollPhysics(), // [cite: flutter/lib/pages/eventcreation.dart]
            itemCount: _ticketLevelNameControllers.length, // [cite: flutter/lib/pages/eventcreation.dart]
            itemBuilder: (context, index) { // [cite: flutter/lib/pages/eventcreation.dart]
              return Card( // [cite: flutter/lib/pages/eventcreation.dart]
                margin: const EdgeInsets.symmetric(vertical: 8.0), // [cite: flutter/lib/pages/eventcreation.dart]
                elevation: 2.0, // [cite: flutter/lib/pages/eventcreation.dart]
                child: Padding( // [cite: flutter/lib/pages/eventcreation.dart]
                  padding: const EdgeInsets.all(12.0), // [cite: flutter/lib/pages/eventcreation.dart]
                  child: Column( // [cite: flutter/lib/pages/eventcreation.dart]
                    children: [ // [cite: flutter/lib/pages/eventcreation.dart]
                      Row( // [cite: flutter/lib/pages/eventcreation.dart]
                        children: [ // [cite: flutter/lib/pages/eventcreation.dart]
                          Expanded(child: Text("Level ${index + 1}", style: Theme.of(context).textTheme.titleMedium)), // [cite: flutter/lib/pages/eventcreation.dart]
                          if (_ticketLevelNameControllers.length > 1) // [cite: flutter/lib/pages/eventcreation.dart]
                            IconButton( // [cite: flutter/lib/pages/eventcreation.dart]
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red), // [cite: flutter/lib/pages/eventcreation.dart]
                              tooltip: 'Remove Level ${index + 1}', // [cite: flutter/lib/pages/eventcreation.dart]
                              onPressed: () => _removeTicketLevel(index), // [cite: flutter/lib/pages/eventcreation.dart]
                            )
                          else // [cite: flutter/lib/pages/eventcreation.dart]
                            const SizedBox(width: 48), // [cite: flutter/lib/pages/eventcreation.dart]
                        ],
                      ),
                      const SizedBox(height: 8), // [cite: flutter/lib/pages/eventcreation.dart]
                      _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                        controller: _ticketLevelNameControllers[index], // [cite: flutter/lib/pages/eventcreation.dart]
                        label: "Level Name (e.g., VIP, Standard)", // [cite: flutter/lib/pages/eventcreation.dart]
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter level name' : null, // [cite: flutter/lib/pages/eventcreation.dart]
                      ),
                      _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                        controller: _ticketLevelCountControllers[index], // [cite: flutter/lib/pages/eventcreation.dart]
                        label: "Number of Tickets", // [cite: flutter/lib/pages/eventcreation.dart]
                        keyboardType: TextInputType.number, // [cite: flutter/lib/pages/eventcreation.dart]
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // [cite: flutter/lib/pages/eventcreation.dart]
                        validator: (value) => _validatePositiveInt(value, 'Number of Tickets'), // [cite: flutter/lib/pages/eventcreation.dart]
                      ),
                      _buildTextFormField( // [cite: flutter/lib/pages/eventcreation.dart]
                        controller: _ticketLevelPriceControllers[index], // [cite: flutter/lib/pages/eventcreation.dart]
                        label: "Price per Ticket (\$)", // [cite: flutter/lib/pages/eventcreation.dart]
                        keyboardType: const TextInputType.numberWithOptions(decimal: true), // [cite: flutter/lib/pages/eventcreation.dart]
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], // [cite: flutter/lib/pages/eventcreation.dart]
                        validator: (value) => _validateNonNegativeNumber(value, 'Price'), // [cite: flutter/lib/pages/eventcreation.dart]
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16), // [cite: flutter/lib/pages/eventcreation.dart]
        Center( // [cite: flutter/lib/pages/eventcreation.dart]
          child: ElevatedButton.icon( // [cite: flutter/lib/pages/eventcreation.dart]
            icon: const Icon(Icons.add_circle_outline), // [cite: flutter/lib/pages/eventcreation.dart]
            label: const Text("Add Another Ticket Level"), // [cite: flutter/lib/pages/eventcreation.dart]
            style: ElevatedButton.styleFrom( // [cite: flutter/lib/pages/eventcreation.dart]
              backgroundColor: Colors.grey[200], // [cite: flutter/lib/pages/eventcreation.dart]
              foregroundColor: Colors.black87, // [cite: flutter/lib/pages/eventcreation.dart]
            ),
            onPressed: _addTicketLevel, // [cite: flutter/lib/pages/eventcreation.dart]
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() { // [cite: flutter/lib/pages/eventcreation.dart]
    // Builds the final submit button
    return ElevatedButton( // [cite: flutter/lib/pages/eventcreation.dart]
      onPressed: _isLoading ? null : _submitForm, // Disable when loading // [cite: flutter/lib/pages/eventcreation.dart]
      style: ElevatedButton.styleFrom( // [cite: flutter/lib/pages/eventcreation.dart]
        backgroundColor: _AppColors.buttonBackground, // Use defined color // [cite: flutter/lib/pages/eventcreation.dart]
        padding: _AppPaddings.button, // Use defined padding
        shape: RoundedRectangleBorder( // Use defined radius
            borderRadius: BorderRadius.circular(12) // Assuming _AppRadius.buttonRadius was 12
        ),
        elevation: 5, // [cite: flutter/lib/pages/eventcreation.dart]
        side: const BorderSide( // [cite: flutter/lib/pages/eventcreation.dart]
          color: _AppColors.buttonBorder, // [cite: flutter/lib/pages/eventcreation.dart]
          width: 2, // [cite: flutter/lib/pages/eventcreation.dart]
        ),
      ),
      child: _isLoading // [cite: flutter/lib/pages/eventcreation.dart]
          ? const SizedBox( // Show loading indicator when _isLoading is true // [cite: flutter/lib/pages/eventcreation.dart]
        width: 24, // [cite: flutter/lib/pages/eventcreation.dart]
        height: 24, // [cite: flutter/lib/pages/eventcreation.dart]
        child: CircularProgressIndicator( // [cite: flutter/lib/pages/eventcreation.dart]
          color: Colors.white, // [cite: flutter/lib/pages/eventcreation.dart]
          strokeWidth: 3, // [cite: flutter/lib/pages/eventcreation.dart]
        ),
      )
          : const Text( // Show button text otherwise // [cite: flutter/lib/pages/eventcreation.dart]
        'Create Event & Generate Tickets', // Updated text
        style: _AppTextStyles.button, // [cite: flutter/lib/pages/eventcreation.dart]
      ),
    );
  }
} // End of _EventCreationPageState class