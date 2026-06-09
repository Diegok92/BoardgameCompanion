import 'dart:math';

import 'package:flutter/material.dart';

class TrucoScoreMark extends StatelessWidget {
  final bool isActive;
  final int index;

  const TrucoScoreMark({
    super.key,
    required this.isActive,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return const SizedBox(
        width: 18,
        height: 42,
      );
    }

    final isDiagonal = index == 4;

    return SizedBox(
      width: 18,
      height: 42,
      child: Center(
        child: Transform.rotate(
          angle: isDiagonal ? -pi / 4 : 0,
          child: const _MatchStick(),
        ),
      ),
    );
  }
}

class _MatchStick extends StatelessWidget {
  const _MatchStick();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 7,
      height: 36,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 5,
            child: Container(
              width: 4,
              height: 29,
              decoration: BoxDecoration(
                color: const Color(0xFFD6A15F),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Container(
            width: 7,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}