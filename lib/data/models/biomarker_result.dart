import 'dart:ui';

enum RiskLevel { green, yellow, red }

class BiomarkerResult {
  final RiskLevel riskLevel;
  final bool vttlFlagged;
  final bool pfvFlagged;
  final bool cvrFlagged;
  final String malayalamExplanation;
  final bool incomplete;
  final List<String> qualityReasons;

  const BiomarkerResult({
    required this.riskLevel,
    required this.vttlFlagged,
    required this.pfvFlagged,
    required this.cvrFlagged,
    required this.malayalamExplanation,
    this.incomplete = false,
    this.qualityReasons = const [],
  });

  const BiomarkerResult.incomplete(this.qualityReasons)
      : riskLevel = RiskLevel.yellow,
        vttlFlagged = false,
        pfvFlagged = false,
        cvrFlagged = false,
        incomplete = true,
        malayalamExplanation = 'Incomplete—repeat recording. ഇത് രോഗനിർണ്ണയം അല്ല.';

  int get flagCount =>
      [vttlFlagged, pfvFlagged, cvrFlagged].where((f) => f).length;

  Color get riskColor {
    switch (riskLevel) {
      case RiskLevel.red:
        return const Color(0xFFC62828);
      case RiskLevel.yellow:
        return const Color(0xFFF9A825);
      case RiskLevel.green:
        return const Color(0xFF2E7D32);
    }
  }

  String get riskLabel {
    if (incomplete) return 'INCOMPLETE';
    switch (riskLevel) {
      case RiskLevel.red:
        return 'RED';
      case RiskLevel.yellow:
        return 'YELLOW';
      case RiskLevel.green:
        return 'GREEN';
    }
  }

  Map<String, dynamic> toJson() => {
        'risk_level': riskLevel.name,
        'vttl_flagged': vttlFlagged,
        'pfv_flagged': pfvFlagged,
        'cvr_flagged': cvrFlagged,
        'malayalam_explanation': malayalamExplanation,
        'incomplete': incomplete,
        'quality_reasons': qualityReasons,
      };
}
