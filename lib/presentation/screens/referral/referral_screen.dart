import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/session_provider.dart';
import '../../../services/whatsapp_service.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profile = session.childProfile;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Referral Letter')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Referral preview card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MozhiMuthal Referral',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                      label: 'Anganwadi ID',
                      value: profile?.anganwadiId ?? '-'),
                  const SizedBox(height: 6),
                  _InfoRow(
                      label: 'Child Age',
                      value: '${profile?.childAgeMonths ?? "-"} months'),
                  const SizedBox(height: 6),
                  _InfoRow(
                      label: 'VTTL',
                      value:
                          '${session.vttlMs.toStringAsFixed(0)} ms ${session.result?.vttlFlagged == true ? "⚠" : "✓"}'),
                  const SizedBox(height: 6),
                  _InfoRow(
                      label: 'CVR',
                      value:
                          '${session.cvrRatio.toStringAsFixed(3)} ${session.result?.cvrFlagged == true ? "⚠" : "✓"}'),
                  if (profile != null && profile.childAgeMonths >= 36) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                        label: 'PFV',
                        value:
                            '${session.pfvStd.toStringAsFixed(2)} ${session.result?.pfvFlagged == true ? "⚠" : "✓"}'),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'ഈ കുട്ടിക്ക് DEIC-ൽ കൂടുതൽ വിലയിരുത്തൽ ആവശ്യമാണ്.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Share via WhatsApp
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
                    const SnackBar(content: Text('Could not open WhatsApp. Please check if it is installed.')),
                  );
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Share via WhatsApp'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Back to Dashboard'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            )),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
