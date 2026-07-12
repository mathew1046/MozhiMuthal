import 'package:flutter/material.dart';

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: flagged
                  ? const Color(0xFFC62828).withOpacity(0.1)
                  : const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              flagged ? '⚠ Flagged' : '✓ Normal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: flagged
                    ? const Color(0xFFC62828)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
