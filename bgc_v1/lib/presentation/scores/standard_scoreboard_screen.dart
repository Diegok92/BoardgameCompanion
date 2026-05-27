import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandardScoreboardScreen extends StatefulWidget {
  final int playerCount;

  const StandardScoreboardScreen({super.key, required this.playerCount});

  @override
  State<StandardScoreboardScreen> createState() =>
      _StandardScoreboardScreenState();
}

class _StandardScoreboardScreenState extends State<StandardScoreboardScreen> {
  static const List<Color> _playerColors = [
    Color(0xFFEF3743),
    Color(0xFF2F7DF4),
    Color(0xFF18B979),
    Color(0xFFFFA726),
    Color(0xFF8B5CF6),
    Color(0xFF6B7280),
  ];

  final List<String> _gameOptions = [
    'Carcassonne',
    'Catan',
    'Ticket to Ride',
    'Splendor',
    'Otro',
  ];

  late int _playerCount;
  late List<int> _scores;

  String _selectedGame = 'Carcassonne';

  @override
  void initState() {
    super.initState();

    _playerCount = widget.playerCount.clamp(1, 6);
    _scores = List<int>.filled(_playerCount, 0);
  }

  List<String> get _players {
    return List.generate(_playerCount, (index) {
      if (index == 0) return '{USUARIO}';
      return 'JUGADOR ${index + 1}';
    });
  }

  Future<void> _openScoreCalculator(int playerIndex) async {
    final points = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return ScoreCalculatorDialog(
          playerName: _players[playerIndex],
          playerColor: _playerColors[playerIndex],
        );
      },
    );

    if (points == null || points == 0) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final actionText = points > 0 ? 'sumar' : 'restar';
        final formattedPoints = points.abs();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'CONFIRMAR CAMBIO',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            '¿Estás seguro de que querés $actionText $formattedPoints puntos a ${_players[playerIndex]}?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'CANCELAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _scores[playerIndex] += points;
    });
  }

  void _resetScores() {
    setState(() {
      _scores = List<int>.filled(_playerCount, 0);
    });
  }

  String _getWinner() {
    int winnerIndex = 0;
    int maxScore = _scores[0];

    for (int i = 1; i < _scores.length; i++) {
      if (_scores[i] > maxScore) {
        maxScore = _scores[i];
        winnerIndex = i;
      }
    }

    return _players[winnerIndex];
  }

  Future<void> _finishGame() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'FINALIZAR PARTIDA',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            '¿Estás seguro de que querés finalizar la partida?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'CANCELAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (shouldFinish != true) return;
    if (!mounted) return;

    await _showGameResultDialog();

    if (!mounted) return;

    _resetScores();
  }

  Future<void> _showGameResultDialog() async {
    final winner = _getWinner();
    final winnerIndex = _players.indexOf(winner);
    final winnerScore = winnerIndex >= 0 ? _scores[winnerIndex] : 0;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'PARTIDA FINALIZADA',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'El ganador es:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                winner,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF18B979),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Puntaje: $winnerScore',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Al cerrar este mensaje, los puntajes se reiniciarán.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'ACEPTAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 390,
            constraints: const BoxConstraints(maxWidth: 430),
            color: const Color(0xFFF3F6FA),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                  child: _buildInfoBar(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildScoresGrid(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: _buildFinishRow(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.menu, size: 28, color: Color(0xFF1F2937)),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'BG Companion',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A3D),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGame,
                      isDense: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                      items: _gameOptions.map((game) {
                        return DropdownMenuItem(value: game, child: Text(game));
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedGame = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.cases_rounded,
                  color: Color(0xFFEF3743),
                  size: 28,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF3743),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DEE8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, size: 20, color: Color(0xFF2F7DF4)),
          const SizedBox(width: 8),
          Text(
            'Jugadores: $_playerCount',
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          const Flexible(
            child: Text(
              'Tocá un jugador para modificar',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _playerCount <= 3 ? 1 : 2;
        final rows = (_playerCount / columns).ceil();
        final spacing = 10.0;
        final availableHeight = constraints.maxHeight - (spacing * (rows - 1));
        final cardHeight = availableHeight / rows;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _playerCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: cardHeight.clamp(86, 132),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemBuilder: (context, index) {
            return _buildPlayerScoreCard(
              playerIndex: index,
              playerName: _players[index],
              score: _scores[index],
              color: _playerColors[index],
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerScoreCard({
    required int playerIndex,
    required String playerName,
    required int score,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _openScoreCalculator(playerIndex),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ),
              ),
              child: Center(
                child: Text(
                  playerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17345F),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Tocar para modificar',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _finishGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B3F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'TERMINAR PARTIDA',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            onPressed: _resetScores,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF3743),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.delete, size: 25),
          ),
        ),
      ],
    );
  }
}

class ScoreCalculatorDialog extends StatefulWidget {
  final String playerName;
  final Color playerColor;

  const ScoreCalculatorDialog({
    super.key,
    required this.playerName,
    required this.playerColor,
  });

  @override
  State<ScoreCalculatorDialog> createState() => _ScoreCalculatorDialogState();
}

class _ScoreCalculatorDialogState extends State<ScoreCalculatorDialog> {
  String _input = '';
  bool _isNegative = false;

  int get _currentValue {
    if (_input.isEmpty) return 0;

    final value = int.tryParse(_input) ?? 0;
    return _isNegative ? -value : value;
  }

  void _pressNumber(String number) {
    if (_input.length >= 6) return;

    setState(() {
      if (_input == '0') {
        _input = number;
      } else {
        _input += number;
      }
    });
  }

  void _toggleSign() {
    setState(() {
      _isNegative = !_isNegative;
    });
  }

  void _deleteLast() {
    if (_input.isEmpty) return;

    setState(() {
      _input = _input.substring(0, _input.length - 1);
    });
  }

  void _clear() {
    setState(() {
      _input = '';
      _isNegative = false;
    });
  }

  void _confirm() {
    Navigator.pop(context, _currentValue);
  }

  String _displayValue() {
    if (_input.isEmpty) return '0';

    if (_isNegative) return '-$_input';

    return '+$_input';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Column(
        children: [
          Text(
            widget.playerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.playerColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Modificar puntaje',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 310,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.playerColor, width: 2),
              ),
              child: Text(
                _displayValue(),
                style: TextStyle(
                  color: widget.playerColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildCalculatorGrid(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _currentValue == 0 ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.playerColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONFIRMAR',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorGrid() {
    final buttons = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '+/-',
      '0',
      '⌫',
      'C',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: buttons.map((button) {
        final isControl = button == '+/-' || button == '⌫' || button == 'C';

        return SizedBox(
          width: button == 'C' ? 270 : 80,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (button == '+/-') {
                _toggleSign();
              } else if (button == '⌫') {
                _deleteLast();
              } else if (button == 'C') {
                _clear();
              } else {
                _pressNumber(button);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isControl
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF1F2937),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              button,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
          ),
        );
      }).toList(),
    );
  }
}
