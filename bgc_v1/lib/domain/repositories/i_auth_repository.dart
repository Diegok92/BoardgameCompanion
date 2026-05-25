import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<User?> login(String email, String password);
  Future<User> register(User newUser);
  Future<void> updateUser(User user);
  Future<void> logout();
  Future<void> softDeleteUser(String userId);
}
