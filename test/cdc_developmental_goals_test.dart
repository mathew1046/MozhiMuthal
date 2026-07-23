import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/domain/cdc_developmental_goals.dart';

void main() {
  test('uses the latest CDC checkpoint at or below the child age', () {
    expect(CdcDevelopmentalGoals.forAge(12).ageMonths, 12);
    expect(CdcDevelopmentalGoals.forAge(14).ageMonths, 12);
    expect(CdcDevelopmentalGoals.forAge(23).ageMonths, 18);
    expect(CdcDevelopmentalGoals.forAge(24).ageMonths, 24);
    expect(CdcDevelopmentalGoals.forAge(36).ageMonths, 36);
  });

  test('every CDC age group contains goals across all domains', () {
    for (final group in CdcDevelopmentalGoals.ageGroups) {
      expect(group.categories.keys, hasLength(4));
      expect(group.goalCount, greaterThan(0));
    }
  });
}
