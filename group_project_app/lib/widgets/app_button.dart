import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonStyle { primary, glass }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AppButtonStyle style;
  final Color? accentColor;

  final IconData? icon;
  final double iconSize;

  // ✅ opsiyonel: buton kart içinde tam genişlik olsun mu?
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.accentColor,
    this.icon,
    this.iconSize = 18,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? AppTheme.neonPurple;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    // ✅ Sığmazsa otomatik küçült (OVERFLOW gider)
    final scaledContent = FittedBox(
      fit: BoxFit.scaleDown,
      child: content,
    );

    final buttonChild = SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 36,
      child: style == AppButtonStyle.primary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10), // ✅ küçük kartlara uygun
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: scaledContent,
            )
          : GestureDetector(
              onTap: onPressed,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  child: IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: scaledContent,
                  ),
                ),
              ),
            ),
    );

    return buttonChild;
  }
}
