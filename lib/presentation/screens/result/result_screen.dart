import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/biomarker_result.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_ui.dart';
import 'biomarker_chip.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  Future<void> _saveAndLeave(
    BuildContext context,
    WidgetRef ref, {
    required bool referral,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final workerName = prefs.getString('worker_name') ?? 'Worker';
    await ref.read(sessionProvider.notifier).completeSession(workerName);
    if (!context.mounted) return;
    if (referral) {
      context.push('/referral');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final result = session.result;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (result == null) {
      return Scaffold(
        body: Center(
          child: SoftCard(
            child: Text(
              'No result is available yet.',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    final riskColor = result.riskColor;
    final isRed = result.riskLevel == RiskLevel.red;
    final statusIcon = isRed
        ? Icons.priority_high_rounded
        : result.riskLevel == RiskLevel.yellow
        ? Icons.visibility_outlined
        : Icons.check_rounded;
    final statusTitle = isRed
        ? 'A DEIC visit is recommended.'
        : result.riskLevel == RiskLevel.yellow
        ? 'A follow-up screening is recommended.'
        : 'The screening is within the expected range.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening result'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'COMPLETE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text('A clear next step.', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 22),
            SoftCard(
              color: riskColor.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.22
                    : 0.1,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  RoundIcon(
                    icon: statusIcon,
                    size: 70,
                    color: riskColor.withValues(alpha: 0.17),
                    iconColor: riskColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.riskLabel,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusTitle,
                    style: theme.textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.malayalamExplanation,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text('Biomarker summary', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'These measurements guide the follow-up recommendation.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 13),
            BiomarkerChipWidget(
              label: 'Vocal turn-taking',
              value: '${session.vttlMs.toStringAsFixed(0)} ms',
              flagged: result.vttlFlagged,
            ),
            const SizedBox(height: 9),
            BiomarkerChipWidget(
              label: 'Child vocalisation',
              value: session.cvrRatio.toStringAsFixed(3),
              flagged: result.cvrFlagged,
            ),
            if (session.childProfile?.childAgeMonths != null &&
                session.childProfile!.childAgeMonths >= 36) ...[
              const SizedBox(height: 9),
              BiomarkerChipWidget(
                label: 'Prosodic variation',
                value: session.pfvStd.toStringAsFixed(2),
                flagged: result.pfvFlagged,
              ),
            ],
            const SizedBox(height: 26),
            if (isRed)
              FilledButton.icon(
                onPressed: () => _saveAndLeave(context, ref, referral: true),
                style: FilledButton.styleFrom(
                  backgroundColor: riskColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Save and prepare referral'),
              )
            else
              FilledButton.icon(
                onPressed: () => _saveAndLeave(context, ref, referral: false),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save screening'),
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
