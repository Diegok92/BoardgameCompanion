import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> login(String email, String password) async {
    try {
      // 1. Logueamos al usuario con Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // 2. Buscamos su información pública (username, color, etc) en Firestore
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (doc.exists && doc.data() != null) {
          // Unimos el ID de Firebase Auth con los datos de Firestore
          return User.fromJson(firebaseUser.uid, doc.data()!);
        }
      }
      return null;
    } catch (e) {
      print('Error en login de Firebase: $e');
      return null;
    }
  }

  Future<User> register(User newUser) async {
    try {
      // 1. Crear el usuario en Firebase Auth (esto encripta y guarda la contraseña)
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: newUser.email,
        password: newUser.password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('No se pudo crear el usuario en Firebase Auth.');
      }

      // 2. Guardar el resto de la información en Firestore, usando el ID generado
      final userToSave = newUser.copyWith(id: firebaseUser.uid);
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userToSave.toJson());

      return userToSave;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      // Actualizamos los datos en Firestore
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      print('Error al actualizar usuario en Firestore: $e');
    }
  }
}
