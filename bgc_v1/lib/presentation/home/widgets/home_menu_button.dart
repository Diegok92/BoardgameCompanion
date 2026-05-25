import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeMenuButton extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final Color backgroundColor;
  final Color? foregroundColor;
  final VoidCallback onPressed;
  final bool isSecondary;

  const HomeMenuButton({
    super.key,
    this.icon,
    this.svgAsset,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor,
    required this.onPressed,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Height based on Figma
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: isSecondary
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (isSecondary)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (svgAsset != null)
                    SvgPicture.asset(svgAsset!, height: 32)
                  else if (icon != null)
                    Icon(icon, size: 32, color: foregroundColor ?? Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (foregroundColor ?? Colors.white).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: svgAsset != null 
                    ? SvgPicture.asset(
                        svgAsset!, 
                        height: 24,
                        colorFilter: ColorFilter.mode(foregroundColor ?? Colors.white, BlendMode.srcIn),
                      )
                    : (icon != null ? Icon(icon, color: foregroundColor ?? Colors.white, size: 24) : const SizedBox(width: 24)),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
