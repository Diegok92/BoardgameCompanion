import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_drawer.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import '../widgets/tracker_dialogs.dart';
import 'providers/burako_tracker_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/burako_entity_editor_dialog.dart';
import 'widgets/burako_buffer_editor.dart';
import '../widgets/player_badge.dart';

class BurakoTrackerScreen extends ConsumerStatefulWidget {
  final int playerCount;

  const BurakoTrackerScreen({super.key, required this.playerCount});

  @override
  ConsumerState<BurakoTrackerScreen> createState() => _BurakoTrackerScreenState();
}

class _BurakoTrackerScreenState extends ConsumerState<BurakoTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref.read(burakoTrackerProvider.notifier).initialize(widget.playerCount, user);
      }
    });
  }

  // Extracted methods replaced by BurakoEntityEditorDialog and BurakoBufferEditor

  Widget _buildEntityHeader(BurakoEntity entity, int index) {
    return Expanded(
      child: Column(
        children: [
          PlayerBadge(
            name: entity.name,
            color: entity.color,
            onTap: () => BurakoEntityEditorDialog.show(context, ref, index),
          ),
          const SizedBox(height: 8),
          Text(
            '${entity.totalScore}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // _buildBufferEditor removed, using BurakoBufferEditor

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(burakoTrackerProvider);

    if (state.entities.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: TrackerAppBar(
        rightWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'BURAKO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset('assets/images/burako_icon.svg', height: 24, width: 24),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Header de totales
              Row(
                children: List.generate(state.entities.length, (index) {
                  final e = state.entities[index];
                  return _buildEntityHeader(e, index);
                }),
              ),
              const Divider(height: 32),
              
              // Buffer Editor (sin scroll)
              const Expanded(
                child: BurakoBufferEditor(),
              ),

              // Bottom Bar
              TrackerBottomBar(
                onBack: () async {
                  await ref.read(burakoTrackerProvider.notifier).saveLocalState();
                  if (context.mounted) Navigator.pop(context);
                },
                onSave: () {
                  final state = ref.read(burakoTrackerProvider);
                  
                  List<DialogPlayerInfo> flattenedPlayers = [];
                  for (var e in state.entities) {
                    for (var p in e.playerNames) {
                      flattenedPlayers.add(DialogPlayerInfo(p, e.totalScore));
                    }
                  }

                  int maxScore = state.entities.isNotEmpty ? state.entities.map((e) => e.totalScore).reduce((a, b) => a > b ? a : b) : 0;
                  String winners = state.entities.where((e) => e.totalScore == maxScore).map((e) => e.name).join(' y ');

                  TrackerDialogs.showFinishMatchDialog(
                    context: context,
                    gameId: state.selectedGame?.id,
                    gameName: state.selectedGame?.name,
                    players: flattenedPlayers,
                    customWinnerName: winners,
                    customMaxScore: maxScore,
                    onSaveMatch: (finalScores) async {
                      await ref.read(matchServiceProvider).saveMatch(
                        gameId: state.selectedGame!.id,
                        gameName: state.selectedGame!.name,
                        playerScores: finalScores,
                      );
                    },
                    onClearState: () => ref.read(burakoTrackerProvider.notifier).clearLocalState(),
                    onNavigateHome: () {
                      if (mounted) context.go('/home');
                    },
                  );
                },
                centerWidget: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  iconSize: 20,
                  padding: const EdgeInsets.all(12),
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () {
                    TrackerDialogs.showResetDialog(
                      context: context,
                      onConfirm: () => ref.read(burakoTrackerProvider.notifier).resetGame(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
