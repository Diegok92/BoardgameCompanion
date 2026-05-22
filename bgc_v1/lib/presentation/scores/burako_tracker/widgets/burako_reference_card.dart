import 'package:flutter/material.dart';

class BurakoReferenceCard extends StatelessWidget {
  const BurakoReferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.blueGrey[700], size: 28),
              const SizedBox(width: 8),
              Text(
                'VALORES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildRefRow('Comodín', '50 pts', Colors.orange[800]!),
          const Divider(height: 24),
          _buildRefRow('Ficha Nº 2', '20 pts', Colors.blue[800]!),
          const Divider(height: 24),
          _buildRefRow('Ficha Nº 1', '15 pts', Colors.green[800]!),
          const Divider(height: 24),
          _buildRefRow('Fichas 8 al 13', '10 pts', Colors.blueGrey[800]!),
          const Divider(height: 24),
          _buildRefRow('Fichas 3 al 7', '5 pts', Colors.blueGrey[500]!),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueGrey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRefRow(String label, String points, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(points, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
