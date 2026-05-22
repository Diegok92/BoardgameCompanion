import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_model.dart';
import '../providers/games_provider.dart';

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

  void _onConfirm() {
    if (_selectedGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un juego primero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPlayerCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona la cantidad de jugadores.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_selectedGame!.validPlayerCounts.contains(_selectedPlayerCount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cantidad de jugadores no válida para el juego seleccionado.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGame!.id == 'burako') {
      context.push(
        '/burako-tracker',
        extra: {'playerCount': _selectedPlayerCount},
      );
    } else if (_selectedGame!.id == 'hp_tracker') {
      context.push(
        '/hp-tracker',
        extra: {'playerCount': _selectedPlayerCount},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El anotador para ${_selectedGame!.name} aún no está implementado.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
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
                        fillColor: Colors.grey[100],
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
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.grey[100],
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
                                color: Colors.blueGrey,
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
                                              ? Colors.blue.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.white,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.grey[300]!,
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
                                color: Colors.blueGrey,
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
                                            ? Colors.blue
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    color: isSelected
                                        ? Colors.blue.withValues(alpha: 0.05)
                                        : Colors.white,
                                    child: ListTile(
                                      onTap: () => _onGameSelected(game),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey[200],
                                        child: const Icon(
                                          Icons.casino,
                                          color: Colors.blueGrey,
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
