import 'package:flutter/material.dart';

import '../../widgets/app_ui.dart';

class BiomarkerChipWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool flagged;

  const BiomarkerChipWidget({
    super.key,
    required this.label,
    required this.value,
    required this.flagged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = flagged
        ? const Color(0xFFB53A4A)
        : const Color(0xFF367E62);
    final icon = flagged ? Icons.info_outline_rounded : Icons.check_rounded;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          RoundIcon(
            icon: icon,
            size: 40,
            color: statusColor.withValues(alpha: 0.12),
            iconColor: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  flagged ? 'Needs attention' : 'Within expected range',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
