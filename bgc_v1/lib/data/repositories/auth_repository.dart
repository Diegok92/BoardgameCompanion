import '../../domain/models/user_model.dart';
import '../mock/mock_database.dart';

class AuthRepository {
  // En el futuro, esto se conectará a FirebaseAuth y Firestore

  Future<User?> login(String email, String password) async {
    // Simulamos un retraso de red
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = MockDatabase.users.firstWhere(
        (u) => u.email == email && u.password == password,
      );
      return user;
    } catch (e) {
      // Si firstWhere falla, devuelve StateError, lo atrapamos y devolvemos null
      return null;
    }
  }

  Future<User> register(User newUser) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulamos que el email debe ser único
    final exists = MockDatabase.users.any((u) => u.email == newUser.email);
    if (exists) {
      throw Exception('El correo electrónico ya está en uso.');
    }

    MockDatabase.users.add(newUser);
    return newUser;
  }

  Future<void> updateUser(User user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = MockDatabase.users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      MockDatabase.users[index] = user;
    }
  }
}
