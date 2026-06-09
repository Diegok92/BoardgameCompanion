import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DiceLockWrapper extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final VoidCallback onTapLock;

  const DiceLockWrapper({
    super.key,
    required this.child,
    required this.isLocked,
    required this.onTapLock,
  });

  static const Color redColor = AppColors.red;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTapLock,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 34,
            decoration: BoxDecoration(
              color: isLocked
                  ? redColor
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLocked
                    ? redColor
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              color: isLocked
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class DiceWidget extends StatelessWidget {
  final String result;
  final String diceType;
  final double size;
  final bool isLocked;

  const DiceWidget({
    super.key,
    required this.result,
    required this.diceType,
    this.size = 220,
    this.isLocked = false,
  });

  static const Color redColor = AppColors.red;
  static const Color grayColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DicePainter(isLocked: isLocked),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result,
                style: TextStyle(
                  color: redColor,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: size * 0.04),
              Text(
                diceType,
                style: TextStyle(
                  color: grayColor,
                  fontSize: size * 0.10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DicePainter extends CustomPainter {
  final bool isLocked;

  DicePainter({required this.isLocked});

  static const Color redColor = AppColors.red;
  static const Color lightRed = Color(0xFFFFE5E8);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.08,
      size.width * 0.84,
      size.height * 0.84,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.14));

    canvas.drawRRect(
      rrect.shift(Offset(0, size.height * 0.035)),
      Paint()..color = redColor.withValues(alpha: isLocked ? 0.20 : 0.12),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isLocked ? redColor.withValues(alpha: 0.75) : redColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.022,
    );

    final dotRadius = size.width * 0.035;
    final offset = size.width * 0.17;
    final dotPaint = Paint()..color = lightRed;

    for (final point in [
      Offset(rect.left + offset, rect.top + offset),
      Offset(rect.right - offset, rect.top + offset),
      Offset(rect.left + offset, rect.bottom - offset),
      Offset(rect.right - offset, rect.bottom - offset),
    ]) {
      canvas.drawCircle(point, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) =>
      oldDelegate.isLocked != isLocked;
}