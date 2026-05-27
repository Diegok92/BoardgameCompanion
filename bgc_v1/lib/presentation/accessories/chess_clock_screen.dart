import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChessClockScreen extends StatefulWidget {
  const ChessClockScreen({super.key});

  @override
  State<ChessClockScreen> createState() => _ChessClockScreenState();
}

class _ChessClockScreenState extends State<ChessClockScreen> {
  static const int initialSeconds = 300; // 5 minutos

  Timer? _timer;

  int _playerOneSeconds = initialSeconds;
  int _playerTwoSeconds = initialSeconds;

  int _activePlayer = 1;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    if (_isRunning) return;

    if (_playerOneSeconds == 0 || _playerTwoSeconds == 0) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (_activePlayer == 1) {
          if (_playerOneSeconds > 0) {
            _playerOneSeconds--;
          }

          if (_playerOneSeconds == 0) {
            _timer?.cancel();
            _isRunning = false;
          }
        } else {
          if (_playerTwoSeconds > 0) {
            _playerTwoSeconds--;
          }

          if (_playerTwoSeconds == 0) {
            _timer?.cancel();
            _isRunning = false;
          }
        }
      });
    });
  }

  void _stopClockAndChangeTurn() {
    if (!_isRunning) return;

    _timer?.cancel();

    setState(() {
      _isRunning = false;

      if (_playerOneSeconds > 0 && _playerTwoSeconds > 0) {
        _activePlayer = _activePlayer == 1 ? 2 : 1;
      }
    });
  }

  void _resetClock() {
    _timer?.cancel();

    setState(() {
      _playerOneSeconds = initialSeconds;
      _playerTwoSeconds = initialSeconds;
      _activePlayer = 1;
      _isRunning = false;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _playerOneLost => _playerOneSeconds == 0;
  bool get _playerTwoLost => _playerTwoSeconds == 0;

  void _goBack() {
    _timer?.cancel();

    if (context.canPop()) {
      context.pop();
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D83DF),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 390,
            constraints: const BoxConstraints(maxWidth: 430),
            color: const Color(0xFF111827),
            child: Column(
              children: [
                Expanded(
                  child: Transform.rotate(
                    angle: pi,
                    child: ChessPlayerPanel(
                      title: _activePlayer == 1 ? 'TU TURNO' : 'JUGADOR 1',
                      time: _formatTime(_playerOneSeconds),
                      subtitle: _playerOneLost
                          ? 'TIEMPO TERMINADO'
                          : _activePlayer == 1
                          ? _isRunning
                                ? 'EN CURSO'
                                : 'LISTO PARA COMENZAR'
                          : 'ESPERANDO...',
                      isActive: _activePlayer == 1,
                      isLost: _playerOneLost,
                    ),
                  ),
                ),

                Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  color: const Color(0xFF0B1220),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClockActionButton(
                          text: 'REINICIAR',
                          color: const Color(0xFF4B5563),
                          onTap: _resetClock,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClockActionButton(
                          text: 'DETENER',
                          color: const Color(0xFFEF3743),
                          onTap: _stopClockAndChangeTurn,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClockActionButton(
                          text: 'COMENZAR',
                          color: const Color(0xFF18B979),
                          onTap: _startClock,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ChessPlayerPanel(
                    title: _activePlayer == 2
                        ? 'TU TURNO'
                        : 'TURNO del OPONENTE',
                    time: _formatTime(_playerTwoSeconds),
                    subtitle: _playerTwoLost
                        ? 'TIEMPO TERMINADO'
                        : _activePlayer == 2
                        ? _isRunning
                              ? 'EN CURSO'
                              : 'LISTO PARA COMENZAR'
                        : 'ESPERANDO...',
                    isActive: _activePlayer == 2,
                    isLost: _playerTwoLost,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: _goBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'VOLVER A ACCESORIOS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChessPlayerPanel extends StatelessWidget {
  final String title;
  final String time;
  final String subtitle;
  final bool isActive;
  final bool isLost;

  const ChessPlayerPanel({
    super.key,
    required this.title,
    required this.time,
    required this.subtitle,
    required this.isActive,
    required this.isLost,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? const Color(0xFF2F7DF4)
        : Colors.white.withValues(alpha: 0.08);

    final timeColor = isLost
        ? const Color(0xFFEF3743)
        : isActive
        ? Colors.white
        : Colors.white.withValues(alpha: 0.45);

    final titleColor = isActive
        ? const Color(0xFF2F7DF4)
        : Colors.white.withValues(alpha: 0.65);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: isActive ? 3 : 1),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: const Color(0xFF2F7DF4).withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            time,
            style: TextStyle(
              color: timeColor,
              fontSize: 68,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLost
                  ? const Color(0xFFEF3743)
                  : Colors.white.withValues(alpha: 0.55),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ClockActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const ClockActionButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
