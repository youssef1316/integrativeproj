import 'package:flutter/material.dart';
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Constants (Similar to HomeScreen, ideally in separate files/theme) ---
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
    color: Colors.white, // Consider using theme color
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent, // Consider using theme color
  );
}

class _AppColors {
  static const Color primaryBackground = Colors.white;
  static const Color appBarBackground = Colors.white;
  static const Color appBarForeground = Colors.black;
  static const Color buttonBackground = Colors.red; // Consider theme.colorScheme.primary
  static const Color buttonBorder = Colors.blueAccent; // Consider theme.colorScheme.secondary
}
// --- End Constants ---


class EventCreationPage extends StatefulWidget {
  // Use const constructor
  const EventCreationPage({super.key});

  @override
  _EventCreationPageState createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final _formKey = GlobalKey<FormState>(); // Key for the Form
  bool _isLoading = false; // To manage loading state during submission

  // --- Event Controllers ---
  final _eventIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _locController = TextEditingController();
  final _slotnumController = TextEditingController();

  // --- Artist Section State ---
  final _numofartistController = TextEditingController();
  List<TextEditingController> _artistIdControllers = [];
  List<TextEditingController> _artistNameControllers = [];
  List<TextEditingController> _artistSlotControllers = [];
  int _currentNumArtists = 0; // Track the number of fields currently shown

  // --- Catering Section State ---
  final _numofcateringController = TextEditingController();
  List<TextEditingController> _cateringController = [];
  int _currentNumCatering = 0; // Track the number of fields currently shown


  @override
  void dispose() {
    // Dispose all controllers
    _eventIdController.dispose();
    _nameController.dispose();
    _locController.dispose();
    _slotnumController.dispose();
    _numofartistController.dispose();
    _numofcateringController.dispose();
    _artistIdControllers.forEach((c) => c.dispose());
    _artistNameControllers.forEach((c) => c.dispose());
    _artistSlotControllers.forEach((c) => c.dispose());
    _cateringController.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- Field Generation Logic ---
  void _generateArtistFields() {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    int? numArt = int.tryParse(_numofartistController.text);
    if (numArt == null || numArt <= 0) {
      _showSnackBar('Please enter a valid positive number of artists.');
      return;
    }

    // Dispose old controllers if regenerating
    _artistIdControllers.forEach((c) => c.dispose());
    _artistNameControllers.forEach((c) => c.dispose());
    _artistSlotControllers.forEach((c) => c.dispose());

    // Create new controllers
    _artistIdControllers = List.generate(numArt, (_) => TextEditingController());
    _artistNameControllers = List.generate(numArt, (_) => TextEditingController());
    _artistSlotControllers = List.generate(numArt, (_) => TextEditingController());

    setState(() {
      _currentNumArtists = numArt;
    });
  }

  void _generateCateringFields() {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    int? numCat = int.tryParse(_numofcateringController.text);
    if (numCat == null || numCat <= 0) {
      _showSnackBar('Please enter a valid positive number for catering companies.');
      return;
    }

    // Dispose old controllers if regenerating
    _cateringController.forEach((c) => c.dispose());

    // Create new controllers
    _cateringController = List.generate(numCat, (_) => TextEditingController());

    setState(() {
      _currentNumCatering = numCat;
    });
  }

  // --- Form Submission Logic ---
  Future<void> _submitForm() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors in the form.');
      return; // Don't proceed if validation fails
    }

    // 2. Set loading state
    setState(() { _isLoading = true; });

