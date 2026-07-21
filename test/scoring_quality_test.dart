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

  test('a two-sided PFV flag participates in the combined risk score', () {
    final result = ScoringEngine.score(
      const SessionFeatures(
        vttlMs: 500,
        pfvStd: 2.6,
        cvrRatio: .20,
        childAgeMonths: 24,
        pfv: PfvScreeningResult(
          rawPfvSemitoneSD: 2.6,
          ageZScore: 2.0,
          isFlagged: true,
          framesUsed: 60,
          insufficientData: false,
        ),
      ),
    );

    expect(result.pfvFlagged, isTrue);
    expect(result.pfvAgeZScore, 2.0);
    expect(result.riskLevel, RiskLevel.yellow);
  });

  test('insufficient PFV data is preserved without a false PFV flag', () {
    final result = ScoringEngine.score(
      const SessionFeatures(
        vttlMs: 500,
        pfvStd: 0,
        cvrRatio: .20,
        childAgeMonths: 24,
        pfv: PfvScreeningResult(
          rawPfvSemitoneSD: null,
          ageZScore: null,
          isFlagged: false,
          framesUsed: 12,
          insufficientData: true,
        ),
      ),
    );

    expect(result.pfvInsufficientData, isTrue);
    expect(result.pfvFlagged, isFalse);
    expect(result.riskLevel, RiskLevel.green);
  });
}
