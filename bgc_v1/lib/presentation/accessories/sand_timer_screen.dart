import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

class SandTimerScreen extends StatefulWidget {
  const SandTimerScreen({super.key});

  @override
  State<SandTimerScreen> createState() => _SandTimerScreenState();
}

class _SandTimerScreenState extends State<SandTimerScreen> {
  static const Color _accent = AppColors.purple;

  int _initialMinutes = 1;
  late int _remainingSeconds;
  bool _isRunning = false;
  bool _hasStarted = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _initialMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress => _remainingSeconds / (_initialMinutes * 60);

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _start() {
    if (_isRunning || _remainingSeconds == 0) return;
    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds == 0) {
            _isRunning = false;
            _timer?.cancel();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showFinishedDialog();
            });
          }
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _hasStarted = false;
      _remainingSeconds = _initialMinutes * 60;
    });
  }

  void _incrementTime() {
    if (_hasStarted || _initialMinutes >= 60) return;
    setState(() {
      _initialMinutes++;
      _remainingSeconds = _initialMinutes * 60;
    });
  }

  void _decrementTime() {
    if (_hasStarted || _initialMinutes <= 1) return;
    setState(() {
      _initialMinutes--;
      _remainingSeconds = _initialMinutes * 60;
    });
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¡TIEMPO AGOTADO!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _accent),
        ),
        content: const Text(
          'El tiempo del Reloj de Arena terminó.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              Navigator.of(context).pop();
              _reset();
            },
            child: const Text('REINICIAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool timedOut = _hasStarted && _remainingSeconds == 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Text(
                'Setea el Tiempo Inicial',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeSetter(),
              const Spacer(),
              SizedBox(
                width: 160,
                height: 220,
                child: CustomPaint(
                  painter: HourglassPainter(
                    progress: _progress,
                    isRunning: _isRunning,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 72,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: timedOut ? _accent : colorScheme.onSurface,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              _buildButtons(timedOut),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 32),
        onPressed: () {
          _timer?.cancel();
          Navigator.of(context).pop();
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BG Companion',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset('assets/images/logo.svg', height: 24),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildTimeSetter() {
    final bool disabled = _hasStarted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade400 : _accent,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: disabled ? null : _decrementTime,
            iconSize: 22,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatTime(_initialMinutes * 60),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: disabled ? null : _incrementTime,
            iconSize: 22,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(bool timedOut) {
    final bool canStart = !_isRunning && _remainingSeconds > 0;
    final String startLabel =
        (_hasStarted && !_isRunning && !timedOut) ? 'REANUDAR' : 'COMENZAR';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canStart ? _start : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              startLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isRunning ? _pause : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isRunning
                          ? Colors.grey.shade600
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'PAUSAR',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: _isRunning
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _hasStarted ? _reset : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _hasStarted
                          ? AppColors.red
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'REINICIAR',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: _hasStarted ? AppColors.red : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HourglassPainter extends CustomPainter {
  final double progress; // 1.0 = lleno (inicio), 0.0 = vacío (terminado)
  final bool isRunning;

  const HourglassPainter({required this.progress, required this.isRunning});

  static const Color _sandRemaining = Color(0xFFCE93D8); // morado claro
  static const Color _sandAccumulated = AppColors.purple;
  static const Color _frame = Color(0xFF37474F);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const barH = 10.0;
    const topY = barH;
    final bottomY = h - barH;
    final midY = h / 2;

    final topTriangle = Path()
      ..moveTo(0, topY)
      ..lineTo(w, topY)
      ..lineTo(cx, midY)
      ..close();

    final bottomTriangle = Path()
      ..moveTo(cx, midY)
      ..lineTo(0, bottomY)
      ..lineTo(w, bottomY)
      ..close();

    // Arena restante (mitad superior — el nivel cae desde arriba hacia la cintura)
    if (progress > 0.001) {
      canvas.save();
      canvas.clipPath(topTriangle);
      final fillTop = topY + (1 - progress) * (midY - topY);
      canvas.drawRect(
        Rect.fromLTWH(0, fillTop, w, midY - fillTop),
        Paint()
          ..color = _sandRemaining
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }

    // Arena acumulada (mitad inferior — crece con el tiempo)
    if (progress < 0.999) {
      canvas.save();
      canvas.clipPath(bottomTriangle);
      final accFillTop = midY + progress * (bottomY - midY);
      canvas.drawRect(
        Rect.fromLTWH(0, accFillTop, w, bottomY - accFillTop),
        Paint()
          ..color = _sandAccumulated
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }

    // Contorno del reloj de arena
    final hourglassPath = Path()
      ..moveTo(0, topY)
      ..lineTo(w, topY)
      ..lineTo(cx, midY)
      ..lineTo(w, bottomY)
      ..lineTo(0, bottomY)
      ..lineTo(cx, midY)
      ..close();

    canvas.drawPath(
      hourglassPath,
      Paint()
        ..color = _frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    final barPaint = Paint()
      ..color = _frame
      ..style = PaintingStyle.fill;

    // Barra superior
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-3, 0, w + 6, barH),
        const Radius.circular(3),
      ),
      barPaint,
    );
    // Barra inferior
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-3, bottomY, w + 6, barH),
        const Radius.circular(3),
      ),
      barPaint,
    );

    // Hilo de arena cayendo (visible mientras corre y hay arena)
    if (isRunning && progress > 0.02) {
      canvas.drawLine(
        Offset(cx, midY),
        Offset(cx, midY + 14),
        Paint()
          ..color = _sandAccumulated.withValues(alpha: 0.7)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(HourglassPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isRunning != isRunning;
}
