import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/domain/scoring_engine.dart';
import 'package:mozhimuthal/data/models/biomarker_result.dart';
import 'package:mozhimuthal/domain/my_child_engine.dart';

void main() {
  test('partial audio features do not produce a clinical screening result', () {
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
    expect(result.riskLabel, 'YELLOW');
    expect(result.riskLevel, RiskLevel.yellow);
    expect(result.qualityReasons, ['too quiet']);
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

  test('questionnaire concerns escalate the final screening result', () {
    const acoustic = BiomarkerResult(
      riskLevel: RiskLevel.green,
      vttlFlagged: false,
      pfvFlagged: false,
      cvrFlagged: false,
      malayalamExplanation: 'Acoustic result',
    );

    final combined = ScoringEngine.combineWithQuestionnaire(
      acoustic,
      MyChildState.warning,
    );

    expect(combined.riskLevel, RiskLevel.red);
    expect(combined.riskLabel, 'RED');
  });

  test('questionnaire cannot downgrade a higher acoustic concern', () {
    const acoustic = BiomarkerResult(
      riskLevel: RiskLevel.red,
      vttlFlagged: true,
      pfvFlagged: true,
      cvrFlagged: false,
      malayalamExplanation: 'Acoustic result',
    );

    final combined = ScoringEngine.combineWithQuestionnaire(
      acoustic,
      MyChildState.normal,
    );

    expect(combined.riskLevel, RiskLevel.red);
  });

  test('temporary voice-test skip produces a questionnaire-only result', () {
    final result = ScoringEngine.questionnaireOnly(MyChildState.warning);

    expect(result.riskLevel, RiskLevel.red);
    expect(result.vttlFlagged, isFalse);
    expect(result.pfvFlagged, isFalse);
    expect(result.cvrFlagged, isFalse);
    expect(result.incomplete, isFalse);
  });

  test('voice-test skip requires a completed questionnaire', () {
    final result = ScoringEngine.questionnaireOnly(null);

    expect(result.incomplete, isTrue);
  });
}
