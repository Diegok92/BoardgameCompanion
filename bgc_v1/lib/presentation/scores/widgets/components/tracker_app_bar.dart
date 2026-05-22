import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TrackerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget rightWidget;

  const TrackerAppBar({
    super.key,
    required this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false, // Ocultar el botón de back por defecto para poner nuestro logo
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo e indicador
          Builder(
            builder: (context) => InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/images/logo.svg', height: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'BG Companion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
          
          // Widget dinámico a la derecha (dropdown o título)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: rightWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
