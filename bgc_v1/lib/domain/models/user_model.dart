import 'package:flutter/material.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final Color? favoriteColor;
  final List<String> invitados;
  final bool isActive; // Para soft-delete

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.favoriteColor,
    required this.invitados,
    this.isActive = true, // Por defecto activo
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    Color? favoriteColor,
    List<String>? invitados,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      favoriteColor: favoriteColor ?? this.favoriteColor,
      invitados: invitados ?? this.invitados,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      // Guardamos el color como entero
      'favoriteColor': favoriteColor?.toARGB32(),
      'invitados': invitados,
      'isActive': isActive,
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
      isActive: json['isActive'] ?? true, // Si no existe (usuarios viejos), asumimos que está activo
    );
  }
}
