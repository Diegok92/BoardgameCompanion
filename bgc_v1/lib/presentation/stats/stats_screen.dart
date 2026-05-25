import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'providers/stats_provider.dart';
import '../providers/auth_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).fetchPartidas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);
    final user = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final winRate = state.totalPartidas > 0 
      ? (state.ganadas / state.totalPartidas * 100).round() 
      : 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera Usuario
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: user?.favoriteColor ?? colorScheme.primaryContainer,
                    child: Icon(Icons.person, size: 40, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'Usuario',
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Estadísticas de Partidas Registradas',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Filtros
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'JUEGO', 
                      state.selectedJuego, 
                      ref.read(statsProvider.notifier).uniqueJuegos, 
                      (val) => ref.read(statsProvider.notifier).setJuegoFilter(val!),
                      colorScheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'CONTRA', 
                      state.selectedOpponent, 
                      ref.read(statsProvider.notifier).uniqueOpponents, 
                      (val) => ref.read(statsProvider.notifier).setOpponentFilter(val!),
                      colorScheme,
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rendimiento Total
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RENDIMIENTO TOTAL', style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        )),
                        Text('$winRate%', style: textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        )),
                      ],
                    ),
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          CircularProgressIndicator(
                            value: winRate / 100,
                            strokeWidth: 12,
                            color: colorScheme.primary,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Partidas Jugadas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Partidas Jugadas', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${state.totalPartidas}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grilla 2x2
              Row(
                children: [
                  Expanded(child: _buildStatCard('Ganadas', state.ganadas, Colors.green.shade600, Colors.green.shade50)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Perdidas', state.perdidas, Colors.red.shade600, Colors.red.shade50)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Empatadas', state.empatadas, Colors.grey.shade700, Colors.grey.shade100)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Racha de Victorias', state.rachaActual, Colors.orange.shade700, Colors.orange.shade50)),
                ],
              ),
              const SizedBox(height: 32),

              // Botón Compartir
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {}, // Sin funcionalidad por ahora
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'COMPARTIR ESTADISTICAS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, ColorScheme colorScheme, {bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: isOutlined ? Border.all(color: colorScheme.primary) : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: isOutlined ? colorScheme.primary : colorScheme.onPrimaryContainer),
          style: TextStyle(
            color: isOutlined ? colorScheme.primary : colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          dropdownColor: colorScheme.surface,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item == 'TODOS' ? '$label: TODOS' : item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}
