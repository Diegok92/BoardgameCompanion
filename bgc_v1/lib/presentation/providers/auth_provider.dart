import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

// Provider que expone y permite mutar el estado del usuario logueado.
// Retorna 'null' si no hay sesión activa.
final authProvider = NotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<User?> {
  late final AuthRepository _repository;

  @override
  User? build() {
    _repository = ref.watch(authRepositoryProvider);
    return null; // Inicialmente no hay usuario logueado
  }

  Future<bool> login(String email, String password) async {
    final user = await _repository.login(email, password);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  Future<void> register(User newUser) async {
    final user = await _repository.register(newUser);
    state = user;
  }

  void logout() {
    state = null;
  }

  Future<void> updateUser(User updatedUser) async {
    if (state != null) {
      await _repository.updateUser(updatedUser);
      state = updatedUser;
    }
  }

  void addInvitado(String nombreInvitado) {
    if (state != null) {
      final updatedList = List<String>.from(state!.invitados)
        ..add(nombreInvitado);
      state = state!.copyWith(invitados: updatedList);
    }
  }

  void editInvitado(int index, String newName) {
    if (state != null && index >= 0 && index < state!.invitados.length) {
      final updatedList = List<String>.from(state!.invitados);
      updatedList[index] = newName;
      state = state!.copyWith(invitados: updatedList);
    }
  }

  void removeInvitado(int index) {
    if (state != null && index >= 0 && index < state!.invitados.length) {
      final updatedList = List<String>.from(state!.invitados)..removeAt(index);
      state = state!.copyWith(invitados: updatedList);
    }
  }
}
