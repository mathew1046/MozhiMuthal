import 'package:flutter/material.dart';

import '../../widgets/app_ui.dart';

class BiomarkerChipWidget extends StatelessWidget {
  const BiomarkerChipWidget({
    super.key,
    required this.label,
    required this.value,
    required this.flagged,
    this.onTap,
  });

  final String label;
  final String value;
  final bool flagged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = flagged
        ? const Color(0xFFC43D42)
        : const Color(0xFF3B8B6A);
    return AppSurface(
      onTap: onTap,
      borderColor: flagged ? statusColor.withOpacity(.35) : null,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIconBadge(
            icon: label == 'VTTL'
                ? Icons.swap_horiz_rounded
                : label == 'CVR'
                ? Icons.graphic_eq_rounded
                : Icons.multitrack_audio_rounded,
            color: flagged ? statusColor : scheme.primary,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          AppPill(
            label: flagged ? 'FLAGGED' : 'WITHIN RANGE',
            color: statusColor,
            icon: flagged ? Icons.priority_high_rounded : Icons.check_rounded,
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: scheme.outline),
          ],
        ],
      ),
    );
  }
}
