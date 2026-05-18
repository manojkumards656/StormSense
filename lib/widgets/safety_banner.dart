import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SafetyBanner extends StatelessWidget {
  final double distanceKm;

  const SafetyBanner({Key? key, required this.distanceKm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (distanceKm > 10.0) {
      return const SizedBox.shrink(); // Safe
    }

    final bool isCritical = distanceKm < 3.0;
    final Color bgColor = isCritical ? AppTheme.criticalColor.withOpacity(0.2) : AppTheme.warningColor.withOpacity(0.2);
    final Color iconColor = isCritical ? AppTheme.criticalColor : AppTheme.warningColor;
    final String message = isCritical 
        ? "CRITICAL: Lightning very close! Seek shelter immediately."
        : "WARNING: Lightning nearby. Be prepared to seek shelter.";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
