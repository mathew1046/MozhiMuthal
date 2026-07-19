import 'package:flutter/material.dart';

class ProtocolInfo {
  final String title;
  final String instruction;
  final IconData icon;
  final int durationSec;

  const ProtocolInfo({
    required this.title,
    required this.instruction,
    required this.icon,
    required this.durationSec,
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
    final progress = elapsed / protocol.durationSec;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Icon(protocol.icon, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 20),

          // Title
          Text(
            protocol.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Instruction
          Text(
            protocol.instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Timer ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$elapsed',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/ ${protocol.durationSec}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recording indicator
          if (isRecording)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFC62828),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Recording',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            )
          else
            Text(
              'Complete',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
