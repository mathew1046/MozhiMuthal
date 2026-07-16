import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/domain/my_child_engine.dart';

void main() {
  test('questionnaire is limited to the operational age range', () {
    expect(MyChildEngine.forAge(11), isEmpty);
    expect(MyChildEngine.forAge(12), isNotEmpty);
    expect(MyChildEngine.forAge(36), isNotEmpty);
    expect(MyChildEngine.forAge(37), isEmpty);
  });

  test('regression and highest concern are preserved', () {
    expect(MyChildEngine.evaluate({'a': true}, previous: MyChildState.precaution), MyChildState.regression);
    final combined = CombinedScreeningResult.combine(
      questionnaire: MyChildState.precaution,
      acousticTier: 'GREEN',
      audioQualityPassed: true,
    );
    expect(combined.tier, 'YELLOW');
    expect(CombinedScreeningResult.combine(
      questionnaire: MyChildState.normal,
      acousticTier: 'RED',
      audioQualityPassed: false,
    ).tier, 'INCOMPLETE');
  });
}
