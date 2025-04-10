import 'package:flutter/material.dart';
import 'tickets.dart';

class Customers {
  String ssn;
  String name;
  int age;
  String email;
  String password;
  String phone;
  List<Tickets> boughtTickets=[];

  Customers({
    required this.ssn,
    required this.name,
    required this.age,
    required this.email,
    required this.password,
    required this.phone,

  });

  void buyTickets(List<Tickets> tickets){
    boughtTickets.addAll(tickets);
  }

}