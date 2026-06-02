import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/chess_clock_provider.dart';
import '../providers/auth_provider.dart';

import '../scores/widgets/tracker_dialogs.dart';
import 'widgets/accessory_control_bar.dart';
import 'widgets/accessory_resume_dialog.dart';
import 'widgets/accessory_time_dialog.dart';

class ChessClockScreen extends ConsumerStatefulWidget {
  const ChessClockScreen({super.key});

  @override
  ConsumerState<ChessClockScreen> createState() => _ChessClockScreenState();
}

class _ChessClockScreenState extends ConsumerState<ChessClockScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initClock();
    });
  }

  Future<void> _initClock() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final isNew = await ref.read(chessClockProvider.notifier).initialize(user);
    if (mounted) {
      setState(() {
        _initialized = true;
      });
      if (isNew) {
        _showTimeDialog();
      } else {
        // Había una partida pausada: preguntar si retomar o arrancar de nuevo.
        AccessoryResumeDialog.show(
          context,
          onResume: () {}, // El estado ya quedó restaurado (pausado).
          onNew: _showTimeDialog,
        );
      }
    }
  }

  void _showTimeDialog() {
    AccessoryTimeDialog.show(
      context,
      title: '¿De cuántos minutos será la partida?',
      optionsSeconds: const [60, 180, 300, 600, 900, 1800],
      onSelect: (seconds) =>
          ref.read(chessClockProvider.notifier).setInitialSeconds(seconds),
    );
  }

  void _showOutOfTimeDialog(String playerName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '¡TIEMPO AGOTADO!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          content: Text(
            '$playerName SE QUEDÓ SIN TIEMPO',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ACEPTAR'),
            ),
          ],
        );
      },
    );
  }

  void _editPlayer(int player, String currentName, Color currentColor) {
    final user = ref.read(authProvider);
    final state = ref.read(chessClockProvider);

    // Datos del otro jugador, para no permitir repetir nombre ni color.
    final otherName = player == 1 ? state.playerTwoName : state.playerOneName;
    final otherColor = player == 1
        ? state.playerTwoColor
        : state.playerOneColor;

    TrackerDialogs.showEntityEditor(
      context: context,
      entityName: player == 1 ? 'Jugador 1' : 'Jugador 2',
      entityId: '',
      entityColor: currentColor,
      entityIndex: player == 1 ? 0 : 1,
      loggedInUsername: user?.username,
      invitados: user?.invitados ?? [],
      assignedNames: [otherName],
      assignedColors: [otherColor],
      onNameChanged: (name) => ref
          .read(chessClockProvider.notifier)
          .updatePlayer(player, name: name),
      onColorChanged: (color) => ref
          .read(chessClockProvider.notifier)
          .updatePlayer(player, color: color),
      onAddInvitado: () {
        Navigator.pop(context);
        context.push('/register-invitado');
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final state = ref.watch(chessClockProvider);
    final notifier = ref.read(chessClockProvider.notifier);

    ref.listen<ChessClockState>(chessClockProvider, (previous, next) {
      if (previous != null &&
          previous.playerOneSeconds > 0 &&
          next.playerOneSeconds == 0) {
        _showOutOfTimeDialog(next.playerOneName);
      } else if (previous != null &&
          previous.playerTwoSeconds > 0 &&
          next.playerTwoSeconds == 0) {
        _showOutOfTimeDialog(next.playerTwoName);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      // Al salir (botón atrás o gesto del sistema) pausamos para conservar
      // el estado de los relojes al volver a entrar.
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) notifier.pause();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Panel Superior (Jugador 2) - Invertido
              Expanded(
                child: Transform.rotate(
                  angle: pi,
                  child: _buildPlayerPanel(
                    player: 2,
                    name: state.playerTwoName,
                    color: state.playerTwoColor,
                    seconds: state.playerTwoSeconds,
                    isActive: state.activePlayer == 2,
                    isRunning: state.isRunning,
                    onTapPanel: () {
                      if (state.activePlayer == 2 && state.isRunning) {
                        notifier.switchTurn();
                      }
                    },
                  ),
                ),
              ),

              // Barra de control central
              AccessoryControlBar(
                onBack: () {
                  notifier.pause();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                onPlay: () => notifier.start(),
                onPause: () => notifier.pause(),
                onStop: () => notifier.stop(),
                onRestart: _showTimeDialog,
              ),

              // Panel Inferior (Jugador 1)
              Expanded(
                child: _buildPlayerPanel(
                  player: 1,
                  name: state.playerOneName,
                  color: state.playerOneColor,
                  seconds: state.playerOneSeconds,
                  isActive: state.activePlayer == 1,
                  isRunning: state.isRunning,
                  onTapPanel: () {
                    if (state.activePlayer == 1 && state.isRunning) {
                      notifier.switchTurn();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerPanel({
    required int player,
    required String name,
    required Color color,
    required int seconds,
    required bool isActive,
    required bool isRunning,
    required VoidCallback onTapPanel,
  }) {
    final bool isLost = seconds == 0;

    return GestureDetector(
      onTap: onTapPanel,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive && isRunning ? color : color.withValues(alpha: 0.3),
            width: isActive && isRunning ? 4 : 2,
          ),
          boxShadow: [
            if (isActive && isRunning)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.edit, color: color.withValues(alpha: 0.8)),
                onPressed: () => _editPlayer(player, name, color),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatTime(seconds),
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: isLost
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLost
                        ? 'TIEMPO AGOTADO'
                        : (isActive
                              ? (isRunning ? 'TU TURNO' : 'LISTO')
                              : 'ESPERANDO'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLost
                          ? Colors.red
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
