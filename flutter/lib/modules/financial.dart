import 'package:flutter/material.dart';

class Finacial{
  //variables
  String repID;
  double totalIn;
  double totalOut;

  //constructor
  Finacial({
   required this.repID,
    required this.totalIn,
    required this. totalOut
});

  // functions
  void updateIn(int v){
    //function to update the total revenue
    totalIn += v;
  }
  void updateOut(int v){
    //function to update the total expendeture
    totalOut += v;
  }
}