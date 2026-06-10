import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/accessory_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessories_provider.dart';
import '../widgets/bgc_app_bar.dart';
import '../widgets/custom_alert.dart';

class AccessoriesScreen extends ConsumerWidget {
  const AccessoriesScreen({super.key});

  void _openAccessory(BuildContext context, Accessory accessory) {
    final accessoryName = accessory.name.toLowerCase();

    if (accessoryName.contains('moneda') || accessoryName.contains('coin')) {
      context.push('/coin-flip');
      return;
    }

    if (accessoryName.contains('dados') || accessoryName.contains('dice')) {
      context.push('/dice-roll');
      return;
    }

    if (accessoryName.contains('ajedrez') || accessoryName.contains('chess')) {
      context.push('/chess-clock');
      return;
    }

    if (accessoryName.contains('arena') || accessoryName.contains('sand')) {
      context.push('/sand-timer');
      return;
    }

    if (accessoryName.contains('letra') || accessoryName.contains('letter')) {
      context.push('/letter-generator');
      return;
    }

    CustomAlert.show(context, 'Abriendo accesorio: ${accessory.name}...');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final accessoriesAsyncValue = ref.watch(accessoriesProvider);

    return Scaffold(
      appBar: const BgcAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: accessoriesAsyncValue.when(
            data: (accessories) {
              final gridAccessories = accessories.take(4).toList();
              final lastAccessory = accessories.length > 4
                  ? accessories.last
                  : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accesorios para partidas Epicas!',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    flex: 2,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: gridAccessories.length,
                      itemBuilder: (context, index) {
                        final accessory = gridAccessories[index];
                        return _buildAccessoryButton(
                          context: context,
                          accessory: accessory,
                          isExpanded: false,
                        );
                      },
                    ),
                  ),

                  if (lastAccessory != null) ...[
                    const SizedBox(height: 16),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildAccessoryButton(
                          context: context,
                          accessory: lastAccessory,
                          isExpanded: true,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessoryButton({
    required BuildContext context,
    required Accessory accessory,
    required bool isExpanded,
  }) {
    return GestureDetector(
      onTap: () => _openAccessory(context, accessory),
      child: Container(
        decoration: BoxDecoration(
          color: accessory.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accessory.color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              accessory.icon,
              size: isExpanded ? 64 : 48,
              color: accessory.color,
            ),
            const SizedBox(height: 12),
            Text(
              accessory.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isExpanded ? 20 : 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
