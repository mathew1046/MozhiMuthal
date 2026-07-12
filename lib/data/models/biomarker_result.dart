import 'dart:ui';

enum RiskLevel { green, yellow, red }

class BiomarkerResult {
  final RiskLevel riskLevel;
  final bool vttlFlagged;
  final bool pfvFlagged;
  final bool cvrFlagged;
  final String malayalamExplanation;

  const BiomarkerResult({
    required this.riskLevel,
    required this.vttlFlagged,
    required this.pfvFlagged,
    required this.cvrFlagged,
    required this.malayalamExplanation,
  });

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
      };
}
