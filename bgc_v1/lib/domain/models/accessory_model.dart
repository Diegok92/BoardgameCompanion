import 'package:flutter/material.dart';

class Accessory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Accessory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
