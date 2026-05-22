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

  late final AnimationController _controller;
  late final Animation<double> _animation;

  final Random _random = Random();
  final List<int> _diceTypes = [4, 6, 10, 12, 20, 100];

  int _selectedDice = 4;
  int _diceAmount = 1;
  List<int> _diceResults = [1];
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

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _diceResults = _generateResults();
          _isRolling = false;
        });

        _controller.reset();
      }
    });
  }

  List<int> _generateResults() {
    return List.generate(
      _diceAmount,
      (_) => _random.nextInt(_selectedDice) + 1,
    );
  }

  void _rollDice() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    _controller.forward();
  }

  void _selectDice(int dice) {
    if (_isRolling) return;

    setState(() {
      _selectedDice = dice;
      _diceResults = _generateResults();
    });
  }

 void _changeDiceAmount() {
  if (_isRolling) return;

  setState(() {
    _diceAmount++;

    if (_diceAmount > 5) {
      _diceAmount = 1;
    }

    _diceResults = _generateResults();
  });
}

  double get _diceSize {
    if (_diceAmount == 1) return 220;
    if (_diceAmount == 2) return 145;
    return 115;
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiceAmountButton(),

              const SizedBox(height: 18),

              Text(
                'TIPO DE DADO (CARAS)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 10),

              _buildDiceSelector(),

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
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateZ(rotation),
                              child: DiceWidget(
                                result: _isRolling
                                    ? '?'
                                    : _diceResults[index].toString(),
                                diceType: 'D$_selectedDice',
                                size: _diceSize,
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
                    _isRolling ? 'TIRANDO...' : 'TIRAR DADO',
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

  Widget _buildDiceAmountButton() {
    return GestureDetector(
      onTap: _changeDiceAmount,
      child: Container(
        width: 120,
        height: 45,
        decoration: BoxDecoration(
          color: redColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DADOS: $_diceAmount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
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
                width: 45,
                height: 35,
                decoration: BoxDecoration(
                  color: isSelected ? redColor : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? redColor : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Center(
                  child: Text(
                    'D$dice',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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

class DiceWidget extends StatelessWidget {
  final String result;
  final String diceType;
  final double size;

  const DiceWidget({
    super.key,
    required this.result,
    required this.diceType,
    this.size = 220,
  });

  static const Color redColor = Color(0xFFE63946);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DicePainter(),
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  static const Color redColor = Color(0xFFE63946);
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
      ..color = redColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final dicePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = redColor
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}