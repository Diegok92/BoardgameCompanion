import 'package:flutter/material.dart';
import '../../domain/models/accessory_model.dart';

class LocalAccessoriesCatalog {
  static const List<Accessory> accessories = [
    Accessory(
      id: 'dados',
      name: 'Dados',
      icon: Icons.casino,
      color: Color(0xFFE53935),
    ),
    Accessory(
      id: 'moneda',
      name: 'Moneda',
      icon: Icons.monetization_on,
      color: Color(0xFFFDD835),
    ),
    Accessory(
      id: 'letra_random',
      name: 'Letra Random',
      icon: Icons.sort_by_alpha,
      color: Color(0xFF1E88E5),
    ),
    Accessory(
      id: 'reloj_ajedrez',
      name: 'Reloj de Ajedrez',
      icon: Icons.timer,
      color: Color(0xFF43A047),
    ),
    Accessory(
      id: 'reloj_arena',
      name: 'Reloj de Arena',
      icon: Icons.hourglass_bottom,
      color: Color(0xFF8E24AA),
    ),
  ];
}
