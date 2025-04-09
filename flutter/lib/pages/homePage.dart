import 'package:flutter/material.dart';
import 'package:eventmangment/modules/events.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';
import 'package:eventmangment/modules/feedback.dart';
import 'package:eventmangment/modules/financial.dart';

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
    for (int i = 0; i < numCat; i++){
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
    for (int j = 0; j < totalCat; j++){
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

    print('Event created: ${newEvent.name} with ${artists.length} artists and ${cateringList.length} catering companies.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Event Management")),
      body: Center(child: Text("Home Page")),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers (both static and dynamic)
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
