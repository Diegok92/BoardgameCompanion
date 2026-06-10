import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Diálogo calculadora reutilizable: permite componer una expresión con
/// sumas y restas y devuelve el resultado evaluado al confirmar.
///
/// Lo usan el anotador de Burako (calcular fichas) y el anotador de puntos
/// estándar (sumar puntos). Devuelve un `int` al confirmar, o `null` si se
/// descarta el diálogo.
class CalculatorDialog extends StatefulWidget {
  final int initialValue;
  final String title;

  const CalculatorDialog({
    super.key,
    this.initialValue = 0,
    this.title = 'Calcular Fichas',
  });

  /// Helper para abrir el diálogo y obtener el resultado.
  static Future<int?> show(
    BuildContext context, {
    int initialValue = 0,
    String title = 'Calcular Fichas',
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) =>
          CalculatorDialog(initialValue: initialValue, title: title),
    );
  }

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _expression = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != 0) {
      _expression = widget.initialValue.toString();
    }
  }

  void _onPressed(String text) {
    setState(() {
      if (_expression == 'Error') _expression = '';
      _expression += text;
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
    });
  }

  void _delete() {
    setState(() {
      if (_expression == 'Error') {
        _expression = '';
      } else if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  int _evaluate(String exp) {
    try {
      if (exp.isEmpty) return 0;

      bool startsWithNegative = exp.startsWith('-');
      if (startsWithNegative) {
        exp = exp.substring(1);
      }

      var terms = exp.split('+');
      int sum = 0;
      for (int t = 0; t < terms.length; t++) {
        var term = terms[t];
        var subTerms = term.split('-');
        int termVal = int.tryParse(subTerms[0]) ?? 0;

        if (t == 0 && startsWithNegative) {
          termVal = -termVal;
        }

        for (int i = 1; i < subTerms.length; i++) {
          termVal -= int.tryParse(subTerms[i]) ?? 0;
        }
        sum += termVal;
      }
      return sum;
    } catch (e) {
      throw Exception('Error');
    }
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    try {
      int result = _evaluate(_expression);
      setState(() {
        _expression = result.toString();
      });
    } catch (e) {
      setState(() {
        _expression = 'Error';
      });
    }
  }

  void _confirm() {
    int result = 0;
    if (_expression.isNotEmpty && _expression != 'Error') {
      try {
        result = _evaluate(_expression);
      } catch (_) {}
    }
    Navigator.of(context).pop(result);
  }

  Widget _buildButton(
    String text, {
    Color? color,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                color ?? Theme.of(context).colorScheme.surfaceContainer,
            foregroundColor:
                textColor ?? Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onTap ?? () => _onPressed(text),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _expression.isEmpty ? '0' : _expression,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 32,
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildButton('7'),
                _buildButton('8'),
                _buildButton('9'),
                _buildButton(
                  'C',
                  color: cs.errorContainer,
                  textColor: cs.onErrorContainer,
                  onTap: _clear,
                ),
              ],
            ),
            Row(
              children: [
                _buildButton('4'),
                _buildButton('5'),
                _buildButton('6'),
                _buildButton(
                  '⌫',
                  color: cs.tertiaryContainer,
                  textColor: cs.onTertiaryContainer,
                  onTap: _delete,
                ),
              ],
            ),
            Row(
              children: [
                _buildButton('1'),
                _buildButton('2'),
                _buildButton('3'),
                _buildButton(
                  '+',
                  color: cs.secondaryContainer,
                  textColor: cs.onSecondaryContainer,
                ),
              ],
            ),
            Row(
              children: [
                _buildButton('0'),
                _buildButton(
                  '=',
                  color: cs.primary,
                  textColor: cs.onPrimary,
                  onTap: _calculate,
                ),
                _buildButton(
                  '-',
                  color: cs.secondaryContainer,
                  textColor: cs.onSecondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirm,
                child: const Text(
                  'CONFIRMAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
