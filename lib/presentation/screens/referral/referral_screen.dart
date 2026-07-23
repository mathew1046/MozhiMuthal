import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/whatsapp_service.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_ui.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profile = session.childProfile;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Referral letter')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionHeader(
                title: 'A next step for the family',
                subtitle:
                    'Share this referral when a DEIC visit is recommended.',
              ),
              const SizedBox(height: 20),
              AppSurface(
                color: scheme.surface,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconBadge(
                          icon: Icons.description_outlined,
                          color: const Color(0xFFC43D42),
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'MozhiMuthal referral',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: scheme.outlineVariant),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'Anganwadi ID',
                      value: profile?.anganwadiId ?? '—',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Child age',
                      value: '${profile?.childAgeMonths ?? '—'} months',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'VTTL',
                      value:
                          '${session.vttlMs.toStringAsFixed(0)} ms ${session.result?.vttlFlagged == true ? '• Flagged' : '• Within range'}',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'CVR',
                      value:
                          '${session.cvrRatio.toStringAsFixed(3)} ${session.result?.cvrFlagged == true ? '• Flagged' : '• Within range'}',
                    ),
                    if (session.result?.pfvInsufficientData != true) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'PFV',
                        value:
                            '${session.pfvStd.toStringAsFixed(2)} semitone SD ${session.result?.pfvFlagged == true ? '• Flagged' : '• Within range'}',
                      ),
                    ],
                    const SizedBox(height: 22),
                    AppSurface(
                      color: scheme.errorContainer.withOpacity(.55),
                      borderColor: scheme.errorContainer,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Further developmental evaluation at a DEIC centre is recommended.',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  final sent = await WhatsAppService.share(
                    text:
                        'MozhiMuthal Screening Referral\n'
                        'Anganwadi: ${profile?.anganwadiId}\n'
                        'Age: ${profile?.childAgeMonths} months\n'
                        'Result: RED — DEIC visit recommended',
                  );
                  if (!sent && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not open WhatsApp. Please check if it is installed.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share on WhatsApp'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Return home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
