import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/biomarker_result.dart';
import '../../../domain/my_child_engine.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_ui.dart';
import 'biomarker_chip.dart';
import 'biomarker_detail_sheet.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final result = session.result;
    final theme = Theme.of(context);
    if (result == null)
      return const Scaffold(body: Center(child: Text('No result available')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening summary'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSurface(
              color: result.riskColor.withOpacity(.09),
              borderColor: result.riskColor.withOpacity(.34),
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  AppIconBadge(
                    icon: result.riskLevel == RiskLevel.red
                        ? Icons.priority_high_rounded
                        : result.riskLevel == RiskLevel.yellow
                        ? Icons.visibility_outlined
                        : Icons.check_circle_outline_rounded,
                    color: result.riskColor,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text('Screening outcome', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    result.riskLabel,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: result.riskColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.malayalamExplanation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface.withOpacity(.74),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (session.audioSource == 'WEB_TEST_FIXTURE')
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Browser test data — not a live microphone or model result.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            AppSurface(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(.58),
              borderColor: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 19,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Screening signal only — not a diagnosis. Discuss concerns with a clinician or DEIC.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (session.questionnaireState != null) ...[
              _QuestionnaireSummary(
                state: session.questionnaireState!,
                evaluation: session.questionnaireEvaluation,
              ),
              const SizedBox(height: 20),
            ],
            Text('Acoustic signals', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tap a signal to see its explanation.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            BiomarkerChipWidget(
              label: 'VTTL',
              value: '${session.vttlMs.toStringAsFixed(0)} ms',
              flagged: result.vttlFlagged,
              onTap: () => showBiomarkerDetail(
                context,
                kind: BiomarkerKind.vttl,
                ageMonths: session.childProfile!.childAgeMonths,
                value: session.vttlMs,
                flagged: result.vttlFlagged,
                waveform: session.waveform,
                trace: session.decisionTrace,
              ),
            ),
            const SizedBox(height: 10),
            BiomarkerChipWidget(
              label: 'CVR',
              value: session.cvrRatio.toStringAsFixed(3),
              flagged: result.cvrFlagged,
              onTap: () => showBiomarkerDetail(
                context,
                kind: BiomarkerKind.cvr,
                ageMonths: session.childProfile!.childAgeMonths,
                value: session.cvrRatio,
                flagged: result.cvrFlagged,
                waveform: session.waveform,
                trace: session.decisionTrace,
              ),
            ),
            const SizedBox(height: 10),
            BiomarkerChipWidget(
              label: 'PFV',
              value: '${session.pfvStd.toStringAsFixed(2)} st SD',
              flagged: result.pfvFlagged,
              onTap: () => showBiomarkerDetail(
                context,
                kind: BiomarkerKind.pfv,
                ageMonths: session.childProfile!.childAgeMonths,
                value: session.pfvStd,
                flagged: result.pfvFlagged,
                waveform: session.waveform,
                trace: session.decisionTrace,
                pfvAgeZScore: result.pfvAgeZScore,
              ),
            ),
            const SizedBox(height: 26),
            if (result.riskLevel == RiskLevel.red)
              FilledButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final workerName = prefs.getString('worker_name') ?? 'Worker';
                  await ref
                      .read(sessionProvider.notifier)
                      .completeSession(workerName);
                  if (context.mounted) context.push('/referral');
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('Create referral letter'),
                style: FilledButton.styleFrom(
                  backgroundColor: result.riskColor,
                ),
              )
            else
              FilledButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final workerName = prefs.getString('worker_name') ?? 'Worker';
                  await ref
                      .read(sessionProvider.notifier)
                      .completeSession(workerName);
                  if (context.mounted) context.go('/');
                },
                child: const Text('Save screening'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Return home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionnaireSummary extends StatelessWidget {
  const _QuestionnaireSummary({required this.state, this.evaluation});
  final MyChildState state;
  final MyChildEvaluation? evaluation;

  @override
  Widget build(BuildContext context) {
    final evaluation = this.evaluation;
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: Icons.forum_outlined,
                color: scheme.tertiary,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Development questionnaire: ${MyChildEngine.tier(state)} — ${state.name}.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (evaluation != null) ...[
            const SizedBox(height: 12),
            Text(evaluation.message),
            const SizedBox(height: 4),
            Text(
              'Scored age: ${evaluation.effectiveAgeMonths.toStringAsFixed(1)} months${evaluation.correctedAgeUsed ? ' corrected' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...evaluation.domains.values.map(
              (domain) => ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(domain.domain),
                subtitle: Text(domain.status.replaceAll('_', ' ')),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(domain.explanation),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Flags ${domain.flagCount} • Warnings ${domain.warningCount} • Precautions ${domain.precautionCount} • Confidence ${domain.confidence}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Question-level explanations'),
              children: evaluation.questions
                  .where(
                    (question) => question.severity != MyChildSeverity.normal,
                  )
                  .map(
                    (question) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        question.question.malayalam ?? question.question.prompt,
                      ),
                      subtitle: Text(
                        '${question.severity.name}: ${question.detail.appliedRule}\n${question.detail.recommendedAction}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'This parent-report result supports, but does not replace, the acoustic screening.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
