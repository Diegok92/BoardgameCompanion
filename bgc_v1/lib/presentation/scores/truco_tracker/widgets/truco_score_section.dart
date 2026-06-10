import 'package:flutter/material.dart';

import 'truco_score_mark.dart';

class TrucoScoreSection extends StatelessWidget {
  final String title;
  final Color labelColor;
  final int points;
  final VoidCallback onAddPoint;
  final bool showLabel;

  const TrucoScoreSection({
    super.key,
    required this.title,
    required this.labelColor,
    required this.points,
    required this.onAddPoint,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePoints = points.clamp(0, 15).toInt();

    return Column(
      children: [
        if (showLabel) ...[
          Container(
            width: 92,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAddPoint,
          child: Column(
            children: List.generate(3, (groupIndex) {
              final startIndex = groupIndex * 5;

              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (matchIndex) {
                    final absoluteIndex = startIndex + matchIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: TrucoScoreMark(
                        isActive: absoluteIndex < visiblePoints,
                        index: matchIndex,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
