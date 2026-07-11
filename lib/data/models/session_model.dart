enum RiskLevel { green, yellow, red }

class SessionModel {
  final String id;
  final String anganwadiId;
  final String workerName;
  final String? childName;
  final int childAgeMonths;
  final DateTime sessionDate;
  final RiskLevel riskLevel;
  final double vttlMs;
  final double pfvStd;
  final double cvrRatio;
  final bool vttlFlagged;
  final bool pfvFlagged;
  final bool cvrFlagged;
  final String audioSourceUsed;
  final bool syncedToCloud;
  final String districtCode;

  SessionModel({
    required this.id,
    required this.anganwadiId,
    required this.workerName,
    this.childName,
    required this.childAgeMonths,
    required this.sessionDate,
    required this.riskLevel,
    required this.vttlMs,
    required this.pfvStd,
    required this.cvrRatio,
    required this.vttlFlagged,
    required this.pfvFlagged,
    required this.cvrFlagged,
    required this.audioSourceUsed,
    required this.syncedToCloud,
    required this.districtCode,
  });
}
