import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/station.dart';

enum StationCardState { sending, sent, error }

class StationCard extends StatelessWidget {
  final Station station;
  final StationCardState cardState;
  final String? errorMessage;
  final VoidCallback onDismiss;

  const StationCard({
    super.key,
    required this.station,
    required this.cardState,
    this.errorMessage,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cardState == StationCardState.sent
                ? AppTheme.success
                : cardState == StationCardState.error
                    ? AppTheme.error
                    : AppTheme.accent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              station.address,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.near_me, color: AppTheme.accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${station.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.navigation, color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${station.headingDiffDeg.toStringAsFixed(0)}° von Kurs',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatusRow(cardState: cardState, errorMessage: errorMessage),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final StationCardState cardState;
  final String? errorMessage;

  const _StatusRow({required this.cardState, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return switch (cardState) {
      StationCardState.sending => const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
            SizedBox(width: 10),
            Text('Wird an Kia gesendet …', style: TextStyle(color: AppTheme.accent, fontSize: 16)),
          ],
        ),
      StationCardState.sent => const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 22),
            SizedBox(width: 8),
            Text('An Kia gesendet ✓', style: TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      StationCardState.error => Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage ?? 'Fehler beim Senden',
                style: const TextStyle(color: AppTheme.error, fontSize: 16),
              ),
            ),
          ],
        ),
    };
  }
}
