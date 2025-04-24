// lib/pages/eventcreation.dart

import 'package:flutter/material.dart';
// Ensure your module paths are correct
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:eventmangment/modules/tickets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Needed for DateFormat

// --- Constants ---
class _AppPaddings {
  static const EdgeInsets screen = EdgeInsets.all(16.0);
  static const EdgeInsets formField = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets sectionSpacing = EdgeInsets.only(top: 16.0, bottom: 8.0);
  static const EdgeInsets button = EdgeInsets.symmetric(vertical: 12, horizontal: 24);
}

class _AppTextStyles {
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent,
  );
}

class _AppColors {
  static const Color primaryBackground = Colors.white;
  static const Color appBarBackground = Colors.white;
  static const Color appBarForeground = Colors.black;
  static const Color buttonBackground = Colors.red; // Or your preferred color
  static const Color buttonBorder = Colors.blueAccent; // Or your preferred color
}
// --- End Constants ---

class EventCreationPage extends StatefulWidget {
  const EventCreationPage({super.key});

  @override
  _EventCreationPageState createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Event Controllers ---
  final _eventIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _locController = TextEditingController();
  final _dateController = TextEditingController(); // Controller to DISPLAY the selected date
  final _slotnumController = TextEditingController();

  // --- State variable to store the selected date ---
  DateTime? _selectedDate;

  // --- Artist Section State ---
  final _numofartistController = TextEditingController();
  List<TextEditingController> _artistIdControllers = [];
  List<TextEditingController> _artistNameControllers = [];
  List<TextEditingController> _artistSlotControllers = [];
  int _currentNumArtists = 0;

  // --- Catering Section State ---
  final _numofcateringController = TextEditingController();
  List<TextEditingController> _cateringController = [];
  int _currentNumCatering = 0;

  // --- Ticket Level Section State ---
  List<TextEditingController> _ticketLevelNameControllers = [];
  List<TextEditingController> _ticketLevelCountControllers = [];
  List<TextEditingController> _ticketLevelPriceControllers = [];

