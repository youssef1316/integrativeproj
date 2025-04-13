import 'package:flutter/material.dart';
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _CreateEvent createState() => _CreateEvent();
}

class _CreateEvent extends State<HomePage> {
  // Event Controllers
  TextEditingController eventIdController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController locController = TextEditingController();
  TextEditingController attendeesController = TextEditingController();
  TextEditingController slotnumController = TextEditingController();

  // Artist Controllers
  TextEditingController numofartistController = TextEditingController();
  List<TextEditingController> artistIdControllers = [];
  List<TextEditingController> artistNameControllers = [];
  List<TextEditingController> artistSlotControllers = [];
  bool generatedArt = false;

  // Catering Controllers
  TextEditingController numofcateringController = TextEditingController();
  List<TextEditingController> cateringController = [];
  bool generatedCat = false;

  // Method to generate artist fields
  void artfields() {
    int? numArt = int.tryParse(numofartistController.text);
    if (numArt == null || numArt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid number of artists')),
      );
      return;
    }
    artistIdControllers.clear();
    artistNameControllers.clear();
    artistSlotControllers.clear();

    for (int i = 0; i < numArt; i++) {
      artistIdControllers.add(TextEditingController());
      artistNameControllers.add(TextEditingController());
      artistSlotControllers.add(TextEditingController());
    }
    setState(() {
      generatedArt = true;
    });
  }

  // Method to generate catering fields
  void catFields() {
    int? numCat = int.tryParse(numofcateringController.text);
    if (numCat == null || numCat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid number of catering companies')),
      );
      return;
    }
    cateringController.clear();
    for (int i = 0; i < numCat; i++) {
      cateringController.add(TextEditingController());
    }
    setState(() {
      generatedCat = true;
    });
  }

  // Method to create the event
  void createEvent() {
    String eventId = eventIdController.text.trim();
    String name = nameController.text.trim();
    String loc = locController.text.trim();
    int? slotnum = int.tryParse(slotnumController.text.trim());

    if (eventId.isEmpty || name.isEmpty || loc.isEmpty || slotnum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all event fields correctly!')),
      );
      return;
    }

    // Collect all artist data
    List<Artist> artists = [];
    int totalArtists = artistIdControllers.length;
    for (int i = 0; i < totalArtists; i++) {
      String artistId = artistIdControllers[i].text.trim();
      String artistName = artistNameControllers[i].text.trim();
      int? slot = int.tryParse(artistSlotControllers[i].text.trim());
      if (artistId.isEmpty || artistName.isEmpty || slot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields for artist ${i + 1} correctly!')),
        );
        return;
      }
      artists.add(Artist(
        artistID: artistId,
        name: artistName,
        slot: slot,
      ));
    }

    // Collect all catering data
    List<Catering> cateringList = [];
    int totalCat = cateringController.length;
    for (int j = 0; j < totalCat; j++) {
      String compName = cateringController[j].text.trim();
      if (compName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill field for company name ${j + 1} correctly!')),
        );
        return;
      }
      cateringList.add(Catering(CompName: compName));
    }

    // Now create the event using the collected data
    Events newEvent = Events(
      eventId: eventId,
      name: name,
      loc: loc,
      slotnum: slotnum,
      artists: artists,
      catering: cateringList,
    );
    FirebaseFirestore.instance.collection('events').doc(eventId).set({
      'eventId': newEvent.eventId,
      'name': newEvent.name,
      'loc': newEvent.loc,
      'slotnum': newEvent.slotnum,
      'artists': newEvent.artists.map((a) => {
        'artistID': a.artistID,
        'name': a.name,
        'slot': a.slot,
      }).toList(),
      'catering': newEvent.catering.map((c) => {
        'CompName': c.CompName,
      }).toList(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event successfully added to Firestore!')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Event Creation")),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _textField("Event ID", eventIdController),
            _textField("Event Name", nameController),
            _textField("Event Location", locController),
            _textField("Number of Slots", slotnumController),
            _textField("Number of Artists", numofartistController, onChanged: artfields),
            if (generatedArt) ...[
              ...List.generate(
                artistIdControllers.length,
                    (index) => Column(
                  children: [
                    _textField("Artist ${index + 1} ID", artistIdControllers[index]),
                    _textField("Artist ${index + 1} Name", artistNameControllers[index]),
                    _textField("Artist ${index + 1} Slot", artistSlotControllers[index]),
                  ],
                ),
              ),
            ],
            _textField("Number of Catering Companies", numofcateringController, onChanged: catFields),
            if (generatedCat) ...[
              ...List.generate(
                cateringController.length,
                    (index) => _textField("Catering Company ${index + 1} Name", cateringController[index]),
              ),
            ],
            ElevatedButton(
              onPressed: createEvent,
              child: Text(
                'Create Event',
                style: TextStyle(
                  fontSize: 18,              // Font size of the button text
                  fontWeight: FontWeight.bold, // Font weight for bold text
                  color: Colors.white,        // Text color
                ),
              ),
              style: ElevatedButton.styleFrom(
               backgroundColor: Colors.red,  // Text color when the button is pressed
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),  // Rounded corners
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Padding
                elevation: 5, // Shadow depth of the button
                side: BorderSide(
                  color: Colors.blueAccent, // Border color
                  width: 2,                 // Border width
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, {Function()? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: label.contains("Number") ? TextInputType.number : TextInputType.text,
        onChanged: (_) => onChanged?.call(),
      ),
    );
  }

  @override
  void dispose() {
    eventIdController.dispose();
    nameController.dispose();
    locController.dispose();
    attendeesController.dispose();
    slotnumController.dispose();
    numofartistController.dispose();
    numofcateringController.dispose();
    artistIdControllers.forEach((controller) => controller.dispose());
    artistNameControllers.forEach((controller) => controller.dispose());
    artistSlotControllers.forEach((controller) => controller.dispose());
    cateringController.forEach((controller) => controller.dispose());
    super.dispose();
  }
}