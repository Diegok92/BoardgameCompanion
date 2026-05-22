import 'package:flutter/material.dart';

class TrackerBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;
  final Widget centerWidget;

  const TrackerBottomBar({
    super.key,
    required this.onBack,
    required this.onSave,
    required this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Back Button
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filledTonal(
                iconSize: 28,
                padding: const EdgeInsets.all(12),
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            ),
          ),
          
          // Center Widget (Custom reset logic / hp input depending on the tracker)
          centerWidget,
          
          // Save Button
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton.filled(
                iconSize: 28,
                padding: const EdgeInsets.all(12),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                icon: const Icon(Icons.save),
                onPressed: onSave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
