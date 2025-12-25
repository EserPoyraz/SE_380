import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsets padding;
  final bool glow;
  final Color? glowColor;

  const AppCard({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: (glowColor ?? AppTheme.neonPurple).withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
