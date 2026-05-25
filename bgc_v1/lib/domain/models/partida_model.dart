import 'package:cloud_firestore/cloud_firestore.dart';

class Partida {
  final String id;
  final String juegoId;
  final String juegoNombre;
  final DateTime? fechaFinalizacion; // null si está en curso
  final List<String> participantes;
  final List<String> ganadores;
  final Map<String, int> puntajesFinales; // o cualquier dato del anotador
  final String estado; // "en_curso" o "finalizada"
  final bool isTeamGame;

  Partida({
    required this.id,
    required this.juegoId,
    required this.juegoNombre,
    this.fechaFinalizacion,
    required this.participantes,
    required this.ganadores,
    required this.puntajesFinales,
    required this.estado,
    this.isTeamGame = false,
  });

  Partida copyWith({
    String? id,
    String? juegoId,
    String? juegoNombre,
    DateTime? fechaFinalizacion,
    List<String>? participantes,
    List<String>? ganadores,
    Map<String, int>? puntajesFinales,
    String? estado,
    bool? isTeamGame,
  }) {
    return Partida(
      id: id ?? this.id,
      juegoId: juegoId ?? this.juegoId,
      juegoNombre: juegoNombre ?? this.juegoNombre,
      fechaFinalizacion: fechaFinalizacion ?? this.fechaFinalizacion,
      participantes: participantes ?? this.participantes,
      ganadores: ganadores ?? this.ganadores,
      puntajesFinales: puntajesFinales ?? this.puntajesFinales,
      estado: estado ?? this.estado,
      isTeamGame: isTeamGame ?? this.isTeamGame,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'juegoId': juegoId,
      'juegoNombre': juegoNombre,
      'fechaFinalizacion': fechaFinalizacion != null
          ? Timestamp.fromDate(fechaFinalizacion!)
          : null,
      'participantes': participantes,
      'ganadores': ganadores,
      'puntajesFinales': puntajesFinales,
      'estado': estado,
      'isTeamGame': isTeamGame,
    };
  }

  factory Partida.fromJson(String id, Map<String, dynamic> json) {
    return Partida(
      id: id,
      juegoId: json['juegoId'] ?? '',
      juegoNombre: json['juegoNombre'] ?? '',
      fechaFinalizacion: json['fechaFinalizacion'] != null
          ? (json['fechaFinalizacion'] as Timestamp).toDate()
          : null,
      participantes: List<String>.from(json['participantes'] ?? []),
      ganadores: List<String>.from(json['ganadores'] ?? []),
      puntajesFinales: Map<String, int>.from(json['puntajesFinales'] ?? {}),
      estado: json['estado'] ?? 'en_curso',
      isTeamGame: json['isTeamGame'] ?? false,
    );
  }
}
