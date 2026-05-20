import 'dart:async';
import 'package:flutter/material.dart';

class HpShield extends StatefulWidget {
  final int hp;
  final Color color;
  final ValueChanged<int> onHpChange;

  const HpShield({
    super.key,
    required this.hp,
    required this.color,
    required this.onHpChange,
  });

  @override
  State<HpShield> createState() => _HpShieldState();
}

class _HpShieldState extends State<HpShield> {
  int _pendingDelta = 0;
  Timer? _debounceTimer;

  void _handleTap(int delta) {
    setState(() {
      _pendingDelta += delta;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_pendingDelta != 0) {
        widget.onHpChange(_pendingDelta);
        setState(() {
          _pendingDelta = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayHp = widget.hp + _pendingDelta;

    return LayoutBuilder(
      builder: (context, constraints) {
        double shieldSize = constraints.biggest.shortestSide * 1.0;

        final shieldStack = Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Flechas internas
            Align(
              alignment: const Alignment(0, -0.60),
              child: Icon(
                Icons.keyboard_arrow_up,
                size: 64,
                color: widget.color.withValues(alpha: 0.6),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.60),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 64,
                color: widget.color.withValues(alpha: 0.6),
              ),
            ),

            Icon(
              Icons.shield,
              size: shieldSize,
              color: widget.color.withValues(alpha: 0.2),
            ),
            Icon(
              Icons.shield_outlined,
              size: shieldSize,
              color: widget.color,
            ),

            // Número Central con animación
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Text(
                '$displayHp',
                key: ValueKey<int>(displayHp),
                style: TextStyle(
                  fontSize: shieldSize * 0.35,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // Popup de Delta Acumulado
            if (_pendingDelta != 0)
              Positioned(
                top: constraints.maxHeight * 0.15,
                right: constraints.maxWidth * 0.15,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, val, child) {
                    return Transform.scale(scale: val, child: child);
                  },
                  child: Text(
                    _pendingDelta > 0 ? '+$_pendingDelta' : '$_pendingDelta',
                    style: TextStyle(
                      fontSize: shieldSize * 0.20,
                      fontWeight: FontWeight.w900,
                      color: _pendingDelta > 0
                          ? Colors.green[700]
                          : Colors.red[700],
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );

        return Stack(
          children: [
            Center(child: shieldStack),
            // Zonas Táctiles Invisibles
            Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleTap(1),
                    child: Container(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleTap(-1),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
