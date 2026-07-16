import '../core/constants.dart';

enum MyChildState { normal, precaution, warning, flag, regression }

class MonitoringQuestion {
  final String id, prompt, domain;
  final int minAge, maxAge;
  final String? malayalamDraft;
  const MonitoringQuestion({required this.id, required this.prompt, required this.domain,
    required this.minAge, required this.maxAge, this.malayalamDraft});
}

/// MyChild Engine v0.4.0 / CDC-aligned monitoring prompts, adapted under the
/// attributed CC BY-SA source terms recorded in the project plan. The Malayalam text
/// is draft-only and is never used to compute a live result.
class MyChildEngine {
  static const engineVersion = AppConstants.myChildEngineVersion;
  static const questions = <MonitoringQuestion>[
    MonitoringQuestion(id: 'language_1', domain: 'language', minAge: 12, maxAge: 18,
      prompt: 'Does the child use a few meaningful sounds or words?', malayalamDraft: 'കുട്ടി അർത്ഥമുള്ള ശബ്ദങ്ങളോ വാക്കുകളോ ഉപയോഗിക്കുന്നുണ്ടോ?'),
    MonitoringQuestion(id: 'language_2', domain: 'language', minAge: 18, maxAge: 24,
      prompt: 'Does the child point to ask for something or name familiar things?', malayalamDraft: 'ആവശ്യപ്പെടാൻ കുട്ടി ചൂണ്ടിക്കാണിക്കുകയോ പരിചിത വസ്തുക്കൾ പറയുകയോ ചെയ്യുന്നുണ്ടോ?'),
    MonitoringQuestion(id: 'language_3', domain: 'language', minAge: 24, maxAge: 36,
      prompt: 'Does the child combine two or more words?', malayalamDraft: 'കുട്ടി രണ്ടോ അതിലധികമോ വാക്കുകൾ ചേർത്ത് പറയുന്നുണ്ടോ?'),
  ];

  static List<MonitoringQuestion> forAge(int months) =>
      months < 12 || months > 36 ? const [] : questions.where((q) => months >= q.minAge && months <= q.maxAge).toList();

  static int correctedAgeMonths({required DateTime birthDate, required DateTime dueDate, DateTime? today}) {
    final now = today ?? DateTime.now();
    final chronological = (now.difference(birthDate).inDays / 30.4375).floor();
    final prematurity = (dueDate.difference(birthDate).inDays / 30.4375).round();
    return (chronological - prematurity).clamp(0, chronological);
  }

  static MyChildState evaluate(Map<String, bool> answers, {MyChildState? previous}) {
    final failed = answers.values.where((v) => !v).length;
    if (previous != null && previous != MyChildState.normal && failed == 0) return MyChildState.regression;
    if (failed >= 2) return MyChildState.warning;
    if (failed == 1) return MyChildState.precaution;
    return MyChildState.normal;
  }

  static String tier(MyChildState state) => switch (state) {
    MyChildState.normal => 'GREEN',
    MyChildState.precaution => 'YELLOW',
    MyChildState.warning || MyChildState.flag || MyChildState.regression => 'RED',
  };

  static bool isDraftMalayalam(String locale) => locale == 'ml-IN';
}

class CombinedScreeningResult {
  final String tier;
  final bool audioIncomplete;
  final MyChildState questionnaireState;
  const CombinedScreeningResult(this.tier, this.audioIncomplete, this.questionnaireState);

  factory CombinedScreeningResult.combine({required MyChildState questionnaire,
      required String acousticTier, required bool audioQualityPassed}) {
    if (!audioQualityPassed) return CombinedScreeningResult('INCOMPLETE', true, questionnaire);
    const order = {'GREEN': 0, 'YELLOW': 1, 'RED': 2};
    final q = MyChildEngine.tier(questionnaire);
    return CombinedScreeningResult((order[q]! >= order[acousticTier]! ? q : acousticTier), false, questionnaire);
  }
}
