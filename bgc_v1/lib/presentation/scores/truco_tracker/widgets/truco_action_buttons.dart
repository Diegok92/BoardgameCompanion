import 'package:flutter/material.dart';

class TrucoActionButtons extends StatelessWidget {
  final Color color;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const TrucoActionButtons({
    super.key,
    required this.color,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TrucoCircleButton(
          icon: Icons.add,
          backgroundColor: color,
          foregroundColor: Colors.white,
          onPressed: onAdd,
        ),
        _TrucoCircleButton(
          icon: Icons.remove,
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class _TrucoCircleButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _TrucoCircleButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: const CircleBorder(),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 22,
        ),
      ),
    );
  }
}