  @override
  void initState() {
    super.initState();
    // Start with one ticket level row by default
    _addTicketLevel();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _eventIdController.dispose();
    _nameController.dispose();
    _locController.dispose();
    _dateController.dispose();
    _slotnumController.dispose();
    _numofartistController.dispose();
    _numofcateringController.dispose();
    _artistIdControllers.forEach((c) => c.dispose());
    _artistNameControllers.forEach((c) => c.dispose());
    _artistSlotControllers.forEach((c) => c.dispose());
    _cateringController.forEach((c) => c.dispose());
    _ticketLevelNameControllers.forEach((c) => c.dispose());
    _ticketLevelCountControllers.forEach((c) => c.dispose());
    _ticketLevelPriceControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- Field Generation Logic for Artists ---
  void _generateArtistFields() {
    FocusScope.of(context).unfocus();
    int? numArt = int.tryParse(_numofartistController.text);
    if (numArt == null || numArt < 0) {
      _showSnackBar('Please enter a valid non-negative number of artists.');
      if (numArt != 0) _numofartistController.clear();
      numArt = 0;
    }
    // Dispose old controllers
    _artistIdControllers.forEach((c) => c.dispose());
    _artistNameControllers.forEach((c) => c.dispose());
    _artistSlotControllers.forEach((c) => c.dispose());
    // Create new controllers
    if (!mounted) return;
    setState(() {
      _artistIdControllers = List.generate(numArt!, (_) => TextEditingController());
      _artistNameControllers = List.generate(numArt, (_) => TextEditingController());
      _artistSlotControllers = List.generate(numArt, (_) => TextEditingController());
      _currentNumArtists = numArt;
    });
  }

  // --- Field Generation Logic for Catering ---
  void _generateCateringFields() {
    FocusScope.of(context).unfocus();
    int? numCat = int.tryParse(_numofcateringController.text);
    if (numCat == null || numCat < 0) {
      _showSnackBar('Please enter a valid non-negative number for catering companies.');
      if (numCat != 0) _numofcateringController.clear();
      numCat = 0;
    }
    // Dispose old controllers
    _cateringController.forEach((c) => c.dispose());
    // Create new controllers
    if (!mounted) return;
    setState(() {
      _cateringController = List.generate(numCat!, (_) => TextEditingController());
      _currentNumCatering = numCat;
    });
  }

  // --- Ticket Level Field Management ---
  void _addTicketLevel() {
    if (!mounted) return;
    setState(() {
      _ticketLevelNameControllers.add(TextEditingController());
      _ticketLevelCountControllers.add(TextEditingController());
      _ticketLevelPriceControllers.add(TextEditingController());
    });
  }

  void _removeTicketLevel(int index) {
    // Ensure controllers are disposed before removing
    _ticketLevelNameControllers[index].dispose();
    _ticketLevelCountControllers[index].dispose();
    _ticketLevelPriceControllers[index].dispose();
    if (!mounted) return;
    setState(() {
      _ticketLevelNameControllers.removeAt(index);
      _ticketLevelCountControllers.removeAt(index);
      _ticketLevelPriceControllers.removeAt(index);
    });
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus(); // Hide keyboard first
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Allow today
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked); // Format for display
      });
    }
  }

  // --- Form Submission Logic ---
  Future<void> _submitForm() async {
    // 1. Validate form
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors in the form.');
      return;
    }
    if (!mounted) return;
    // 2. Show Loading
    setState(() { _isLoading = true; });

    final firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();

    try {
      // 3. Gather Event base data
      String eventId = _eventIdController.text.trim();
      String eventName = _nameController.text.trim();
      String eventLoc = _locController.text.trim();
      int eventSlotnum = int.parse(_slotnumController.text.trim());
      // Validation ensures _selectedDate is not null here
      Timestamp eventTimestamp = Timestamp.fromDate(_selectedDate!);

      // 3a. Gather Artist map data
      List<Map<String, dynamic>> artistsData = [];
      for (int i = 0; i < _currentNumArtists; i++) {
        artistsData.add({
          'artistID': _artistIdControllers[i].text.trim(),
          'name': _artistNameControllers[i].text.trim(),
          'slot': int.parse(_artistSlotControllers[i].text.trim()),
        });
      }

      // 3b. Gather Catering map data
      List<Map<String, dynamic>> cateringData = [];
      for (int j = 0; j < _currentNumCatering; j++) {
        cateringData.add({'CompName': _cateringController[j].text.trim()});
      }

      // 3c. Gather and Validate Ticket Level definitions
      List<Map<String, dynamic>> ticketLevelsData = [];
      if (_ticketLevelNameControllers.isEmpty) {
        _showSnackBar('Please add at least one ticket level.');
        if (!mounted) return;
        setState(() { _isLoading = false; });
        return;
      }
      for (int k = 0; k < _ticketLevelNameControllers.length; k++) {
        String levelName = _ticketLevelNameControllers[k].text.trim();
        int ticketCount = int.parse(_ticketLevelCountControllers[k].text.trim());
        double ticketPrice = double.parse(_ticketLevelPriceControllers[k].text.trim());
        ticketLevelsData.add({
          'levelName': levelName,
          'count': ticketCount,
          'price': ticketPrice,
        });
      }

      // 4. Prepare Event Document Data for Firestore
      Map<String, dynamic> eventDocData = {
        'eventId': eventId,
        'name': eventName,
        'loc': eventLoc,
        'eventDate': eventTimestamp,
        'slotnum': eventSlotnum,
        'artists': artistsData,
        'catering': cateringData,
        'ticketLevels': ticketLevelsData,
        'totalRevenue': 0.0, // Initialize aggregate field
        'totalTicketsSold': 0, // Initialize aggregate field
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 5. Add Event Document creation to the batch
      DocumentReference eventRef = firestore.collection('events').doc(eventId);
      batch.set(eventRef, eventDocData);

      // 6. Generate and Add Individual Ticket Documents to the batch
      for (var level in ticketLevelsData) {
        String levelName = level['levelName'];
        int count = level['count'];
        double price = level['price'];
        String levelNameFormatted = levelName.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w-]'), '');

        for (int i = 1; i <= count; i++) {
          String ticketId = '$eventId-${levelNameFormatted.toUpperCase()}-${i.toString().padLeft(4, '0')}';
          Ticket newTicket = Ticket( // Use updated Ticket model
            ticketId: ticketId,
            eventId: eventId,
            levelName: levelName,
            price: price,
            status: 'available',
            userId: null,
            purchaseTimestamp: null,
          );
          DocumentReference ticketRef = firestore.collection('tickets').doc(ticketId);
          batch.set(ticketRef, newTicket.toMap()); // Use toMap from model
        }
      }

      // **** NEW: Add Payment Log Creation to the batch ****
      final paymentLogRef = firestore.collection('event_payment_logs').doc(eventId);
      final initialPaymentLogData = {
        'eventId': eventId,
        'eventName': eventName, // Store name for context
        'createdAt': FieldValue.serverTimestamp(), // Use same timestamp trigger
        'payments': [], // Initialize as empty array, ready for future payments
      };
      batch.set(paymentLogRef, initialPaymentLogData);
      // *****************************************************

      // 7. Commit the Batch (Event, Tickets, Payment Log)
      await batch.commit();

      _showSnackBar('Event, Tickets, and Payment Log successfully created!', isError: false);

      // 8. Clear the form and reset state
      _formKey.currentState?.reset();
      // Clear standard controllers
      _eventIdController.clear();
      _nameController.clear();
      _locController.clear();
      _dateController.clear();
      _slotnumController.clear();
      // Clear dynamic fields and reset state
      if (!mounted) return;
      setState(() {
        _selectedDate = null;
        // Dispose and clear artist controllers
        _artistIdControllers.forEach((c) => c.dispose());
        _artistNameControllers.forEach((c) => c.dispose());
        _artistSlotControllers.forEach((c) => c.dispose());
        _numofartistController.clear();
        _artistIdControllers = [];
        _artistNameControllers = [];
        _artistSlotControllers = [];
        _currentNumArtists = 0;
        // Dispose and clear catering controllers
        _cateringController.forEach((c) => c.dispose());
        _numofcateringController.clear();
        _cateringController = [];
        _currentNumCatering = 0;
        // Dispose and clear ticket level controllers
        _ticketLevelNameControllers.forEach((c) => c.dispose());
        _ticketLevelCountControllers.forEach((c) => c.dispose());
        _ticketLevelPriceControllers.forEach((c) => c.dispose());
        _ticketLevelNameControllers = [];
        _ticketLevelCountControllers = [];
        _ticketLevelPriceControllers = [];
        // Add back one empty ticket level row
        _addTicketLevel();
      });

    } catch (error) {
      print("Error during submission: $error");
      _showSnackBar('Failed to create event/tickets/log: ${error.toString()}');
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  // --- UI Helper Methods ---
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: _AppPaddings.sectionSpacing,
      child: Text(title, style: _AppTextStyles.sectionHeader),
    );
  }

  // TextFormField builder
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return Padding(
      padding: _AppPaddings.formField,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  String? _validatePositiveInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid integer';
    }
    if (number <= 0) {
      return 'Please enter a positive integer';
    }
    return null;
  }

  String? _validateNonNegativeNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return 'Please enter a non-negative number';
    }
    return null;
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: _AppColors.appBarBackground,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _AppColors.appBarForeground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Event",
          style: TextStyle(color: _AppColors.appBarForeground),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: _AppPaddings.screen,
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrolling
            children: [
              _buildEventDetailsSection(), // Includes date field now
              const Divider(height: 30, thickness: 1),
              _buildArtistSection(),
              const Divider(height: 30, thickness: 1),
              _buildCateringSection(),
              const Divider(height: 30, thickness: 1),
              _buildTicketLevelsSection(), // Section for tickets
              const SizedBox(height: 30),
              _buildSubmitButton(),
              const SizedBox(height: 20), // Space at the bottom
            ],
          ),
        ),
      ),
    );
  }

  // --- Section Builder Methods ---

  Widget _buildEventDetailsSection() {
    // Builds the UI section for basic event details including the date picker
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Event Details"),
        _buildTextFormField(
          controller: _eventIdController,
          label: "Event ID (Unique)",
          validator: (value) {
            if (value == null || value.trim().isEmpty) { return 'Please enter a unique Event ID'; }
            // Optional: Add check for spaces or invalid characters
            return null;
          },
        ),
        _buildTextFormField(
          controller: _nameController,
          label: "Event Name",
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter Event Name' : null,
        ),
        _buildTextFormField(
          controller: _locController,
          label: "Event Location",
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter Event Location' : null,
        ),
        // --- Date Picker TextFormField ---
        _buildTextFormField(
          controller: _dateController, // Displays formatted date
          readOnly: true, // Make read-only
          label: "Event Date",
          hintText: "Select Date", // Added hint text
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          onTap: () => _selectDate(context), // Call date picker on tap
          validator: (value) {
            // Validate based on the _selectedDate state variable
            if (_selectedDate == null) {
              return 'Please select an event date';
            }
            return null;
          },
        ),
        // -----------------------------
        _buildTextFormField(
          controller: _slotnumController,
          label: "Event Capacity",
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) => _validatePositiveInt(value, 'Event Capacity'),
        ),
      ],
    );
  }

  Widget _buildArtistSection() {
    // Builds the UI section for adding artists dynamically
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Artists (Optional)"),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextFormField(
                  controller: _numofartistController,
                  label: "Number of Artists",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) { // Allow 0
                    if (value == null || value.trim().isEmpty) return null;
                    final number = int.tryParse(value.trim());
                    if (number == null) return 'Enter a valid number';
                    if (number < 0) return 'Enter a non-negative number';
                    return null;
                  }
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: ElevatedButton(
                onPressed: _generateArtistFields,
                child: const Text("Set"),
              ),
            ),
          ],
        ),
        // Dynamically generate artist fields
        if (_currentNumArtists > 0)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentNumArtists,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Artist ${index + 1}", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _artistIdControllers[index],
                      label: "Artist ID",
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter Artist ID' : null, // Required if num artists > 0
                    ),
                    _buildTextFormField(
                      controller: _artistNameControllers[index],
                      label: "Artist Name",
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter Artist Name' : null,
                    ),
                    _buildTextFormField(
                      controller: _artistSlotControllers[index],
                      label: "Artist Slot",
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => _validatePositiveInt(value, 'Artist Slot'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_numofartistController.text.isNotEmpty && (int.tryParse(_numofartistController.text) ?? -1) == 0) // Handle 0 case
          const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('No artist fields generated.', style: TextStyle(color: Colors.grey))
          )
        else if (_numofartistController.text.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Press "Set" to generate artist fields.', style: TextStyle(color: Colors.grey[600]))
            ),
      ],
    );
  }

  Widget _buildCateringSection() {
    // Builds the UI section for adding catering companies dynamically
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Catering (Optional)"),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:_buildTextFormField(
                  controller: _numofcateringController,
                  label: "Number of Catering Companies",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) { // Allow 0
                    if (value == null || value.trim().isEmpty) return null;
                    final number = int.tryParse(value.trim());
                    if (number == null) return 'Enter a valid number';
                    if (number < 0) return 'Enter a non-negative number';
                    return null;
                  }
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: ElevatedButton(
                onPressed: _generateCateringFields,
                child: const Text("Set"),
              ),
            ),
          ],
        ),
        // Dynamically generate catering fields
        if (_currentNumCatering > 0)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentNumCatering,
            itemBuilder: (context, index) => _buildTextFormField(
              controller: _cateringController[index],
              label: "Catering Company ${index + 1} Name",
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter Company Name' : null, // Required if num > 0
            ),
          )
        else if (_numofcateringController.text.isNotEmpty && (int.tryParse(_numofcateringController.text) ?? -1) == 0)
          const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('No catering fields generated.', style: TextStyle(color: Colors.grey))
          )
        else if (_numofcateringController.text.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Press "Set" to add catering fields.', style: TextStyle(color: Colors.grey[600]))
            ),
      ],
    );
  }

  Widget _buildTicketLevelsSection() {
    // Builds the UI section for adding ticket levels dynamically
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Ticket Levels"),
        // Display existing ticket level rows
        if (_ticketLevelNameControllers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text("Click 'Add Ticket Level' to start.")),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ticketLevelNameControllers.length,
            itemBuilder: (context, index) {
              // Card for each level
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row( // Header for the level card
                        children: [
                          Expanded(child: Text("Level ${index + 1}", style: Theme.of(context).textTheme.titleMedium)),
                          // Remove button enabled only if more than one level exists
                          if (_ticketLevelNameControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              tooltip: 'Remove Level ${index + 1}',
                              onPressed: () => _removeTicketLevel(index),
                            )
                          else
                            const SizedBox(width: 48), // Placeholder for alignment
                        ],
                      ),
                      const SizedBox(height: 8),
                      // --- Fields for this Ticket Level ---
                      _buildTextFormField(
                        controller: _ticketLevelNameControllers[index],
                        label: "Level Name (e.g., VIP, Standard)",
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter level name' : null,
                      ),
                      _buildTextFormField(
                        controller: _ticketLevelCountControllers[index],
                        label: "Number of Tickets",
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => _validatePositiveInt(value, 'Number of Tickets'),
                      ),
                      _buildTextFormField(
                        controller: _ticketLevelPriceControllers[index],
                        label: "Price per Ticket (\$)",
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        validator: (value) => _validateNonNegativeNumber(value, 'Price'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        // Button to add a new ticket level row
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Add Another Ticket Level"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
            onPressed: _addTicketLevel,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    // Builds the final submit button
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm, // Disable when loading
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.buttonBackground, // Use defined color
        padding: _AppPaddings.button, // Use constant padding
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12) // Assuming _AppRadius.buttonRadius was 12
        ),
        elevation: 5,
        side: const BorderSide(
          color: _AppColors.buttonBorder,
          width: 2,
        ),
      ),
      child: _isLoading
          ? const SizedBox( // Show loading indicator
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      )
          : const Text( // Show button text
        'Create Event & Generate Tickets',
        style: _AppTextStyles.button,
      ),
    );
  }
}