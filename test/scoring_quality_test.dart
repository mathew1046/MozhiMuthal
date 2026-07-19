import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/domain/scoring_engine.dart';
import 'package:mozhimuthal/data/models/biomarker_result.dart';

void main() {
  test('quality failure cannot resolve to green', () {
    final result = ScoringEngine.score(
      SessionFeatures(
        vttlMs: 0,
        pfvStd: 0,
        cvrRatio: 0,
        childAgeMonths: 24,
        analysisStatus: 'INCOMPLETE',
        qualityReasons: const ['too quiet'],
      ),
    );
    expect(result.incomplete, isTrue);
    expect(result.riskLabel, 'INCOMPLETE');
    expect(result.riskLevel, isNot(RiskLevel.green));
  });
}
