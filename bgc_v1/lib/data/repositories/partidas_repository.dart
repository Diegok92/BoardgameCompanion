import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/partida_model.dart';

class PartidasRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registrarPartida(String userId, Partida partida) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('partidas')
          .doc();

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
      return [];
    }
  }

  Future<Map<String, dynamic>> getHistorialPartidasPaginated(
    String userId, {
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
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
          .map(
            (doc) =>
                Partida.fromJson(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();

      return {
        'partidas': partidas,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      return {'partidas': <Partida>[], 'lastDocument': null, 'hasMore': false};
    }
  }

  Future<void> borrarPartida(String userId, String partidaId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('partidas')
          .doc(partidaId)
          .delete();
    } catch (e) {
      // ignore: empty_catches — borrar una partida inexistente es no-op
    }
  }
}
