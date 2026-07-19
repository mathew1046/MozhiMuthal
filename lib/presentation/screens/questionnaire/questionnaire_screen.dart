import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/my_child_engine.dart';
import '../../providers/session_provider.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  final Map<String, MyChildAnswer> _answers = {};

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider).childProfile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Child details are required first.')),
      );
    }
    final questions = MyChildEngine.forAge(profile.childAgeMonths);
    final complete = questions.every((q) => _answers.containsKey(q.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Development questionnaire')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ask each age-appropriate MyChild milestone question. Malayalam text is saved with the answer; this is developmental monitoring, not a diagnosis.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '${questions.length} questions for ${profile.childAgeMonths} months · Child ID ${profile.childUuid}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: questions.isEmpty
                  ? const Center(
                      child: Text(
                        'No questionnaire prompts are available for this age.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: questions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.malayalam ?? q.prompt,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (q.malayalamSubtext != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    q.malayalamSubtext!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  '${q.prompt}${q.subtext == null ? '' : '\n${q.subtext}'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final tag in q.tags)
                                      Chip(
                                        label: Text(tag),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    Chip(
                                      label: Text('Weight ${q.weight}'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SegmentedButton<MyChildAnswer>(
                                  emptySelectionAllowed: true,
                                  segments: const [
                                    ButtonSegment(
                                      value: MyChildAnswer.achieved,
                                      label: Text('Achieved'),
                                    ),
                                    ButtonSegment(
                                      value: MyChildAnswer.notYet,
                                      label: Text('Not yet'),
                                    ),
                                    ButtonSegment(
                                      value: MyChildAnswer.unsure,
                                      label: Text('Unsure'),
                                    ),
                                  ],
                                  selected: _answers.containsKey(q.id)
                                      ? {_answers[q.id]!}
                                      : const {},
                                  onSelectionChanged: (value) => setState(
                                    () => _answers[q.id] = value.first,
                                  ),
                                ),
                                if (_answers[q.id] == MyChildAnswer.unsure) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    MyChildEngine.probesMalayalam(q).join('\n'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            FilledButton.icon(
              onPressed: complete
                  ? () {
                      final evaluation = MyChildEngine.evaluateDetailed(
                        ageMonths: profile.childAgeMonths,
                        birthDate: profile.birthDate,
                        gestationalWeeks: profile.gestationalWeeks,
                        answers: _answers,
                      );
                      ref
                          .read(sessionProvider.notifier)
                          .setQuestionnaire(_answers, evaluation);
                      context.push('/consent');
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                complete
                    ? 'Continue to consent'
                    : 'Answer ${questions.length - _answers.length} more',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
