import 'package:flutter/material.dart';

class TrucoPlayersFooter extends StatelessWidget {
  final int teamIndex;
  final List<String?> playerNames;
  final VoidCallback onEdit;

  const TrucoPlayersFooter({
    super.key,
    required this.teamIndex,
    required this.playerNames,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final playersPerTeam = playerNames.length;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 4,
        ),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF9E9E9E),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              teamIndex == 0 ? 'Jugadores Nosotros:' : 'Jugadores Ellos:',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            ...playerNames.asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value;

              final playerNumber = (teamIndex * playersPerTeam) + index + 1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name ?? 'Jugador $playerNumber',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              name == null ? FontWeight.w600 : FontWeight.w900,
                          color: name == null ? Colors.black54 : Colors.black87,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Colors.black54,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}