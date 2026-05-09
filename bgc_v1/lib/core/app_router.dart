import 'package:go_router/go_router.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/register/register_screen.dart';
import '../presentation/home/home_screen.dart';
import '../domain/models/user_model.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final user = state.extra as User;
        return HomeScreen(user: user);
      },
    ),
  ],
);
