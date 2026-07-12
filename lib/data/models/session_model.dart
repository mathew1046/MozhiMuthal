import 'biomarker_result.dart';

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

  const SessionModel({
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
    this.syncedToCloud = false,
    required this.districtCode,
  });

  SessionModel copyWith({
    String? id,
    String? anganwadiId,
    String? workerName,
    String? childName,
    int? childAgeMonths,
    DateTime? sessionDate,
    RiskLevel? riskLevel,
    double? vttlMs,
    double? pfvStd,
    double? cvrRatio,
    bool? vttlFlagged,
    bool? pfvFlagged,
    bool? cvrFlagged,
    String? audioSourceUsed,
    bool? syncedToCloud,
    String? districtCode,
  }) {
    return SessionModel(
      id: id ?? this.id,
      anganwadiId: anganwadiId ?? this.anganwadiId,
      workerName: workerName ?? this.workerName,
      childName: childName ?? this.childName,
      childAgeMonths: childAgeMonths ?? this.childAgeMonths,
      sessionDate: sessionDate ?? this.sessionDate,
      riskLevel: riskLevel ?? this.riskLevel,
      vttlMs: vttlMs ?? this.vttlMs,
      pfvStd: pfvStd ?? this.pfvStd,
      cvrRatio: cvrRatio ?? this.cvrRatio,
      vttlFlagged: vttlFlagged ?? this.vttlFlagged,
      pfvFlagged: pfvFlagged ?? this.pfvFlagged,
      cvrFlagged: cvrFlagged ?? this.cvrFlagged,
      audioSourceUsed: audioSourceUsed ?? this.audioSourceUsed,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
      districtCode: districtCode ?? this.districtCode,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'anganwadi_id': anganwadiId,
        'worker_name': workerName,
        'child_name': childName,
        'child_age_months': childAgeMonths,
        'session_date': sessionDate.toIso8601String(),
        'risk_level': riskLevel.name,
        'vttl_ms': vttlMs,
        'pfv_std': pfvStd,
        'cvr_ratio': cvrRatio,
        'vttl_flagged': vttlFlagged ? 1 : 0,
        'pfv_flagged': pfvFlagged ? 1 : 0,
        'cvr_flagged': cvrFlagged ? 1 : 0,
        'audio_source': audioSourceUsed,
        'synced': syncedToCloud ? 1 : 0,
        'district_code': districtCode,
      };

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
        id: map['id'] as String,
        anganwadiId: map['anganwadi_id'] as String,
        workerName: map['worker_name'] as String? ?? '',
        childName: map['child_name'] as String?,
        childAgeMonths: map['child_age_months'] as int,
        sessionDate: DateTime.parse(map['session_date'] as String),
        riskLevel: RiskLevel.values.firstWhere(
          (e) => e.name == map['risk_level'],
          orElse: () => RiskLevel.green,
        ),
        vttlMs: (map['vttl_ms'] as num).toDouble(),
        pfvStd: (map['pfv_std'] as num).toDouble(),
        cvrRatio: (map['cvr_ratio'] as num).toDouble(),
        vttlFlagged: map['vttl_flagged'] == 1,
        pfvFlagged: map['pfv_flagged'] == 1,
        cvrFlagged: map['cvr_flagged'] == 1,
        audioSourceUsed: map['audio_source'] as String? ?? 'UNPROCESSED',
        syncedToCloud: map['synced'] == 1,
        districtCode: map['district_code'] as String? ?? '',
      );

  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'anganwadi_id': anganwadiId,
        'district_code': districtCode,
        'child_age_months': childAgeMonths,
        'risk_level': riskLevel.name,
        'vttl_ms': vttlMs,
        'pfv_std': pfvStd,
        'cvr_ratio': cvrRatio,
        'vttl_flagged': vttlFlagged,
        'pfv_flagged': pfvFlagged,
        'cvr_flagged': cvrFlagged,
        'audio_source': audioSourceUsed,
        'session_date': sessionDate.toIso8601String(),
      };
}
