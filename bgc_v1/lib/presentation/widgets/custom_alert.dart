import 'package:flutter/material.dart';
import 'dart:async';

class CustomAlert {
  static void show(BuildContext context, String message, {bool isError = false, String? title}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black12,
      builder: (BuildContext dialogContext) {
        Timer(const Duration(seconds: 3), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });
        
        final colorScheme = Theme.of(context).colorScheme;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                      color: isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