    try {
      // 3. Gather data (already validated by the form)
      String eventId = _eventIdController.text.trim();
      String name = _nameController.text.trim();
      String loc = _locController.text.trim();
      int slotnum = int.parse(_slotnumController.text.trim()); // Use parse (validated)

      // Collect artist data
      List<Artist> artists = [];
      for (int i = 0; i < _currentNumArtists; i++) {
        artists.add(Artist(
          artistID: _artistIdControllers[i].text.trim(),
          name: _artistNameControllers[i].text.trim(),
          slot: int.parse(_artistSlotControllers[i].text.trim()), // Use parse
        ));
      }

      // Collect catering data
      List<Catering> cateringList = [];
      for (int j = 0; j < _currentNumCatering; j++) {
        cateringList.add(Catering(CompName: _cateringController[j].text.trim()));
      }

      // 4. Create Event object and map for Firestore
      // (Consider adding toJson methods to your model classes)
      Events newEvent = Events(
        eventId: eventId, name: name, loc: loc, slotnum: slotnum,
        artists: artists, catering: cateringList,
      );

      Map<String, dynamic> eventData = {
        'eventId': newEvent.eventId,
        'name': newEvent.name,
        'loc': newEvent.loc,
        'slotnum': newEvent.slotnum,
        'artists': newEvent.artists.map((a) => {
          'artistID': a.artistID, 'name': a.name, 'slot': a.slot,
        }).toList(),
        'catering': newEvent.catering.map((c) => {
          'CompName': c.CompName,
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(), // Good practice to add a timestamp
      };

      // 5. Save to Firestore
      await FirebaseFirestore.instance.collection('events').doc(eventId).set(eventData);

      _showSnackBar('Event successfully created!', isError: false);
      // Optionally clear form or navigate away
      // _formKey.currentState?.reset();
      // Navigator.pop(context);

    } catch (error) {
      _showSnackBar('Failed to create event: ${error.toString()}');
    } finally {
      // 6. Reset loading state
      if (mounted) { // Check if widget is still in the tree
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- UI Helper Methods ---
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return; // Check if the widget is still active
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: _AppPaddings.sectionSpacing,
      child: Text(title, style: _AppTextStyles.sectionHeader),
    );
  }

  // Generic TextFormField builder
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return Padding(
      padding: _AppPaddings.formField,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0), // Consistent radius
          ),
          filled: true, // Add subtle background
          fillColor: Colors.grey[50], // Light fill color
        ),
        keyboardType: keyboardType,
        validator: validator ?? (value) { // Default non-empty validator
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        maxLines: maxLines,
        autovalidateMode: AutovalidateMode.onUserInteraction, // Validate as user types (after first interaction)
      ),
    );
  }

  // Specific validator for positive integers
  String? _validatePositiveInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return 'Please enter a positive number';
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
        child: Form( // Wrap content in a Form widget
          key: _formKey,
          child: ListView(
            children: [
              _buildEventDetailsSection(),
              const Divider(height: 30, thickness: 1),
              _buildArtistSection(),
              const Divider(height: 30, thickness: 1),
              _buildCateringSection(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Section Builder Methods ---

  Widget _buildEventDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Event Details"),
        _buildTextFormField(
          controller: _eventIdController,
          label: "Event ID",
          // Add specific validation if needed (e.g., check uniqueness async)
        ),
        _buildTextFormField(
          controller: _nameController,
          label: "Event Name",
        ),
        _buildTextFormField(
          controller: _locController,
          label: "Event Location",
        ),
        _buildTextFormField(
          controller: _slotnumController,
          label: "Number of Slots",
          keyboardType: TextInputType.number,
          validator: (value) => _validatePositiveInt(value, 'Number of Slots'),
        ),
      ],
    );
  }

  Widget _buildArtistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Artists"),
        Row( // Layout number input and button horizontally
          crossAxisAlignment: CrossAxisAlignment.start, // Align top
          children: [
            Expanded(
              child: _buildTextFormField(
                controller: _numofartistController,
                label: "Number of Artists",
                keyboardType: TextInputType.number,
                validator: (value) => _validatePositiveInt(value, 'Number of Artists'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0), // Adjust spacing
              child: ElevatedButton(
                // Style this button if needed
                onPressed: _generateArtistFields,
                child: const Text("Set Artists"),
              ),
            ),
          ],
        ),
        // Dynamically generate artist fields based on _currentNumArtists
        if (_currentNumArtists > 0) ...[
          ...List.generate(
            _currentNumArtists,
                (index) => Card( // Group each artist's fields in a Card
              margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                    ),
                    _buildTextFormField(
                      controller: _artistNameControllers[index],
                      label: "Artist Name",
                    ),
                    _buildTextFormField(
                      controller: _artistSlotControllers[index],
                      label: "Artist Slot",
                      keyboardType: TextInputType.number,
                      validator: (value) => _validatePositiveInt(value, 'Artist Slot'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (_numofartistController.text.isNotEmpty) // Prompt user if number entered but not generated
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Press "Set Artists" to add fields.', style: TextStyle(color: Colors.grey[600]))
          ),

      ],
    );
  }

  Widget _buildCateringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Catering"),
        Row( // Layout number input and button horizontally
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:_buildTextFormField(
                controller: _numofcateringController,
                label: "Number of Catering Companies",
                keyboardType: TextInputType.number,
                validator: (value) => _validatePositiveInt(value, 'Number of Catering Companies'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: ElevatedButton(
                onPressed: _generateCateringFields,
                child: const Text("Set Catering"),
              ),
            ),
          ],
        ),
        // Dynamically generate catering fields
        if (_currentNumCatering > 0)...[
          ...List.generate(
            _currentNumCatering,
                (index) => _buildTextFormField(
              controller: _cateringController[index],
              label: "Catering Company ${index + 1} Name",
            ),
          ),
        ] else if (_numofcateringController.text.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Press "Set Catering" to add fields.', style: TextStyle(color: Colors.grey[600]))
          ),
      ],
    );
  }


  Widget _buildSubmitButton() {
    return ElevatedButton(
      // Use onPressed: null to disable when loading
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.buttonBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: _AppPaddings.button,
        elevation: 5,
        side: const BorderSide( // Keep border if desired
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
        'Create Event',
        style: _AppTextStyles.button,
      ),
    );
  }
}