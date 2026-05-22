import 'package:flutter/material.dart';

class FichasCalculatorDialog extends StatefulWidget {
  final int initialValue;

  const FichasCalculatorDialog({super.key, this.initialValue = 0});

  @override
  State<FichasCalculatorDialog> createState() => _FichasCalculatorDialogState();
}

class _FichasCalculatorDialogState extends State<FichasCalculatorDialog> {
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
      
      // Permitir un negativo al principio
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
        
        // Aplicar el negativo inicial al primer término
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

  Widget _buildButton(String text, {Color? color, Color? textColor, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: textColor ?? Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Calcular Fichas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _expression.isEmpty ? '0' : _expression,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Teclado
            Row(
              children: [
                _buildButton('7'),
                _buildButton('8'),
                _buildButton('9'),
                _buildButton('C', color: Colors.red[100], textColor: Colors.red, onTap: _clear),
              ],
            ),
            Row(
              children: [
                _buildButton('4'),
                _buildButton('5'),
                _buildButton('6'),
                _buildButton('⌫', color: Colors.orange[100], textColor: Colors.orange[800], onTap: _delete),
              ],
            ),
            Row(
              children: [
                _buildButton('1'),
                _buildButton('2'),
                _buildButton('3'),
                _buildButton('+', color: Colors.blue[100], textColor: Colors.blue[800]),
              ],
            ),
            Row(
              children: [
                _buildButton('0'),
                _buildButton('=' , color: Colors.blue[600], textColor: Colors.white, onTap: _calculate),
                _buildButton('-', color: Colors.blue[100], textColor: Colors.blue[800]),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _confirm,
                child: const Text('CONFIRMAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
