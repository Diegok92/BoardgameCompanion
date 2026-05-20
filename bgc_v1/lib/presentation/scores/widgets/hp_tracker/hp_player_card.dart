import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../providers/hp_tracker_provider.dart';

class HpPlayerCard extends StatefulWidget {
  final TrackerPlayer player;
  final List<String> invitados;
  final List<TrackerPlayer> allPlayers;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<int> onHpChange;

  const HpPlayerCard({
    super.key,
    required this.player,
    required this.invitados,
    required this.allPlayers,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onHpChange,
  });

  @override
  State<HpPlayerCard> createState() => _HpPlayerCardState();
}

class _HpPlayerCardState extends State<HpPlayerCard> {
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

  void _showColorPicker(BuildContext context) {
    final usedColors = widget.allPlayers.map((p) => p.color.toARGB32()).toSet();
    final available = AppColors.availableColors
        .where(
          (c) =>
              !usedColors.contains(c.toARGB32()) ||
              c.toARGB32() == widget.player.color.toARGB32(),
        )
        .toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elegir Color'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: available.map((color) {
              return GestureDetector(
                onTap: () {
                  widget.onColorChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Widget _buildNameWidget(bool isUser) {
    if (isUser) {
      return Text(
        widget.player.name ?? 'Usuario',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: widget.player.color,
        ),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return PopupMenuButton<String>(
        initialValue: widget.player.name,
        onSelected: widget.onNameChanged,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (BuildContext context) {
          return [
            ...widget.invitados.map(
              (i) => PopupMenuItem(
                value: i,
                child: Text(
                  i,
                  style: TextStyle(
                    color: widget.player.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const PopupMenuItem(
              value: 'NUEVO_INVITADO',
              child: Text(
                '+ Agregar...',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.player.name ?? 'Jugador ${widget.player.index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: widget.player.name == null
                      ? widget.player.color.withValues(alpha: 0.6)
                      : widget.player.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: widget.player.color),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.player.index == 0;
    // Calculate preview HP including the pending delta
    final displayHp = widget.player.hp + _pendingDelta;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSinglePlayer = widget.allPlayers.length == 1;
        bool isWide = constraints.maxWidth > constraints.maxHeight * 1.3;

        final colorSelector = GestureDetector(
          onTap: () => _showColorPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.player.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 1),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: widget.player.color, size: 22),
            ],
          ),
        );

        Widget capsuleContent;
        if (isSinglePlayer) {
          capsuleContent = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              colorSelector,
              const SizedBox(width: 16),
              Container(
                width: 2,
                height: 32,
                color: widget.player.color.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Flexible(child: _buildNameWidget(isUser)),
            ],
          );
        } else if (isWide) {
          capsuleContent = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              colorSelector,
              const SizedBox(height: 6),
              Container(
                height: 1.5,
                width: 32,
                color: widget.player.color.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 6),
              Flexible(child: _buildNameWidget(isUser)),
            ],
          );
        } else {
          capsuleContent = _buildNameWidget(isUser);
        }

        final capsule = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 4.0 : 16.0,
            vertical: isWide ? 16.0 : 4.0,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 8 : (isSinglePlayer ? 24 : 16),
              vertical: isWide ? 16 : (isSinglePlayer ? 12 : 2),
            ),
            decoration: BoxDecoration(
              color: widget.player.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isSinglePlayer ? 32 : 24),
              border: Border.all(
                color: widget.player.color.withValues(alpha: 0.3),
                width: isSinglePlayer ? 2.0 : 1.5,
              ),
            ),
            child: capsuleContent,
          ),
        );

        final shield = Expanded(
          child: LayoutBuilder(
            builder: (context, shieldConstraints) {
              
              double shieldSize = shieldConstraints.biggest.shortestSide * 1.0;

              final shieldStack = Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Flechas internas
                  Align(
                    alignment: const Alignment(0, -0.45),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      size: 64,
                      color: widget.player.color.withValues(alpha: 0.6),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.45),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 64,
                      color: widget.player.color.withValues(alpha: 0.6),
                    ),
                  ),

                  Icon(
                    Icons.shield,
                    size: shieldSize,
                    color: widget.player.color.withValues(alpha: 0.2),
                  ),
                  Icon(
                    Icons.shield_outlined,
                    size: shieldSize,
                    color: widget.player.color,
                  ),

                  // Número Central con animación
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
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
                      top: shieldConstraints.maxHeight * 0.15,
                      right: shieldConstraints.maxWidth * 0.15,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 200),
                        builder: (context, val, child) {
                          return Transform.scale(scale: val, child: child);
                        },
                        child: Text(
                          _pendingDelta > 0
                              ? '+$_pendingDelta'
                              : '$_pendingDelta',
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

                  // (Flechas internas se movieron arriba en el stack)
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
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 1, child: Center(child: capsule)),
              Expanded(flex: 2, child: shield),
            ],
          );
        } else {
          return Column(
            children: [
              const SizedBox(height: 16),
              capsule,
              Expanded(
                child: isSinglePlayer
                    ? shield
                    : Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: colorSelector,
                          ),
                          shield,
                        ],
                      ),
              ),
            ],
          );
        }
      },
    );
  }
}
