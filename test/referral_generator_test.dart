import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/data/models/biomarker_result.dart';
import 'package:mozhimuthal/data/models/session_model.dart';
import 'package:mozhimuthal/domain/referral_generator.dart';

void main() {
  test(
    'referral PDF contains a valid PDF document for a saved screening',
    () async {
      final bytes = await ReferralGenerator.buildReferralPdf(
        SessionModel(
          id: 'referral-test',
          anganwadiId: '',
          workerName: 'Worker',
          childAgeMonths: 24,
          sessionDate: DateTime(2026, 7, 23),
          riskLevel: RiskLevel.red,
          vttlMs: 1200,
          pfvStd: 2.1,
          cvrRatio: .08,
          vttlFlagged: true,
          pfvFlagged: true,
          cvrFlagged: true,
          audioSourceUsed: 'LIVE',
          districtCode: 'TVM',
          questionnaireState: 'warning',
          questionnaireAnalysis: const {
            'tier': 'RED',
            'state': 'warning',
            'message': 'Questionnaire concern',
          },
        ),
      );

      expect(bytes.take(4), orderedEquals(const [37, 80, 68, 70]));
      expect(bytes.length, greaterThan(100));
    },
  );
}
