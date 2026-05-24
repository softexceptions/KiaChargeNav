import 'package:flutter/material.dart';
import '../app_theme.dart';

class NetworkChip extends StatelessWidget {
  final String networkKey;
  final VoidCallback onTap;

  const NetworkChip({super.key, required this.networkKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.networkColors[networkKey] ?? AppTheme.accent;
    final label = AppTheme.networkLabels[networkKey] ?? networkKey;
    final isDark = color.computeLuminance() > 0.4;
    final textColor = isDark ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
