import 'package:go_router/go_router.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/register/register_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/invitados/register_invitado_screen.dart';
import '../presentation/profile/user_edit_screen.dart';
import '../presentation/scores/score_selector_screen.dart';
import '../presentation/scores/hp_tracker/hp_tracker_screen.dart';
import '../presentation/scores/burako_tracker/burako_tracker_screen.dart';
import '../presentation/accessories/accessories_screen.dart';
import '../presentation/accessories/coin_flip_screen.dart';
import '../presentation/accessories/dice_screen.dart';
import '../presentation/settings/config_screen.dart';
import '../presentation/scores/akropolis_tracker/akropolis_tracker_screen.dart';
import '../presentation/stats/stats_screen.dart';
import '../presentation/historial/historial_screen.dart';

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
      path: '/hp-tracker',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final playerCount = extras?['playerCount'] as int? ?? 2;
        final fullKey = extras?['fullKey'] as String?;
        return HpTrackerScreen(playerCount: playerCount, fullKey: fullKey);
      },
    ),
    GoRoute(
      path: '/burako-tracker',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final playerCount = extras?['playerCount'] as int? ?? 2;
        final fullKey = extras?['fullKey'] as String?;
        return BurakoTrackerScreen(playerCount: playerCount, fullKey: fullKey);
      },
    ),
    GoRoute(
      path: '/akropolis-tracker',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final playerCount = extras?['playerCount'] as int? ?? 2;
        final fullKey = extras?['fullKey'] as String?;
        return AkropolisTrackerScreen(playerCount: playerCount, fullKey: fullKey);
      },
    ),
    GoRoute(
      path: '/config',
      builder: (context, state) {
        return const ConfigScreen();
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
        GoRoute(
      path: '/dice-roll',
      builder: (context, state) {
        return const DiceRollScreen();
      },
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) {
        return const StatsScreen();
      },
    ),
    GoRoute(
      path: '/historial',
      builder: (context, state) {
        return const HistorialScreen();
      },
    ),
  ],
);
