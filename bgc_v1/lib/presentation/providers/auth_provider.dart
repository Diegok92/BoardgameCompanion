import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';

// Provider que expone y permite mutar el estado del usuario logueado.
// Retorna 'null' si no hay sesión activa.
final authProvider = NotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null; // Inicialmente no hay usuario logueado
  }

  void login(User user) {
    state = user;
  }

  void logout() {
    state = null;
  }

  void updateUser(User updatedUser) {
    // Solo actualizamos si hay un usuario logueado
    if (state != null) {
      // Opcional: También podríamos buscarlo en la DB simulada y actualizarlo ahí
      // para que persista, pero por ahora solo actualizamos la sesión activa.
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
