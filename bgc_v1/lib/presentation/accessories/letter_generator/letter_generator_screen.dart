import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bgc_app_bar.dart';
import 'providers/letter_generator_provider.dart';
import '../widgets/accessory_resume_dialog.dart';

class LetterGeneratorScreen extends ConsumerStatefulWidget {
  const LetterGeneratorScreen({super.key});

  @override
  ConsumerState<LetterGeneratorScreen> createState() =>
      _LetterGeneratorScreenState();
}

class _LetterGeneratorScreenState extends ConsumerState<LetterGeneratorScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = AppColors.blue;

  bool _initialized = false;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final isNew = await ref
        .read(letterGeneratorProvider.notifier)
        .initialize(user);
    if (!mounted) return;

    // Mostrar la letra restaurada (si hay) a tamaño completo, sin animar.
    if (ref.read(letterGeneratorProvider).currentLetter != null) {
      _controller.value = 1.0;
    }
    setState(() => _initialized = true);

    if (!isNew) {
      // Había una partida en curso: preguntar si retomar o arrancar de cero.
      AccessoryResumeDialog.show(
        context,
        onResume: () {}, // El estado ya quedó restaurado.
        onNew: () {
          ref.read(letterGeneratorProvider.notifier).clearHistory();
          _controller.reset();
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGenerate() {
    ref.read(letterGeneratorProvider.notifier).generateLetter();
    _controller.forward(from: 0);
  }

  void _onClear() {
    ref.read(letterGeneratorProvider.notifier).clearHistory();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(letterGeneratorProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const BgcAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggle(context, state),
              const SizedBox(height: 16),
              _buildLetterCard(context, state),
              const SizedBox(height: 20),
              Text(
                'LETRAS QUE YA SALIERON',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildHistory(context, state)),
              const SizedBox(height: 16),
              _buildButtons(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context, LetterGeneratorState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Permitir repetir letras',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        Switch(
          value: state.allowRepeat,
          onChanged: (v) =>
              ref.read(letterGeneratorProvider.notifier).setAllowRepeat(v),
          activeThumbColor: _accent,
        ),
      ],
    );
  }

  Widget _buildLetterCard(BuildContext context, LetterGeneratorState state) {
    final colorScheme = Theme.of(context).colorScheme;

    final String subtitle;
    if (state.noLettersLeft) {
      subtitle = '¡Todas las letras han salido!';
    } else if (state.currentLetter == null) {
      subtitle = 'Presioná GENERAR';
    } else {
      subtitle = state.allowRepeat ? 'Con Repetición' : 'Sin Repetición';
    }

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent, width: 2.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.noLettersLeft)
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.green)
          else if (state.currentLetter != null)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                state.currentLetter!,
                style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: _accent,
                  height: 1.0,
                ),
              ),
            )
          else
            Icon(
              Icons.sort_by_alpha,
              size: 64,
              color: _accent.withValues(alpha: 0.3),
            ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, LetterGeneratorState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.history.isEmpty) {
      return Center(
        child: Text(
          'Ninguna todavía',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: state.history.map((letter) {
          return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _accent,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtons(LetterGeneratorState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool canClear = state.history.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: state.noLettersLeft ? null : _onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colorScheme.surfaceContainerHighest,
              disabledForegroundColor: colorScheme.onSurfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'GENERAR LETRA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: canClear ? _onClear : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: canClear ? AppColors.red : colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'BORRAR HISTORIAL / NUEVA PARTIDA',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: canClear
                    ? AppColors.red
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
