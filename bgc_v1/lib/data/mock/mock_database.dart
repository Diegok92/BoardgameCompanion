import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';

class MockDatabase {
  static final List<User> users = [
    User(
      id: '1',
      username: 'MagoSupremo',
      email: 'mago@test.com',
      password: 'password123',
      favoriteColor: const Color(0xFFE53935), // Rojo
      invitados: ['Fede', 'Matias', 'Lucas'],
    ),
    User(
      id: '2',
      username: 'Caro',
      email: 'caro@test.com',
      password: 'password123',
      favoriteColor: const Color(0xFF1E88E5), // Azul
      invitados: ['Ana', 'Juli', 'Sofi'],
    ),
    User(
      id: '3',
      username: 'Diego',
      email: 'diego',
      password: '123',
      favoriteColor: const Color(0xFF43A047), // Verde
      invitados: ['MagoSupremo', 'Caro'],
    ),
  ];

  static User? authenticate(String email, String password) {
    try {
      return users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}
