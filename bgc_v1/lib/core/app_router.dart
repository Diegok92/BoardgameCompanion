import 'package:go_router/go_router.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/register/register_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/invitados/register_invitado_screen.dart';
import '../presentation/profile/user_edit_screen.dart';
import '../presentation/scores/score_selector_screen.dart';
import '../presentation/accessories/accessories_screen.dart';
import '../presentation/accessories/coin_flip_screen.dart';

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
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/register-invitado',
      builder: (context, state) {
        return const RegisterInvitadoScreen();
      },
    ),
    GoRoute(
      path: '/user-edit',
      builder: (context, state) {
        return const UserEditScreen();
      },
    ),
    GoRoute(
      path: '/score-selector',
      builder: (context, state) {
        return const ScoreSelectorScreen();
      },
    ),
    GoRoute(
      path: '/accessories',
      builder: (context, state) {
        return const AccessoriesScreen();
      },
    ),
    GoRoute(
      path: '/coin-flip',
      builder: (context, state) {
        return const CoinFlipScreen();
      },
    ),
  ],
);
