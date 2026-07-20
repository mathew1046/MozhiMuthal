import 'package:flutter/material.dart';

import '../../widgets/app_ui.dart';

enum ProtocolTint { lilac, blue, pink }

class ProtocolInfo {
  final String title;
  final String instruction;
  final IconData icon;
  final int durationSec;
  final ProtocolTint tint;

  const ProtocolInfo({
    required this.title,
    required this.instruction,
    required this.icon,
    required this.durationSec,
    required this.tint,
  });
}

class ProtocolCard extends StatelessWidget {
  final ProtocolInfo protocol;
  final int elapsed;
  final bool isRecording;

  const ProtocolCard({
    super.key,
    required this.protocol,
    required this.elapsed,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (accent, onAccent) = switch (protocol.tint) {
      ProtocolTint.lilac => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      ProtocolTint.blue => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      ProtocolTint.pink => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
    };
    final progress = (elapsed / protocol.durationSec).clamp(0.0, 1.0);

    return SoftCard(
      color: accent.withValues(alpha: 0.34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RoundIcon(
            icon: protocol.icon,
            size: 82,
            color: accent,
            iconColor: onAccent,
          ),
          const SizedBox(height: 22),
          Text(
            protocol.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 9),
          Text(
            protocol.instruction,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 142,
            height: 142,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 142,
                  height: 142,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: onAccent,
                    backgroundColor: onAccent.withValues(alpha: 0.13),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$elapsed s',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: onAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${protocol.durationSec}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onAccent.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: isRecording
                  ? const Color(0xFFB53A4A).withValues(alpha: 0.12)
                  : colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRecording
                      ? Icons.fiber_manual_record_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isRecording ? const Color(0xFFB53A4A) : colors.primary,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  isRecording ? 'Recording in progress' : 'Activity complete',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isRecording
                        ? const Color(0xFFB53A4A)
                        : colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
