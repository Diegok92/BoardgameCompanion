import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/partida_model.dart';

class PartidasRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guarda una partida terminada en Firestore
  Future<void> registrarPartida(String userId, Partida partida) async {
    try {
      // Usamos .doc() vacío para generar un ID aleatorio único
      final docRef =
          _firestore.collection('users').doc(userId).collection('partidas').doc();

      // Guardamos la partida con el ID generado, fecha actual y estado finalizada
      final partidaFinal = partida.copyWith(
        id: docRef.id,
        fechaFinalizacion: DateTime.now(),
        estado: 'finalizada',
      );

      await docRef.set(partidaFinal.toJson());
    } catch (e) {
      throw Exception('Error al registrar la partida: $e');
    }
  }

  // Obtiene el historial completo de partidas del usuario
  Future<List<Partida>> getHistorialPartidas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('partidas')
          .orderBy('fechaFinalizacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Partida.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // print('Error obteniendo historial: $e');
      return [];
    }
  }

  // Obtiene el historial de partidas de forma paginada
  Future<Map<String, dynamic>> getHistorialPartidasPaginated(String userId, {DocumentSnapshot? lastDocument, int limit = 20}) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('partidas')
          .orderBy('fechaFinalizacion', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final partidas = snapshot.docs
          .map((doc) => Partida.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      return {
        'partidas': partidas,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      return {
        'partidas': <Partida>[],
        'lastDocument': null,
        'hasMore': false,
      };
    }
  }

  // Eliminar una partida del historial
  Future<void> borrarPartida(String userId, String partidaId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('partidas')
          .doc(partidaId)
          .delete();
    } catch (e) {
      // print('Error al borrar la partida: $e');
    }
  }
}
