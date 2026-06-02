import 'package:flutter/material.dart';

import '../../../data/local_catalog/local_games_catalog.dart';
import '../../../domain/models/game_model.dart';

/// Desplegable reutilizable para elegir qué juego se está anotando dentro de
/// un anotador. La opción por defecto es "Sin Asignar" (null).
///
/// Lo usan los anotadores que comparten juegos estándar (HP y Puntos VP), para
/// no duplicar la lógica del dropdown.
class TrackerGameDropdown extends StatelessWidget {
  final Game? selectedGame;
  final ValueChanged<Game?> onChanged;
  final List<Game> games;

  const TrackerGameDropdown({
    super.key,
    required this.selectedGame,
    required this.onChanged,
    this.games = LocalGamesCatalog.trackerGames,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Game?>(
          value: selectedGame,
          hint: const Text('Juego', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: colorScheme.onSurfaceVariant,
          ),
          items: [
            DropdownMenuItem<Game?>(
              value: null,
              child: Text(
                'Sin Asignar',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...games.map(
              (g) => DropdownMenuItem<Game?>(
                value: g,
                child: Text(
                  g.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
