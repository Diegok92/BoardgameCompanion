import 'package:flutter/material.dart';
import 'dart:async';

class CustomAlert {
  static void show(BuildContext context, String message, {bool isError = false, String? title}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black12,
      builder: (BuildContext dialogContext) {
        return _CustomAlertDialog(message: message, isError: isError, title: title);
      },
    );
  }
}

class _CustomAlertDialog extends StatefulWidget {
  final String message;
  final bool isError;
  final String? title;

  const _CustomAlertDialog({required this.message, this.isError = false, this.title});

  @override
  State<_CustomAlertDialog> createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<_CustomAlertDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: widget.isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: TextStyle(
                  color: widget.isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              widget.message,
              style: TextStyle(
                color: widget.isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
