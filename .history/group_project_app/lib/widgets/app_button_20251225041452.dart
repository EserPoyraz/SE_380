import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonStyle { primary, glass }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AppButtonStyle style;
  final Color? accentColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? AppTheme.neonPurple;

    return SizedBox(
      height: 36,
      child: style == AppButtonStyle.primary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(text),
            )
          : GestureDetector(
              onTap: onPressed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
    );
  }
}
