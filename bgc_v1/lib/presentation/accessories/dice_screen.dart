import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class DiceRollScreen extends StatefulWidget {
  const DiceRollScreen({super.key});

  @override
  State<DiceRollScreen> createState() => _DiceRollScreenState();
}

class _DiceRollScreenState extends State<DiceRollScreen>
    with SingleTickerProviderStateMixin {
  static const Color redColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color grayColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE2E8F0);

  late final AnimationController _controller;
  late final Animation<double> _animation;

  final Random _random = Random();

  final List<int> _diceTypes = [4, 6, 10, 12, 20, 100];
  final List<int> _diceAmounts = [1, 2, 3, 4, 5];

  int _selectedDice = 4;
  int _diceAmount = 1;

  List<int> _diceResults = [1];
  List<bool> _lockedDice = [false];

  bool _isRolling = false;

  int get _total => _diceResults.fold(0, (sum, value) => sum + value);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0, end: pi * 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _diceResults = _generateResults(amount: _diceAmount);
    _lockedDice = List.generate(_diceAmount, (_) => false);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _diceResults = _generateResultsKeepingLocked();
          _isRolling = false;
        });

        _controller.reset();
      }
    });
  }

int _generateSingleResult() {
  if (_selectedDice == 100) {
    return (_random.nextInt(10) + 1) * 10;
  }

  return _random.nextInt(_selectedDice) + 1;
}

  List<int> _generateResults({required int amount}) {
    return List.generate(amount, (_) => _generateSingleResult());
  }

  List<int> _generateResultsKeepingLocked() {
    return List.generate(_diceAmount, (index) {
      final isLocked = _lockedDice[index];

      if (isLocked) {
        return _diceResults[index];
      }

      return _generateSingleResult();
    });
  }

  void _rollDice() {
    if (_isRolling) return;

    final allDiceLocked = _lockedDice.every((isLocked) => isLocked);

    if (allDiceLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todos los dados están bloqueados. Desbloqueá uno para tirar.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isRolling = true;
    });

    _controller.forward();
  }

  void _selectDice(int dice) {
    if (_isRolling) return;

    setState(() {
      _selectedDice = dice;

      // Regenera todos para evitar valores inválidos.
      // Ejemplo: si antes era D100 y ahora es D10, no puede quedar 91.
      _diceResults = _generateResults(amount: _diceAmount);

      // Al cambiar el tipo de dado, se desbloquean todos.
      _lockedDice = List.generate(_diceAmount, (_) => false);
    });
  }

  void _changeDiceAmount(int amount) {
    if (_isRolling) return;

    setState(() {
      _diceAmount = amount;

      if (_diceResults.length < amount) {
        final missingAmount = amount - _diceResults.length;

        _diceResults = [
          ..._diceResults,
          ..._generateResults(amount: missingAmount),
        ];

        _lockedDice = [
          ..._lockedDice,
          ...List.generate(missingAmount, (_) => false),
        ];
      } else {
        _diceResults = _diceResults.take(amount).toList();
        _lockedDice = _lockedDice.take(amount).toList();
      }
    });
  }

  void _toggleDiceLock(int index) {
    if (_isRolling) return;

    setState(() {
      _lockedDice[index] = !_lockedDice[index];
    });
  }

  double get _diceSize {
    if (_diceAmount == 1) return 220;
    if (_diceAmount == 2) return 145;
    return 115;
  }

  String get _rollButtonText {
    if (_isRolling) return 'TIRANDO...';
    return _diceAmount == 1 ? 'TIRAR DADO' : 'TIRAR DADOS';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiceAmountDropdown(),
              const SizedBox(height: 18),
<<<<<<< Updated upstream

              const Text(
                'TIPO DE DADO (CARAS)',
=======
              Text(
                'TIPO DE DADO',
>>>>>>> Stashed changes
                style: TextStyle(
                  color: grayColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              _buildDiceSelector(),
              const SizedBox(height: 10),
              Text(
                'Tocá el candado para bloquear un dado y seguir tirando solo los demás.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final rotation = _animation.value;

                        return Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,
                          children: List.generate(_diceAmount, (index) {
                            final isLocked = _lockedDice[index];

                            return DiceLockWrapper(
                              isLocked: isLocked,
                              onTapLock: () => _toggleDiceLock(index),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateZ(isLocked ? 0 : rotation),
                                child: DiceWidget(
                                  result: _isRolling && !isLocked
                                      ? '?'
                                      : _diceResults[index].toString(),
                                  diceType: 'D$_selectedDice',
                                  size: _diceSize,
                                  isLocked: isLocked,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isRolling ? 'TOTAL: ...' : 'TOTAL: $_total',
                      style: const TextStyle(
                        color: redColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _rollDice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: redColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _rollButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.4,
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

  Widget _buildDiceAmountDropdown() {
    return SizedBox(
      width: 145,
      height: 45,
      child: DropdownButtonFormField<int>(
        value: _diceAmount,
        dropdownColor: Theme.of(context).colorScheme.surface,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white,
          size: 22,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: redColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: redColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: redColor),
          ),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        selectedItemBuilder: (context) {
          return _diceAmounts.map((amount) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DADOS: $amount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            );
          }).toList();
        },
        items: _diceAmounts.map((amount) {
          return DropdownMenuItem<int>(
            value: amount,
            child: Text(
              amount == 1 ? '1 dado' : '$amount dados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
        onChanged: _isRolling
            ? null
            : (value) {
                if (value == null) return;
                _changeDiceAmount(value);
              },
      ),
    );
  }

  Widget _buildDiceSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _diceTypes.map((dice) {
          final isSelected = dice == _selectedDice;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _selectDice(dice),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 50,
                height: 35,
                decoration: BoxDecoration(
<<<<<<< Updated upstream
                  color: isSelected ? redColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? redColor : borderColor,
=======
                  color: isSelected
                      ? redColor
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? redColor
                        : Theme.of(context).colorScheme.outlineVariant,
>>>>>>> Stashed changes
                  ),
                ),
                child: Center(
                  child: Text(
                    'D$dice',
                    style: TextStyle(
<<<<<<< Updated upstream
                      color: isSelected ? Colors.white : grayColor,
=======
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
>>>>>>> Stashed changes
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DiceLockWrapper extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final VoidCallback onTapLock;

  const DiceLockWrapper({
    super.key,
    required this.child,
    required this.isLocked,
    required this.onTapLock,
  });

  static const Color redColor = AppColors.red;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTapLock,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 34,
            decoration: BoxDecoration(
              color: isLocked
                  ? redColor
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLocked
                    ? redColor
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              color: isLocked
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class DiceWidget extends StatelessWidget {
  final String result;
  final String diceType;
  final double size;
  final bool isLocked;

  const DiceWidget({
    super.key,
    required this.result,
    required this.diceType,
    this.size = 220,
    this.isLocked = false,
  });

<<<<<<< Updated upstream
  static const Color redColor = Color(0xFFE63946);
  static const Color grayColor = Color(0xFF6B7280);
=======
  static const Color redColor = AppColors.red;
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DicePainter(isLocked: isLocked),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result,
                style: TextStyle(
                  color: redColor,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: size * 0.04),
              Text(
                diceType,
                style: TextStyle(
                  color: grayColor,
                  fontSize: size * 0.10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DicePainter extends CustomPainter {
  final bool isLocked;

  DicePainter({required this.isLocked});

  static const Color redColor = AppColors.red;
  static const Color lightRed = Color(0xFFFFE5E8);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.08,
      size.width * 0.84,
      size.height * 0.84,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.14),
    );

    final shadowPaint = Paint()
      ..color = redColor.withValues(alpha: isLocked ? 0.20 : 0.12)
      ..style = PaintingStyle.fill;

    final dicePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isLocked ? redColor.withValues(alpha: 0.75) : redColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022;

    final dotPaint = Paint()
      ..color = lightRed
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      rrect.shift(Offset(0, size.height * 0.035)),
      shadowPaint,
    );

    canvas.drawRRect(rrect, dicePaint);
    canvas.drawRRect(rrect, borderPaint);

    _drawDots(
      canvas: canvas,
      rect: rect,
      paint: dotPaint,
      size: size,
    );
  }

  void _drawDots({
    required Canvas canvas,
    required Rect rect,
    required Paint paint,
    required Size size,
  }) {
    final dotRadius = size.width * 0.035;
    final offset = size.width * 0.17;

    final points = [
      Offset(rect.left + offset, rect.top + offset),
      Offset(rect.right - offset, rect.top + offset),
      Offset(rect.left + offset, rect.bottom - offset),
      Offset(rect.right - offset, rect.bottom - offset),
    ];

    for (final point in points) {
      canvas.drawCircle(point, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) {
    return oldDelegate.isLocked != isLocked;
  }
}