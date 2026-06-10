import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../core/error/app_exceptions.dart';

class AuthRepository implements IAuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          data['id'] = firebaseUser.uid;
          data['password'] =
              ''; // Por seguridad, nunca cargamos la contraseña guardada
          final user = User.fromJson(data);

          if (!user.isActive) {
            await _firebaseAuth.signOut();
            throw const AuthException(
              'Esta cuenta ha sido eliminada.',
              code: 'account-deleted',
            );
          }

          return user;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User> register(User newUser) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: newUser.email,
        password: newUser.password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          'No se pudo crear el usuario en Firebase Auth.',
          code: 'user-not-created',
        );
      }

      // password: '' — la contraseña no se guarda en Firestore; Firebase Auth la gestiona
      final userToSave = newUser.copyWith(id: firebaseUser.uid, password: '');
      final userData = userToSave.toJson();
      userData.remove('password');
      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      return userToSave;
    } catch (e) {
      throw AuthException(
        'Error al registrar usuario: $e',
        code: 'registration-error',
      );
    }
  }

  @override
  Future<void> updateUser(User user) async {
    try {
      final safeUser = user.copyWith(password: '');
      final userData = safeUser.toJson();
      userData['password'] = FieldValue.delete();
      await _firestore.collection('users').doc(user.id).update(userData);

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        if (user.email.isNotEmpty && user.email != currentUser.email) {
          await currentUser.verifyBeforeUpdateEmail(user.email);
        }
      }
    } catch (e) {
      throw const AuthException(
        'No se pudo actualizar el perfil. Si cambiaste el email, es posible que debas cerrar sesión y volver a entrar por seguridad.',
        code: 'update-profile-error',
      );
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> softDeleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
      });
      await logout();
    } catch (e) {
      throw AuthException(
        'Error al borrar la cuenta: $e',
        code: 'soft-delete-error',
      );
    }
  }
}
