import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key});

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen>
    with SingleTickerProviderStateMixin {
  static const Color orangeColor = Color(0xFFFFA726);

  late final AnimationController _controller;
  late final Animation<double> _animation;

  String _coinResult = 'CARA';
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0, end: pi * 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final result = Random().nextBool() ? 'CARA' : 'CRUZ';

        setState(() {
          _coinResult = result;
          _isFlipping = false;
        });

        _controller.reset();
      }
    });
  }

  void _flipCoin() {
    if (_isFlipping) return;

    setState(() {
      _isFlipping = true;
    });

    _controller.forward();
  }

  void _goBackToAccessories() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu, size: 28, color: Color(0xFF1F2937)),
        onPressed: () {},
      ),
      title: const Text(
        'BG Companion',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          color: Color(0xFF1F2937),
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.cases_rounded,
                color: Color(0xFFEF3743),
                size: 28,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF3743),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
      backgroundColor: const Color(0xFFF3F6FA),
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              const Spacer(),

              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final rotation = _animation.value;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotation),
                    child: CoinWidget(text: _isFlipping ? '...' : _coinResult),
                  );
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _flipCoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isFlipping ? 'TIRANDO...' : 'TIRAR MONEDA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _goBackToAccessories,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(
                      color: Color(0xFF4B5563),
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'VOLVER A ACCESORIOS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoinWidget extends StatelessWidget {
  final String text;

  const CoinWidget({super.key, required this.text});

  static const Color orangeColor = Color(0xFFFFA726);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CoinPainter(),
      child: SizedBox(
        width: 210,
        height: 210,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: orangeColor,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class CoinPainter extends CustomPainter {
  static const Color orangeColor = Color(0xFFFFA726);
  static const Color lightOrange = Color(0xFFFFF3D6);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final outerGlowPaint = Paint()
      ..color = lightOrange
      ..style = PaintingStyle.fill;

    final coinPaint = Paint()
      ..color = const Color(0xFFFFFAED)
      ..style = PaintingStyle.fill;

    final outerBorderPaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final innerBorderPaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dashedPaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rayPaint = Paint()
      ..color = orangeColor.withOpacity(0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 4, outerGlowPaint);
    canvas.drawCircle(center, radius - 18, coinPaint);
    canvas.drawCircle(center, radius - 22, outerBorderPaint);
    canvas.drawCircle(center, radius - 34, innerBorderPaint);

    _drawDashedCircle(
      canvas: canvas,
      center: center,
      radius: radius - 42,
      paint: dashedPaint,
    );

    _drawRays(canvas: canvas, center: center, radius: radius, paint: rayPaint);
  }

  void _drawDashedCircle({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Paint paint,
  }) {
    const int dashCount = 44;
    const double dashAngle = pi / 55;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (2 * pi / dashCount) * i;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  void _drawRays({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Paint paint,
  }) {
    final rayData = [
      {'angle': -pi / 2, 'start': 1.08, 'end': 1.16},
      {'angle': -pi / 3.5, 'start': 1.05, 'end': 1.14},
      {'angle': -pi + pi / 3.5, 'start': 1.05, 'end': 1.14},
    ];

    for (final ray in rayData) {
      final angle = ray['angle']!;
      final startMultiplier = ray['start']!;
      final endMultiplier = ray['end']!;

      final start = Offset(
        center.dx + cos(angle) * radius * startMultiplier,
        center.dy + sin(angle) * radius * startMultiplier,
      );

      final end = Offset(
        center.dx + cos(angle) * radius * endMultiplier,
        center.dy + sin(angle) * radius * endMultiplier,
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
