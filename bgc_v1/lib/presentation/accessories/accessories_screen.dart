import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/accessory_model.dart';
import '../../data/mock/mock_accessories_database.dart';

class AccessoriesScreen extends StatelessWidget {
  final User user;

  const AccessoriesScreen({super.key, required this.user});

  void _openAccessory(BuildContext context, Accessory accessory) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo accesorio: ${accessory.name}...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accessories = MockAccessoriesDatabase.accessories;

    // Los primeros 4 accesorios van en grilla (2x2)
    final gridAccessories = accessories.take(4).toList();
    // El último accesorio (Reloj de Arena) va expandido abajo
    final lastAccessory = accessories.length > 4 ? accessories.last : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BG Companion',
              style: textTheme.headlineSmall?.copyWith(
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accesorios para partidas Epicas!',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 24),

              // Cuadrícula para los primeros 4 accesorios
              Expanded(
                flex: 2,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0, // Botones cuadrados
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

              // Botón grande inferior para el último accesorio
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
          color: accessory.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accessory.color.withOpacity(0.5), width: 2),
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
                color: Colors.blueGrey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
