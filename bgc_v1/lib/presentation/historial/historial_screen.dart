import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'providers/historial_provider.dart';
import '../../domain/models/partida_model.dart';
import '../widgets/custom_alert.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historialProvider.notifier).initialFetch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleContinueMatch(Partida partida) {
    // La llave tiene el formato [prefijo]_state_[userId]_[playerCount] o con timestamp al final
    final parts = partida.id.split('_');
    int? playerCount;
    if (parts.length >= 4) {
      playerCount = int.tryParse(parts[3]);
    }

    if (playerCount == null) {
      CustomAlert.show(context, 'No se pudo determinar la cantidad de jugadores para continuar.', isError: true);
      return;
    }

    String route = '';
    if (partida.id.startsWith('burako')) {
      route = '/burako-tracker';
    } else if (partida.id.startsWith('akropolis')) {
      route = '/akropolis-tracker';
    } else if (partida.id.startsWith('tracker')) {
      route = '/hp-tracker';
    } else {
      CustomAlert.show(context, 'Anotador no soportado.', isError: true);
      return;
    }

    context.push(route, extra: {'playerCount': playerCount, 'fullKey': partida.id});
  }

  void _showEnCursoOptions(Partida partida) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Partida en curso'),
          content: const Text('¿Qué deseas hacer con esta partida que dejaste a medias?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(historialProvider.notifier).removeLocalMatch(partida.id);
              },
              child: const Text('Borrar', style: TextStyle(color: Colors.red)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _handleContinueMatch(partida);
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFinalizadaOptions(Partida partida) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar Historial'),
          content: const Text('¿Estás seguro de borrar este registro del historial? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                Navigator.pop(context);
                ref.read(historialProvider.notifier).removeFirestoreMatch(partida.id);
              },
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Historial',
                    style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            // Filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text('Estado:', style: textTheme.titleMedium),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.statusFilter,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onPrimaryContainer),
                          dropdownColor: colorScheme.surface,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TODOS', child: Text('TODOS')),
                            DropdownMenuItem(value: 'EN CURSO', child: Text('EN CURSO')),
                            DropdownMenuItem(value: 'FINALIZADA', child: Text('FINALIZADAS')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(historialProvider.notifier).setFilter(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.filteredPartidas.isEmpty
                      ? Center(
                          child: Text('No hay partidas para mostrar.', style: textTheme.titleMedium),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(historialProvider.notifier).initialFetch(),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(24),
                            itemCount: state.filteredPartidas.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.filteredPartidas.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: state.isFetchingMore
                                        ? const CircularProgressIndicator()
                                        : TextButton(
                                            onPressed: () => ref.read(historialProvider.notifier).fetchMore(),
                                            child: const Text('Cargar más partidas finalizadas'),
                                          ),
                                  ),
                                );
                              }

                              final partida = state.filteredPartidas[index];
                              final isEnCurso = partida.estado == 'en curso';

                              String fechaTexto = 'Desconocida';
                              if (partida.fechaFinalizacion != null) {
                                final d = partida.fechaFinalizacion!.toLocal();
                                fechaTexto = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    if (isEnCurso) {
                                      _showEnCursoOptions(partida);
                                    }
                                  },
                                  onLongPress: () {
                                    if (!isEnCurso) {
                                      _showDeleteFinalizadaOptions(partida);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              partida.juegoNombre.toUpperCase(),
                                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isEnCurso ? colorScheme.tertiaryContainer : colorScheme.primaryContainer,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                partida.estado.toUpperCase(),
                                                style: textTheme.labelSmall?.copyWith(
                                                  color: isEnCurso ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Participantes: ${partida.participantes.join(", ")}'),
                                        if (!isEnCurso && partida.ganadores.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            partida.isTeamGame ? 'Ganadores: ${partida.ganadores.join(", ")}' : 'Ganador: ${partida.ganadores.join(", ")}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              fechaTexto,
                                              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
