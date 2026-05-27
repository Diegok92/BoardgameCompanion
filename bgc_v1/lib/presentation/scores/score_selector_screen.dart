import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_model.dart';
import '../providers/games_provider.dart';
import '../widgets/custom_alert.dart';
import '../historial/providers/historial_provider.dart';
import '../../data/local_catalog/local_games_catalog.dart';
import '../providers/auth_provider.dart';

class ScoreSelectorScreen extends ConsumerStatefulWidget {
  const ScoreSelectorScreen({super.key});

  @override
  ConsumerState<ScoreSelectorScreen> createState() =>
      _ScoreSelectorScreenState();
}

class _ScoreSelectorScreenState extends ConsumerState<ScoreSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();

  Game? _selectedGame;
  int? _selectedPlayerCount; // Starts as null to represent "-"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onGameSelected(Game game) {
    setState(() {
      _selectedGame = game;
    });
  }

  void _onConfirm() async {
    if (_selectedGame == null) {
      CustomAlert.show(context, 'Por favor, selecciona un juego primero.', isError: true);
      return;
    }

    if (_selectedPlayerCount == null) {
      CustomAlert.show(context, 'Por favor, selecciona la cantidad de jugadores.', isError: true);
      return;
    }

    if (!_selectedGame!.validPlayerCounts.contains(_selectedPlayerCount)) {
      CustomAlert.show(context, 'Cantidad de jugadores no válida para el juego seleccionado.', isError: true);
      return;
    }

    String route = '';
    if (_selectedGame!.id == 'burako') {
      route = '/burako-tracker';
    } else if (_selectedGame!.id == 'hp_tracker' || LocalGamesCatalog.trackerGames.any((g) => g.id == _selectedGame!.id)) {
      route = '/hp-tracker';
    } else if (_selectedGame!.id == 'akropolis') {
      route = '/akropolis-tracker';
    } else {
      CustomAlert.show(context, 'El anotador para ${_selectedGame!.name} aún no está implementado.', isError: true);
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    final localMatches = await ref.read(historialProvider.notifier).fetchLocalMatches(user.id);
    if (!mounted) return;
    final matchingMatches = localMatches.where((p) {
      final parts = p.id.split('_');
      if (parts.length >= 4) {
        final pCount = parts[3];
        return p.juegoId == _selectedGame!.id && pCount == _selectedPlayerCount.toString();
      }
      return false;
    }).toList();

    if (matchingMatches.isNotEmpty) {
      matchingMatches.sort((a, b) {
        if (a.fechaFinalizacion == null && b.fechaFinalizacion == null) return 0;
        if (a.fechaFinalizacion == null) return 1;
        if (b.fechaFinalizacion == null) return -1;
        return b.fechaFinalizacion!.compareTo(a.fechaFinalizacion!);
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Partidas en curso'),
            content: Text('Tienes partidas en curso para ${_selectedGame!.name} a $_selectedPlayerCount jugadores. ¿Quieres retomar la última o iniciar partida nueva?\n\n(Recordá que en "Historial" vas a poder ver todas tus partidas "En Curso")'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(route, extra: {'playerCount': _selectedPlayerCount});
                },
                child: const Text('Iniciar Nueva'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(route, extra: {'playerCount': _selectedPlayerCount, 'fullKey': matchingMatches.first.id});
                },
                child: const Text('Retomar Última'),
              ),
            ],
          );
        },
      );
    } else {
      context.push(route, extra: {'playerCount': _selectedPlayerCount});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BG Companion',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset('assets/images/logo.svg', height: 24),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección superior: Buscador y Jugadores
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).updateQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar juego...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedPlayerCount,
                      hint: const Text('-'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _selectedPlayerCount != null
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: _selectedPlayerCount != null
                              ? const BorderSide(color: Colors.blue, width: 2)
                              : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: _selectedPlayerCount != null
                              ? const BorderSide(color: Colors.blue, width: 2)
                              : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(
                        Icons.people,
                        color: _selectedPlayerCount != null
                            ? Colors.blue
                            : null,
                      ),
                      items: [1, 2, 3, 4, 5, 6].map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text('$count Jug.'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPlayerCount = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ref
                  .watch(filteredGamesProvider)
                  .when(
                    data: (games) {
                      final standardGames = games
                          .where((g) => g.isStandard)
                          .toList();
                      final specificGames = games
                          .where((g) => !g.isStandard)
                          .toList();
                      specificGames.sort((a, b) => a.name.compareTo(b.name));

                      return Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Anotadores Rápidos (Estándares)
                            Text(
                              'Anotadores Estándar',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: standardGames.map((game) {
                                final isSelected = _selectedGame?.id == game.id;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: game == standardGames.first
                                          ? 8.0
                                          : 0,
                                      left: game == standardGames.last
                                          ? 8.0
                                          : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _onGameSelected(game),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primaryContainer
                                              : Theme.of(context).colorScheme.surface,
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.outlineVariant,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            if (isSelected)
                                              BoxShadow(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              game.id == 'hp_tracker'
                                                  ? Icons.favorite
                                                  : Icons.star,
                                              color: game.id == 'hp_tracker'
                                                  ? Colors.red
                                                  : Colors.amber,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              game.name,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Otros Juegos
                            Text(
                              'Anotadores Personalizados',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: specificGames.length,
                                itemBuilder: (context, index) {
                                  final game = specificGames[index];
                                  final isSelected =
                                      _selectedGame?.id == game.id;

                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.outlineVariant,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surface,
                                    child: ListTile(
                                      onTap: () => _onGameSelected(game),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: game.iconPath != null
                                            ? SvgPicture.asset(
                                                game.iconPath!,
                                                height: 24,
                                                width: 24,
                                              )
                                            : Icon(
                                                Icons.casino,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                      ),
                                      title: Text(
                                        game.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                            )
                                          : const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) =>
                        Expanded(child: Center(child: Text('Error: $err'))),
                  ),
              const SizedBox(height: 16),

              // Botón de Confirmar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _onConfirm,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'CONFIRMAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
