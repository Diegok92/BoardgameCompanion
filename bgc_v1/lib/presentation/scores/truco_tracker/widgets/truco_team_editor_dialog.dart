import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../providers/truco_tracker_provider.dart';

class TrucoTeamEditorDialog {
  static void show(BuildContext context, WidgetRef ref, int teamIndex) {
    final user = ref.read(authProvider);

    final availablePlayers = <String>[
      if (user != null) user.username,
      ...user?.invitados ?? [],
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentState = ref.read(trucoTrackerProvider);

            if (teamIndex < 0 || teamIndex >= currentState.teams.length) {
              return const AlertDialog(
                title: Text('Error'),
                content: Text('Equipo inválido.'),
              );
            }

            final currentTeam = currentState.teams[teamIndex];

            return AlertDialog(
              title: Text(
                'Jugadores ${currentTeam.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Elegí quién ocupa cada lugar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ...List.generate(currentTeam.playerNames.length, (
                      playerIndex,
                    ) {
                      final currentName = currentTeam.playerNames[playerIndex];

                      int globalIndex = 1;

                      for (int i = 0; i < teamIndex; i++) {
                        globalIndex += currentState.teams[i].playerNames.length;
                      }

                      globalIndex += playerIndex;

                      final selectablePlayers = availablePlayers.where((player) {
                        for (int i = 0; i < currentState.teams.length; i++) {
                          for (int j = 0;
                              j < currentState.teams[i].playerNames.length;
                              j++) {
                            final isCurrentPosition =
                                i == teamIndex && j == playerIndex;

                            if (isCurrentPosition) continue;

                            if (currentState.teams[i].playerNames[j] ==
                                player) {
                              return false;
                            }
                          }
                        }

                        return true;
                      }).toList();

                      final selectedValue =
                          currentName != null &&
                                  selectablePlayers.contains(currentName)
                              ? currentName
                              : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String?>(
                          initialValue: selectedValue,
                          decoration: InputDecoration(
                            labelText: 'Jugador $globalIndex',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Sin asignar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...selectablePlayers.map(
                              (player) => DropdownMenuItem<String?>(
                                value: player,
                                child: Text(player),
                              ),
                            ),
                            const DropdownMenuItem<String?>(
                              value: 'NUEVO_INVITADO',
                              child: Text(
                                '+ Agregar invitado',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == 'NUEVO_INVITADO') {
                              Navigator.pop(context);
                              context.push('/register-invitado');
                              return;
                            }

                            ref
                                .read(trucoTrackerProvider.notifier)
                                .updatePlayerNameInTeam(
                                  teamIndex,
                                  playerIndex,
                                  value,
                                );

                            setDialogState(() {});
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 4),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD0D0D0),
                        ),
                      ),
                      child: const Text(
                        'Un jugador no puede repetirse en dos posiciones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}