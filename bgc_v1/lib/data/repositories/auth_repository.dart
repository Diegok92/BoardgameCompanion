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
          final user = User.fromJson(firebaseUser.uid, doc.data()!);
          
          if (!user.isActive) {
            await _firebaseAuth.signOut();
            throw Exception('Esta cuenta ha sido eliminada.');
          }
          
          return user;
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
      // 1. Actualizamos los datos en Firestore
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      
      // 2. Actualizamos credenciales en Firebase Auth si el usuario cambió algo
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // Actualizar email si es diferente
        if (user.email.isNotEmpty && user.email != currentUser.email) {
          await currentUser.verifyBeforeUpdateEmail(user.email);
        }
        // Actualizar contraseña si escribió una nueva
        if (user.password.isNotEmpty) {
          await currentUser.updatePassword(user.password);
        }
      }
    } catch (e) {
      print('Error al actualizar usuario: $e');
      // Lanzamos la excepción para que la UI pueda atraparla y mostrar el error
      throw Exception('No se pudo actualizar el perfil. Si cambiaste la contraseña o email, es posible que debas cerrar sesión y volver a entrar por seguridad.');
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> softDeleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'isActive': false});
      await logout();
    } catch (e) {
      print('Error al hacer soft delete del usuario: $e');
      throw Exception('Error al borrar la cuenta.');
    }
  }
}
