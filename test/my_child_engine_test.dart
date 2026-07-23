import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/domain/my_child_engine.dart';

void main() {
  test('questionnaire is limited to the operational age range', () {
    expect(MyChildEngine.forAge(11), isEmpty);
    expect(MyChildEngine.forAge(12), isNotEmpty);
    expect(MyChildEngine.forAge(36), isNotEmpty);
    expect(MyChildEngine.forAge(37), isEmpty);
    expect(MyChildEngine.forAge(24).length, greaterThan(10));
  });

  test('regression and highest concern are preserved', () {
    expect(
      MyChildEngine.evaluate({'a': true}, previous: MyChildState.precaution),
      MyChildState.regression,
    );
    final combined = CombinedScreeningResult.combine(
      questionnaire: MyChildState.precaution,
      acousticTier: 'GREEN',
      audioQualityPassed: true,
    );
    expect(combined.tier, 'YELLOW');
    expect(
      CombinedScreeningResult.combine(
        questionnaire: MyChildState.normal,
        acousticTier: 'RED',
        audioQualityPassed: false,
      ).tier,
      'RED',
    );
  });

  test('detailed evaluation includes deterministic explainability', () {
    final questions = MyChildEngine.forAge(24);
    final answers = {
      for (final q in questions) q.id: MyChildAnswer.achieved,
      'q_21_23m_04': MyChildAnswer.notYet,
      'rf_02': MyChildAnswer.notYet,
    };
    final result = MyChildEngine.evaluateDetailed(
      ageMonths: 24,
      birthDate: DateTime.now().subtract(const Duration(days: 730)),
      gestationalWeeks: 40,
      answers: answers,
    );

    expect(result.tier, 'RED');
    expect(result.domains['VH']?.status, isNot('normal'));
    expect(result.questions.first.detail.appliedRule, isNotEmpty);
    expect(result.toJson()['questions'], isNotEmpty);
  });

  test('compact parent check has at most 20 representative prompts', () {
    for (var age = 12; age <= 36; age++) {
      final questions = MyChildEngine.forAge(age);
      expect(questions, isNotEmpty);
      expect(questions.length, lessThanOrEqualTo(20));
      expect(questions.where((q) => q.isMchatQuestion), isEmpty);

      final groupCounts = <String, int>{};
      for (final question in questions) {
        final group = MyChildEngine.questionGroupFor(question);
        groupCounts[group] = (groupCounts[group] ?? 0) + 1;
      }
      for (final entry in groupCounts.entries) {
        expect(
          entry.value,
          lessThanOrEqualTo(entry.key == 'Safety and sensory' ? 5 : 3),
        );
      }
    }
  });
}
