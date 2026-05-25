import 'package:flutter/material.dart';

class PlayerBadge extends StatelessWidget {
  final String name;
  final Color color;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const PlayerBadge({
    super.key,
    required this.name,
    required this.color,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name.toUpperCase(),
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }
}
