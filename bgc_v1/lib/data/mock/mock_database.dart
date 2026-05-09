import '../../domain/models/user_model.dart';

class MockDatabase {
  static final List<User> users = [
    User(
      id: '1',
      username: 'MagoSupremo',
      email: 'mago@test.com',
      password: 'password123',
    ),
    User(
      id: '2',
      username: 'Caro',
      email: 'caro@test.com',
      password: 'password123',
    ),
    User(id: '3', username: 'Diego', email: 'diego', password: '123'),
  ];

  static User? authenticate(String email, String password) {
    try {
      return users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}
