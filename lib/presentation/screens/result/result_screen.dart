import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/biomarker_result.dart';
import '../../../domain/my_child_engine.dart';
import '../../providers/session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biomarker_chip.dart';
import 'biomarker_detail_sheet.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final result = session.result;
    final theme = Theme.of(context);

    if (result == null) {
      return const Scaffold(body: Center(child: Text('No result available')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Risk card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: result.riskColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: result.riskColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    result.riskLabel,
                    style: TextStyle(
                      fontSize: 32,
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
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (session.audioSource == 'WEB_TEST_FIXTURE')
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Browser test data — not a live microphone/model result.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            const Text(
              'Screening signal only — not a diagnosis. Discuss concerns with a clinician/DEIC.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 28),

            if (session.questionnaireState != null) ...[
              _QuestionnaireSummary(
                state: session.questionnaireState!,
                evaluation: session.questionnaireEvaluation,
              ),
              const SizedBox(height: 16),
            ],

            // Biomarker chips
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            BiomarkerChipWidget(
              label: 'PFV',
              value: result.pfvInsufficientData
                  ? 'Insufficient data'
                  : '${session.pfvStd.toStringAsFixed(2)} st SD',
              flagged: result.pfvFlagged,
              onTap: () => showBiomarkerDetail(
                context,
                kind: BiomarkerKind.pfv,
                ageMonths: session.childProfile!.childAgeMonths,
                value: session.pfvStd,
                flagged: result.pfvFlagged,
                waveform: session.waveform,
                trace: session.decisionTrace,
                pfvInsufficientData: result.pfvInsufficientData,
                pfvAgeZScore: result.pfvAgeZScore,
                pfvFramesUsed: result.pfvFramesUsed,
              ),
            ),

            const SizedBox(height: 28),

            // Save & referral
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
                label: const Text('Generate Referral'),
                style: FilledButton.styleFrom(
                  backgroundColor: result.riskColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save & Return'),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Dashboard'),
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
    final e = evaluation;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Development questionnaire: ${MyChildEngine.tier(state)} — ${state.name}.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (e != null) ...[
            const SizedBox(height: 6),
            Text(e.message),
            Text(
              'Scored age: ${e.effectiveAgeMonths.toStringAsFixed(1)} months${e.correctedAgeUsed ? ' corrected' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...e.domains.values.map(
              (d) => ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(d.domain),
                subtitle: Text(d.status.replaceAll('_', ' ')),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(d.explanation),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Flags ${d.flagCount} · Warnings ${d.warningCount} · Precautions ${d.precautionCount} · Confidence ${d.confidence}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Question-level explanations'),
              children: e.questions
                  .where((q) => q.severity != MyChildSeverity.normal)
                  .map(
                    (q) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(q.question.malayalam ?? q.question.prompt),
                      subtitle: Text(
                        '${q.severity.name}: ${q.detail.appliedRule}\n${q.detail.recommendedAction}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'This parent-report result supports, but does not replace, the acoustic screening.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
