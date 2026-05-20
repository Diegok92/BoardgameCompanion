import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class PlayerColorPicker extends StatelessWidget {
  final Color playerColor;
  final Set<int> usedColorsArgb;
  final ValueChanged<Color> onColorChanged;

  const PlayerColorPicker({
    super.key,
    required this.playerColor,
    required this.usedColorsArgb,
    required this.onColorChanged,
  });

  void _showColorPicker(BuildContext context) {
    final available = AppColors.availableColors
        .where(
          (c) =>
              !usedColorsArgb.contains(c.toARGB32()) ||
              c.toARGB32() == playerColor.toARGB32(),
        )
        .toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elegir Color'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: available.map((color) {
              return GestureDetector(
                onTap: () {
                  onColorChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: playerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26, width: 1),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: playerColor, size: 22),
        ],
      ),
    );
  }
}
