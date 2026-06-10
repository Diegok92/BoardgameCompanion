import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// AppBar estándar de la app: botón de volver + "BG Companion" + logo.
///
/// Lo usan las pantallas simples (accesorios, selector, etc.) para no repetir
/// la misma barra en cada una. [onBack] permite personalizar la acción de
/// volver (por defecto hace `context.pop()`).
class BgcAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;

  const BgcAppBar({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 32),
        onPressed: onBack ?? () => context.pop(),
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
