import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class LetterGeneratorScreen extends StatefulWidget {
  const LetterGeneratorScreen({super.key});

  @override
  State<LetterGeneratorScreen> createState() => _LetterGeneratorScreenState();
}

class _LetterGeneratorScreenState extends State<LetterGeneratorScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = AppColors.blue;
  static const List<String> _alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  String? _currentLetter;
  final List<String> _history = [];
  bool _allowRepeat = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _noLettersLeft =>
      !_allowRepeat && _history.toSet().length >= _alphabet.length;

  List<String> get _availableLetters {
    if (_allowRepeat) return _alphabet;
    final used = _history.toSet();
    return _alphabet.where((l) => !used.contains(l)).toList();
  }

  void _generateLetter() {
    final available = _availableLetters;
    if (available.isEmpty) return;
    final letter = available[Random().nextInt(available.length)];
    _controller.forward(from: 0);
    setState(() {
      _currentLetter = letter;
      _history.add(letter);
    });
  }

  void _clearHistory() {
    _controller.reset();
    setState(() {
      _history.clear();
      _currentLetter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggle(context),
              const SizedBox(height: 16),
              _buildLetterCard(context),
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
              Expanded(child: _buildHistory(context)),
              const SizedBox(height: 16),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 32),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BG Companion',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Permitir repetir letras',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Switch(
          value: _allowRepeat,
          onChanged: (v) => setState(() => _allowRepeat = v),
          activeThumbColor: _accent,
        ),
      ],
    );
  }

  Widget _buildLetterCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String subtitle;
    if (_noLettersLeft) {
      subtitle = '¡Todas las letras han salido!';
    } else if (_currentLetter == null) {
      subtitle = 'Presioná GENERAR';
    } else {
      subtitle = _allowRepeat ? 'Con Repetición' : 'Sin Repetición';
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
          if (_noLettersLeft)
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.green)
          else if (_currentLetter != null)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                _currentLetter!,
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

  Widget _buildHistory(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_history.isEmpty) {
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
        children: _history.map((letter) {
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

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _noLettersLeft ? null : _generateLetter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
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
            onPressed: _history.isNotEmpty ? _clearHistory : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _history.isNotEmpty
                    ? AppColors.red
                    : Colors.grey.shade300,
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
                color: _history.isNotEmpty
                    ? AppColors.red
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
