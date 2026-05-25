import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import '../../widgets/app_drawer.dart';
import 'providers/akropolis_tracker_provider.dart';
import '../widgets/tracker_dialogs.dart';
import 'widgets/akropolis_grid_table.dart';
import 'widgets/akropolis_input_panel.dart';
import '../../widgets/custom_alert.dart';

class AkropolisTrackerScreen extends ConsumerStatefulWidget {
  final int playerCount;

  const AkropolisTrackerScreen({super.key, required this.playerCount});

  @override
  ConsumerState<AkropolisTrackerScreen> createState() =>
      _AkropolisTrackerScreenState();
}

class _AkropolisTrackerScreenState
    extends ConsumerState<AkropolisTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref
            .read(akropolisTrackerProvider.notifier)
            .initialize(widget.playerCount, user);
      }
    });
  }

  // _showEntityEditor removed, using TrackerDialogs.showEntityEditor
  // _getExplanation removed, using AkropolisHexagonExtension
  // _getHexColor removed, using AkropolisHexagonExtension

  // Removed _getHexName

  // Removed _showInfoDialog

  // _showNumberPad removed, using TrackerDialogs.showNumberPadDialog

  // _buildGridTable and _buildInputPanel extracted to widgets

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(akropolisTrackerProvider);
    final notifier = ref.read(akropolisTrackerProvider.notifier);

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
              'AKROPOLIS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/images/burako_icon.svg',
              height: 24,
              width: 24,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: const AkropolisGridTable(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const AkropolisInputPanel(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p24,
                vertical: AppSizes.p16,
              ),
              child: TrackerBottomBar(
                onBack: () => context.pop(),
                onSave: () {
                  final hasUnsavedScores = state.buffer.districtValue != 0 || state.buffer.starsValue != 0;
                  if (hasUnsavedScores) {
                    CustomAlert.show(
                      context,
                      'Debes sumar los puntos en curso antes de guardar la partida.',
                      isError: true,
                    );
                    return;
                  }

                  List<DialogPlayerInfo> flattenedPlayers = [];
                  for (var e in state.entities) {
                    flattenedPlayers.add(
                      DialogPlayerInfo(e.name, e.totalScore),
                    );
                  }

                  int maxScore = state.entities.isNotEmpty
                      ? state.entities
                            .map((e) => e.totalScore)
                            .reduce((a, b) => a > b ? a : b)
                      : 0;
                  String winners = state.entities
                      .where((e) => e.totalScore == maxScore)
                      .map((e) => e.name)
                      .join(' y ');

                  TrackerDialogs.showFinishMatchDialog(
                    context: context,
                    gameId: state.selectedGame?.id,
                    gameName: state.selectedGame?.name,
                    players: flattenedPlayers,
                    customWinnerName: winners,
                    customMaxScore: maxScore,
                    onSaveMatch: (finalScores) async {
                      if (state.selectedGame != null) {
                        await ref
                            .read(matchServiceProvider)
                            .saveMatch(
                              gameId: state.selectedGame!.id,
                              gameName: state.selectedGame!.name,
                              playerScores: finalScores,
                            );
                      }
                    },
                    onClearState: () {
                      notifier.resetAllScores();
                    },
                    onNavigateHome: () {
                      if (mounted) context.go('/home');
                    },
                  );
                },
                centerWidget: IconButton.filledTonal(
                  iconSize: 28,
                  padding: const EdgeInsets.all(12),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onErrorContainer,
                  ),
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    TrackerDialogs.showResetDialog(
                      context: context,
                      onConfirm: () {
                        notifier.resetAllScores();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
