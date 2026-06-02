import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'providers/sand_timer_provider.dart';
import 'widgets/accessory_control_bar.dart';
import 'widgets/accessory_resume_dialog.dart';
import 'widgets/accessory_time_dialog.dart';

class SandTimerScreen extends ConsumerStatefulWidget {
  const SandTimerScreen({super.key});

  @override
  ConsumerState<SandTimerScreen> createState() => _SandTimerScreenState();
}

class _SandTimerScreenState extends ConsumerState<SandTimerScreen> {
  static const Color _accent = AppColors.purple;
  static const List<int> _timeOptions = [30, 60, 180, 300, 600, 900, 1800];

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final isNew = await ref.read(sandTimerProvider.notifier).initialize(user);
    if (!mounted) return;
    setState(() => _initialized = true);
    if (isNew) {
      _showTimeDialog();
    } else {
      // Había un temporizador pausado: preguntar si retomar o arrancar uno nuevo.
      AccessoryResumeDialog.show(
        context,
        onResume: () {}, // El estado ya quedó restaurado (pausado).
        onNew: _showTimeDialog,
      );
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _goBack() {
    ref.read(sandTimerProvider.notifier).pause();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/accessories');
    }
  }

  void _showTimeDialog() {
    AccessoryTimeDialog.show(
      context,
      title: '¿De cuánto tiempo será el reloj?',
      optionsSeconds: _timeOptions,
      onSelect: (seconds) =>
          ref.read(sandTimerProvider.notifier).setInitialSeconds(seconds),
    );
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¡TIEMPO AGOTADO!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: _accent,
          ),
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
              ref.read(sandTimerProvider.notifier).reset();
            },
            child: const Text('REINICIAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(sandTimerProvider);

    // Mostrar el diálogo de tiempo agotado cuando llega a 0.
    ref.listen<SandTimerState>(sandTimerProvider, (previous, next) {
      final justFinished =
          previous != null &&
          previous.remainingSeconds > 0 &&
          next.remainingSeconds == 0 &&
          next.hasStarted;
      if (justFinished) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showFinishedDialog();
        });
      }
    });

    return PopScope(
      // Al salir (botón atrás o gesto del sistema) pausamos para conservar
      // el tiempo remanente detenido al volver a entrar.
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(sandTimerProvider.notifier).pause();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 170,
                      height: 234,
                      child: CustomPaint(
                        painter: HourglassPainter(
                          progress: state.progress,
                          isRunning: state.isRunning,
                          frameColor: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(state.remainingSeconds),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 96,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: state.isFinished
                            ? _accent
                            : colorScheme.onSurface,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AccessoryControlBar(
                    height: 92,
                    iconSize: 46,
                    onPlay: () => ref.read(sandTimerProvider.notifier).start(),
                    onPause: () => ref.read(sandTimerProvider.notifier).pause(),
                    onStop: () => ref.read(sandTimerProvider.notifier).reset(),
                    onRestart: _showTimeDialog,
                  ),
                ),
              ),
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
        onPressed: _goBack,
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
}

class HourglassPainter extends CustomPainter {
  final double progress; // 1.0 = lleno (inicio), 0.0 = vacío (terminado)
  final bool isRunning;
  final Color frameColor;

  const HourglassPainter({
    required this.progress,
    required this.isRunning,
    required this.frameColor,
  });

  static const Color _sandRemaining = Color(0xFFCE93D8); // morado claro
  static const Color _sandAccumulated = AppColors.purple;

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
        ..color = frameColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    final barPaint = Paint()
      ..color = frameColor
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
      oldDelegate.progress != progress ||
      oldDelegate.isRunning != isRunning ||
      oldDelegate.frameColor != frameColor;
}
