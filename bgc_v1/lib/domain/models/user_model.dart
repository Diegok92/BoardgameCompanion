import 'package:flutter/material.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final Color? favoriteColor;
  final List<String> invitados;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.favoriteColor,
    required this.invitados,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    Color? favoriteColor,
    List<String>? invitados,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      favoriteColor: favoriteColor ?? this.favoriteColor,
      invitados: invitados ?? this.invitados,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      // Guardamos el color como entero
      'favoriteColor': favoriteColor?.toARGB32(),
      'invitados': invitados,
      // IMPORTANTE: NUNCA guardamos la contraseña en Firestore
    };
  }

  factory User.fromJson(String id, Map<String, dynamic> json) {
    return User(
      id: id,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: '', // Firebase Auth maneja la contraseña, no viene de Firestore
      favoriteColor: json['favoriteColor'] != null
          ? Color(json['favoriteColor'])
          : null,
      invitados: List<String>.from(json['invitados'] ?? []),
    );
  }
}
