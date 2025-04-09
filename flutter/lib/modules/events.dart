import 'package:flutter/material.dart';
import 'package:eventmangment/modules/Artists.dart';
import 'package:eventmangment/modules/catering.dart';

class Events{
  //variables
  String eventId;
  String name;
  String loc;
  int slotnum;
  List<Artist> artists;
  List<Catering> catering;

  //constructor
  Events({
    required this.eventId,
    required this.name,
    required this.loc,
    required this.slotnum,
    required this.artists,
    required this.catering
});

// functions and methods


}