import 'package:flutter/material.dart';

class User {
  final String id;
  String username;
  String email;
  String password;
  Color? favoriteColor;
  final List<String> invitados;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.favoriteColor,
    required this.invitados,
  });
}
