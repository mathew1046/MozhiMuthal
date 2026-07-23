import 'package:flutter/material.dart';

import '../../widgets/app_ui.dart';

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
  const ProtocolCard({
    super.key,
    required this.protocol,
    required this.elapsed,
    required this.isRecording,
  });

  final ProtocolInfo protocol;
  final int elapsed;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (elapsed / protocol.durationSec).clamp(0.0, 1.0);
    return AppSurface(
      color: scheme.surface,
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconBadge(
                  icon: protocol.icon,
                  color: scheme.secondary,
                  size: 70,
                ),
                const SizedBox(height: 20),
                Text(
                  protocol.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  protocol.instruction,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          backgroundColor: scheme.primaryContainer,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$elapsed',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          Text(
                            'of ${protocol.durationSec} sec',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppPill(
                  label: isRecording ? 'RECORDING' : 'READY TO CONTINUE',
                  color: isRecording ? const Color(0xFFC43D42) : scheme.primary,
                  icon: isRecording
                      ? Icons.fiber_manual_record_rounded
                      : Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
