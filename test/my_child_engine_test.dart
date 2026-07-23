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

  test(
    'M-CHAT-R includes all Malayalam items and reverse-scores items 2, 5, and 12',
    () {
      final questions = MyChildEngine.forAge(24);
      final mchat = questions.where((q) => q.isMchatQuestion).toList();
      expect(mchat, hasLength(20));
      expect(mchat.every((q) => q.malayalam != null), isTrue);

      final answers = {
        for (final q in questions)
          q.id: q.isMchatQuestion
              ? (q.mchatConcernWhenYes
                    ? MyChildAnswer.notYet
                    : MyChildAnswer.achieved)
              : MyChildAnswer.achieved,
        'mchat_01': MyChildAnswer.notYet,
        'mchat_03': MyChildAnswer.notYet,
        'mchat_04': MyChildAnswer.notYet,
      };
      final result = MyChildEngine.evaluateDetailed(
        ageMonths: 24,
        answers: answers,
      );

      expect(result.domains['MCHAT']?.warningCount, 3);
      expect(result.domains['MCHAT']?.status, 'low_concern');
    },
  );
}
