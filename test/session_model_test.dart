import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/data/models/biomarker_result.dart';
import 'package:mozhimuthal/data/models/session_model.dart';

void main() {
  test('corrupt optional JSON fields do not block local session loading', () {
    final session = SessionModel(
      id: 'session-1',
      anganwadiId: '',
      workerName: 'Worker',
      childAgeMonths: 24,
      sessionDate: DateTime(2026),
      riskLevel: RiskLevel.green,
      vttlMs: 800,
      pfvStd: 1.2,
      cvrRatio: .2,
      vttlFlagged: false,
      pfvFlagged: false,
      cvrFlagged: false,
      audioSourceUsed: 'UNPROCESSED',
      districtCode: 'TVM',
    );
    final row = Map<String, dynamic>.from(session.toMap())
      ..['questionnaire_answers'] = '{invalid'
      ..['questionnaire_analysis'] = '{invalid'
      ..['decision_trace'] = '{invalid'
      ..['waveform'] = '{invalid';

    final restored = SessionModel.fromMap(row);

    expect(restored.questionnaireAnswers, isEmpty);
    expect(restored.questionnaireAnalysis, isEmpty);
    expect(restored.decisionTrace, isEmpty);
    expect(restored.waveform, isEmpty);
  });
}
