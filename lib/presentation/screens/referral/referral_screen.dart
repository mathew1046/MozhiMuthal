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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Referral support')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const PageIntro(
              eyebrow: 'Recommended follow-up',
              title: 'Help the family take the next step.',
              subtitle:
                  'Share the screening outcome and support a DEIC visit for further assessment.',
            ),
            const SizedBox(height: 24),
            SoftCard(
              color: colors.tertiaryContainer.withValues(alpha: 0.47),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RoundIcon(
                        icon: Icons.description_outlined,
                        color: colors.tertiary,
                        iconColor: colors.onTertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'MozhiMuthal referral',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Anganwadi',
                    value: profile?.anganwadiId ?? '—',
                  ),
                  _InfoRow(
                    label: 'Child age',
                    value: '${profile?.childAgeMonths ?? '—'} months',
                  ),
                  _InfoRow(
                    label: 'Vocal turn-taking',
                    value: '${session.vttlMs.toStringAsFixed(0)} ms',
                  ),
                  _InfoRow(
                    label: 'Child vocalisation',
                    value: session.cvrRatio.toStringAsFixed(3),
                  ),
                  if (profile?.childAgeMonths != null &&
                      profile!.childAgeMonths >= 36)
                    _InfoRow(
                      label: 'Prosodic variation',
                      value: session.pfvStd.toStringAsFixed(2),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'This screen indicates that a more detailed DEIC assessment would be helpful.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  RoundIcon(
                    icon: Icons.favorite_outline_rounded,
                    size: 42,
                    color: colors.primaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use supportive language: this is a recommendation for further assessment, not a diagnosis.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
                        'Could not open WhatsApp. Please check that it is installed.',
                      ),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share via WhatsApp'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Text(value, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
