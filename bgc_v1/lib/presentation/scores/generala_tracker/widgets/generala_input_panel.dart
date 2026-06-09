import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/generala_tracker_provider.dart';

class GeneralaInputPanel extends ConsumerWidget {
  const GeneralaInputPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(generalaTrackerProvider);
    final notifier = ref.read(generalaTrackerProvider.notifier);
    final cs       = Theme.of(context).colorScheme;

    if (state.entities.isEmpty) return const SizedBox.shrink();

    final activeIdx    = state.buffer.activeEntityIndex;
    final category     = state.buffer.selectedCategory;
    final pendingScore = state.buffer.pendingScore;
    final entity       = state.entities[activeIdx];
    final alreadyScored = entity.scores[category] != null;

    final dobleGeneralaBlocked =
        category == GeneralaCategory.dobleGenerala &&
        (entity.scores[GeneralaCategory.generala] == null ||
            entity.scores[GeneralaCategory.generala] == 0);

    final canCommit =
        pendingScore != null && !alreadyScored && !dobleGeneralaBlocked;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Fila 1: USUARIO | TIPO DE JUGADA ──────────────────────────────
          Row(
            children: [
              // Dropdown jugador
              Expanded(
                child: _PlayerDropdown(
                  entities: state.entities,
                  activeIndex: activeIdx,
                  onChanged: notifier.setActiveEntity,
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown categoría
              Expanded(
                child: _CategoryDropdown(
                  entity: entity,
                  selected: category,
                  onChanged: notifier.setCategory,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Fila 2: botones de puntaje ─────────────────────────────────────
          _ScoreOptions(
            entity: entity,
            category: category,
            pendingScore: pendingScore,
            dobleGeneralaBlocked: dobleGeneralaBlocked,
            alreadyScored: alreadyScored,
            onSelect: notifier.setPendingScore,
          ),

          const SizedBox(height: 8),

          // ── Fila 3: "Sumando a X" pequeño ─────────────────────────────────
          Text(
            _summaryText(entity, pendingScore, alreadyScored),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: entity.color.withValues(alpha: alreadyScored ? 0.5 : 1.0),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // ── Fila 4: botón SUMAR ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: canCommit ? notifier.commitScore : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'SUMAR A ${entity.name.toUpperCase()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _summaryText(
      GeneralaEntity entity, int? pendingScore, bool alreadyScored) {
    if (alreadyScored) return '✓ Categoría ya anotada para ${entity.name}';
    if (pendingScore == null) return 'Sumando a ${entity.name}';
    if (pendingScore == 0) return 'Tachando casilla para ${entity.name}';
    return 'Sumando $pendingScore pts a ${entity.name}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown: jugador
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerDropdown extends StatelessWidget {
  final List<GeneralaEntity> entities;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _PlayerDropdown({
    required this.entities,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entity = entities[activeIndex];
    final fg = entity.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: entity.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: activeIndex,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: fg),
          dropdownColor: Theme.of(context).colorScheme.surface,
          items: List.generate(entities.length, (i) {
            final e = entities[i];
            return DropdownMenuItem<int>(
              value: i,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: e.color,
                child: Text(
                  e.name.toUpperCase(),
                  style: TextStyle(
                    color: e.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
          onChanged: (v) { if (v != null) onChanged(v); },
          selectedItemBuilder: (context) => List.generate(
            entities.length,
            (i) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entities[i].name.toUpperCase(),
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.bold, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown: categoría
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final GeneralaEntity entity;
  final GeneralaCategory selected;
  final ValueChanged<GeneralaCategory> onChanged;

  const _CategoryDropdown({
    required this.entity,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GeneralaCategory>(
          value: selected,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: cs.onSurface, size: 18),
          dropdownColor: cs.surface,
          selectedItemBuilder: (context) => GeneralaCategory.values
              .map((cat) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      cat.dropdownLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          items: GeneralaCategory.values.map((cat) {
            final isScored = entity.scores[cat] != null;
            return DropdownMenuItem<GeneralaCategory>(
              value: cat,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cat.dropdownLabel,
                      style: TextStyle(
                        color: isScored
                            ? cs.onSurface.withValues(alpha: 0.4)
                            : cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        decoration:
                            isScored ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isScored)
                    Icon(Icons.check, size: 12,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botones de selección de puntaje
// Puntos arriba (wrap centrado) · Tachar abajo (centrado solo)
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreOptions extends StatelessWidget {
  final GeneralaEntity entity;
  final GeneralaCategory category;
  final int? pendingScore;
  final bool dobleGeneralaBlocked;
  final bool alreadyScored;
  final ValueChanged<int> onSelect;

  const _ScoreOptions({
    required this.entity,
    required this.category,
    required this.pendingScore,
    required this.dobleGeneralaBlocked,
    required this.alreadyScored,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (alreadyScored || dobleGeneralaBlocked) {
      return const SizedBox.shrink();
    }

    // Construir lista de opciones sin "Tachar"
    final pointOpts = <_Opt>[];

    if (category.isNumeric) {
      final face = category.faceValue;
      for (int i = 1; i <= 5; i++) {
        pointOpts.add(_Opt('${i * face} pts', i * face));
      }
    } else if (category.hasServidaOption) {
      pointOpts.add(_Opt('No Serv. (${category.noServidaScore})', category.noServidaScore));
      pointOpts.add(_Opt('Serv. (${category.servidaScore})', category.servidaScore));
    } else {
      pointOpts.add(_Opt('Hecha (${category.servidaScore})', category.servidaScore));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Puntos arriba
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: pointOpts.map((opt) => _chip(context, opt)).toList(),
        ),
        const SizedBox(height: 8),
        // Tachar abajo, centrado
        _chip(context, const _Opt('Tachar (0)', 0), isTachar: true),
      ],
    );
  }

  Widget _chip(BuildContext context, _Opt opt, {bool isTachar = false}) {
    final isSelected = pendingScore == opt.value;
    final cs = Theme.of(context).colorScheme;

    Color bg, fg, borderColor;
    if (isSelected && isTachar) {
      bg = cs.error;
      fg = cs.onError;
      borderColor = cs.error;
    } else if (isSelected) {
      bg = entity.color;
      fg = entity.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
      borderColor = entity.color;
    } else if (isTachar) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant.withValues(alpha: 0.7);
      borderColor = cs.outlineVariant;
    } else {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant;
      borderColor = cs.outlineVariant;
    }

    return GestureDetector(
      onTap: () => onSelect(opt.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Text(
          opt.label,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}

class _Opt {
  final String label;
  final int value;
  const _Opt(this.label, this.value);
}
