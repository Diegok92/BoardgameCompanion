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

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }

  Future<void> deleteAccount() async {
    if (state != null) {
      await _repository.softDeleteUser(state!.id);
      state = null;
    }
  }

  Future<void> updateUser(User updatedUser) async {
    if (state != null) {
      await _repository.updateUser(updatedUser);
      state = updatedUser;
    }
  }

  Future<void> addInvitado(String nombreInvitado) async {
    if (state != null) {
      final updatedList = List<String>.from(state!.invitados)
        ..add(nombreInvitado);
      await updateUser(state!.copyWith(invitados: updatedList));
    }
  }

  Future<void> editInvitado(int index, String newName) async {
    if (state != null && index >= 0 && index < state!.invitados.length) {
      final updatedList = List<String>.from(state!.invitados);
      updatedList[index] = newName;
      await updateUser(state!.copyWith(invitados: updatedList));
    }
  }

  Future<void> removeInvitado(int index) async {
    if (state != null && index >= 0 && index < state!.invitados.length) {
      final updatedList = List<String>.from(state!.invitados)..removeAt(index);
      await updateUser(state!.copyWith(invitados: updatedList));
    }
  }
}
