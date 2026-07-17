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
  final Map<String, bool> _answers = {};

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider).childProfile;
    if (profile == null)
      return const Scaffold(
        body: Center(child: Text('Child details are required first.')),
      );
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
              'Ask the parent each age-appropriate question. This supports screening and is not a diagnosis.',
              style: TextStyle(fontSize: 13),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.malayalamDraft ?? q.prompt,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  q.prompt,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                      value: true,
                                      label: Text('Yes'),
                                    ),
                                    ButtonSegment(
                                      value: false,
                                      label: Text('No'),
                                    ),
                                  ],
                                  selected: _answers.containsKey(q.id)
                                      ? {_answers[q.id]!}
                                      : const {},
                                  onSelectionChanged: (value) => setState(
                                    () => _answers[q.id] = value.first,
                                  ),
                                ),
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
                      final state = MyChildEngine.evaluate(_answers);
                      ref
                          .read(sessionProvider.notifier)
                          .setQuestionnaire(_answers, state);
                      context.push('/consent');
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to consent'),
            ),
          ],
        ),
      ),
    );
  }
}
