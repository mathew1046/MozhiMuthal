import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/my_child_engine.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_ui.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  final Map<String, MyChildAnswer> _answers = {};
  final ScrollController _questionScrollController = ScrollController();
  int _currentQuestionIndex = 0;

  void _showQuestion(int index) {
    setState(() => _currentQuestionIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _questionScrollController.hasClients) {
        _questionScrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _questionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider).childProfile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final questions = MyChildEngine.forAge(profile.childAgeMonths);
    final total = questions.length;
    final answered = _answers.length;
    final remaining = total - answered;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Development questions')),
        body: const Center(child: Text('No questions are available yet.')),
      );
    }

    final currentIndex = _currentQuestionIndex.clamp(0, questions.length - 1);
    final question = questions[currentIndex];
    final currentAnswer = _answers[question.id];
    final currentAnswered = currentAnswer != null;
    final isLastQuestion = currentIndex == questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Parent questionnaire')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppStepIndicator(
                current: 3,
                total: 4,
                label: 'Step 1 of 4 · Development check',
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$remaining ${remaining == 1 ? 'answer' : 'answers'} remaining',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  AppPill(
                    label: currentAnswered ? 'ANSWERED' : 'IN PROGRESS',
                    color: currentAnswered
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: answered / total,
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Question ${currentIndex + 1} of $total',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AppSurface(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Scrollbar(
                      controller: _questionScrollController,
                      child: SingleChildScrollView(
                        controller: _questionScrollController,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppPill(
                              label: MyChildEngine.questionGroupFor(
                                question,
                              ).toUpperCase(),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              question.prompt,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (question.subtext != null &&
                                question.subtext!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                question.subtext!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Divider(),
                            ),
                            Text(
                              'Malayalam',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.malayalam ??
                                  'Malayalam translation unavailable.',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (question.malayalamSubtext != null &&
                                question.malayalamSubtext!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                question.malayalamSubtext!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (question.tags.isNotEmpty)
                                  ...question.tags.map(
                                    (tag) => Chip(label: Text(tag)),
                                  ),
                                Chip(label: Text('Weight ${question.weight}')),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SegmentedButton<MyChildAnswer>(
                              emptySelectionAllowed: true,
                              showSelectedIcon: false,
                              segments: question.isMchatQuestion
                                  ? const [
                                      ButtonSegment(
                                        value: MyChildAnswer.achieved,
                                        label: Text('Yes'),
                                      ),
                                      ButtonSegment(
                                        value: MyChildAnswer.notYet,
                                        label: Text('No'),
                                      ),
                                    ]
                                  : const [
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
                              selected: currentAnswer == null
                                  ? const <MyChildAnswer>{}
                                  : <MyChildAnswer>{currentAnswer},
                              onSelectionChanged: (selection) {
                                setState(
                                  () => _answers[question.id] = selection.first,
                                );
                              },
                            ),
                            if (currentAnswer == MyChildAnswer.unsure &&
                                question.probes.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: .36),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  MyChildEngine.probesMalayalam(
                                    question,
                                  ).join('\n'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: currentIndex == 0
                          ? null
                          : () => _showQuestion(currentIndex - 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: !currentAnswered
                          ? null
                          : () {
                              if (!isLastQuestion) {
                                _showQuestion(currentIndex + 1);
                                return;
                              }

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
                            },
                      icon: Icon(
                        isLastQuestion
                            ? Icons.arrow_forward_rounded
                            : Icons.navigate_next_rounded,
                      ),
                      label: Text(isLastQuestion ? 'Continue' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
