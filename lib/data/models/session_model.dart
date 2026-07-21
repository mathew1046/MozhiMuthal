import 'dart:convert';

import 'biomarker_result.dart';

class SessionModel {
  final String id;
  final String anganwadiId;
  final String workerName;
  final String? childName;
  final int childAgeMonths;
  final DateTime? childBirthDate;
  final int? gestationalWeeks;
  final DateTime sessionDate;
  final RiskLevel riskLevel;
  final double vttlMs;
  final double pfvStd;
  final double cvrRatio;
  final bool vttlFlagged;
  final bool pfvFlagged;
  final bool cvrFlagged;
  final double? pfvRawSemitoneSD;
  final double? pfvAgeZScore;
  final int pfvFramesUsed;
  final bool pfvInsufficientData;
  final String pfvUnit;
  final String audioSourceUsed;
  final bool syncedToCloud;
  final String districtCode;
  final String? childUuid;
  final String analysisStatus;
  final List<String> qualityReasons;
  final int transitionCount;
  final double voicedSeconds;
  final double childVoicedSeconds;
  final bool demoSession;
  final int retryCount;
  final String? questionnaireRunId;
  final String? consentId;
  final String? questionnaireState;
  final Map<String, String> questionnaireAnswers;
  final Map<String, dynamic> questionnaireAnalysis;
  final List<Map<String, dynamic>> decisionTrace;
  final List<double> waveform;

  const SessionModel({
    required this.id,
    required this.anganwadiId,
    required this.workerName,
    this.childName,
    required this.childAgeMonths,
    this.childBirthDate,
    this.gestationalWeeks,
    required this.sessionDate,
    required this.riskLevel,
    required this.vttlMs,
    required this.pfvStd,
    required this.cvrRatio,
    required this.vttlFlagged,
    required this.pfvFlagged,
    required this.cvrFlagged,
    this.pfvRawSemitoneSD,
    this.pfvAgeZScore,
    this.pfvFramesUsed = 0,
    this.pfvInsufficientData = true,
    this.pfvUnit = 'hz_legacy',
    required this.audioSourceUsed,
    this.syncedToCloud = false,
    required this.districtCode,
    this.childUuid,
    this.analysisStatus = 'COMPLETE',
    this.qualityReasons = const [],
    this.transitionCount = 0,
    this.voicedSeconds = 0,
    this.childVoicedSeconds = 0,
    this.demoSession = false,
    this.retryCount = 0,
    this.questionnaireRunId,
    this.consentId,
    this.questionnaireState,
    this.questionnaireAnswers = const {},
    this.questionnaireAnalysis = const {},
    this.decisionTrace = const [],
    this.waveform = const [],
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
    double? pfvRawSemitoneSD,
    double? pfvAgeZScore,
    int? pfvFramesUsed,
    bool? pfvInsufficientData,
    String? pfvUnit,
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
      childBirthDate: childBirthDate,
      gestationalWeeks: gestationalWeeks,
      sessionDate: sessionDate ?? this.sessionDate,
      riskLevel: riskLevel ?? this.riskLevel,
      vttlMs: vttlMs ?? this.vttlMs,
      pfvStd: pfvStd ?? this.pfvStd,
      cvrRatio: cvrRatio ?? this.cvrRatio,
      vttlFlagged: vttlFlagged ?? this.vttlFlagged,
      pfvFlagged: pfvFlagged ?? this.pfvFlagged,
      cvrFlagged: cvrFlagged ?? this.cvrFlagged,
      pfvRawSemitoneSD: pfvRawSemitoneSD ?? this.pfvRawSemitoneSD,
      pfvAgeZScore: pfvAgeZScore ?? this.pfvAgeZScore,
      pfvFramesUsed: pfvFramesUsed ?? this.pfvFramesUsed,
      pfvInsufficientData: pfvInsufficientData ?? this.pfvInsufficientData,
      pfvUnit: pfvUnit ?? this.pfvUnit,
      audioSourceUsed: audioSourceUsed ?? this.audioSourceUsed,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
      districtCode: districtCode ?? this.districtCode,
      childUuid: childUuid,
      analysisStatus: analysisStatus,
      qualityReasons: qualityReasons,
      transitionCount: transitionCount,
      voicedSeconds: voicedSeconds,
      childVoicedSeconds: childVoicedSeconds,
      demoSession: demoSession,
      retryCount: retryCount,
      questionnaireRunId: questionnaireRunId,
      consentId: consentId,
      questionnaireState: questionnaireState,
      questionnaireAnswers: questionnaireAnswers,
      questionnaireAnalysis: questionnaireAnalysis,
      decisionTrace: decisionTrace,
      waveform: waveform,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'anganwadi_id': anganwadiId,
    'worker_name': workerName,
    'child_name': childName,
    'child_age_months': childAgeMonths,
    'child_birth_date': childBirthDate?.toIso8601String(),
    'gestational_weeks': gestationalWeeks,
    'session_date': sessionDate.toIso8601String(),
    'risk_level': riskLevel.name,
    'vttl_ms': vttlMs,
    'pfv_std': pfvStd,
    'cvr_ratio': cvrRatio,
    'vttl_flagged': vttlFlagged ? 1 : 0,
    'pfv_flagged': pfvFlagged ? 1 : 0,
    'pfv_raw_semitone_sd': pfvRawSemitoneSD,
    'pfv_age_z_score': pfvAgeZScore,
    'pfv_frames_used': pfvFramesUsed,
    'pfv_insufficient_data': pfvInsufficientData ? 1 : 0,
    'pfv_unit': pfvUnit,
    'cvr_flagged': cvrFlagged ? 1 : 0,
    'audio_source': audioSourceUsed,
    'synced': syncedToCloud ? 1 : 0,
    'district_code': districtCode,
    'child_uuid': childUuid,
    'analysis_status': analysisStatus,
    'quality_reasons': qualityReasons.join('|'),
    'transition_count': transitionCount,
    'voiced_seconds': voicedSeconds,
    'child_voiced_seconds': childVoicedSeconds,
    'demo_session': demoSession ? 1 : 0,
    'retry_count': retryCount,
    'questionnaire_run_id': questionnaireRunId,
    'consent_id': consentId,
    'questionnaire_state': questionnaireState,
    'questionnaire_answers': jsonEncode(questionnaireAnswers),
    'questionnaire_analysis': jsonEncode(questionnaireAnalysis),
    'decision_trace': jsonEncode(decisionTrace),
    'waveform': jsonEncode(waveform),
  };

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
    id: map['id'] as String,
    anganwadiId: map['anganwadi_id'] as String,
    workerName: map['worker_name'] as String? ?? '',
    childName: map['child_name'] as String?,
    childAgeMonths: map['child_age_months'] as int,
    childBirthDate: (map['child_birth_date'] as String?) == null
        ? null
        : DateTime.parse(map['child_birth_date'] as String),
    gestationalWeeks: (map['gestational_weeks'] as num?)?.toInt(),
    sessionDate: DateTime.parse(map['session_date'] as String),
    riskLevel: RiskLevel.values.firstWhere(
      (e) => e.name == map['risk_level'],
      orElse: () => RiskLevel.green,
    ),
    vttlMs: (map['vttl_ms'] as num).toDouble(),
    pfvStd: (map['pfv_std'] as num?)?.toDouble() ?? 0,
    cvrRatio: (map['cvr_ratio'] as num).toDouble(),
    vttlFlagged: map['vttl_flagged'] == 1,
    pfvFlagged: map['pfv_flagged'] == 1,
    cvrFlagged: map['cvr_flagged'] == 1,
    pfvRawSemitoneSD: (map['pfv_raw_semitone_sd'] as num?)?.toDouble(),
    pfvAgeZScore: (map['pfv_age_z_score'] as num?)?.toDouble(),
    pfvFramesUsed: (map['pfv_frames_used'] as num?)?.toInt() ?? 0,
    pfvInsufficientData: map['pfv_insufficient_data'] == null
        ? true
        : map['pfv_insufficient_data'] == 1,
    pfvUnit: map['pfv_unit'] as String? ?? 'hz_legacy',
    audioSourceUsed: map['audio_source'] as String? ?? 'UNPROCESSED',
    syncedToCloud: map['synced'] == 1,
    districtCode: map['district_code'] as String? ?? '',
    childUuid: map['child_uuid'] as String?,
    analysisStatus: map['analysis_status'] as String? ?? 'COMPLETE',
    qualityReasons: (map['quality_reasons'] as String? ?? '')
        .split('|')
        .where((e) => e.isNotEmpty)
        .toList(),
    transitionCount: (map['transition_count'] as num?)?.toInt() ?? 0,
    voicedSeconds: (map['voiced_seconds'] as num?)?.toDouble() ?? 0,
    childVoicedSeconds: (map['child_voiced_seconds'] as num?)?.toDouble() ?? 0,
    demoSession: map['demo_session'] == 1,
    retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
    questionnaireRunId: map['questionnaire_run_id'] as String?,
    consentId: map['consent_id'] as String?,
    questionnaireState: map['questionnaire_state'] as String?,
    questionnaireAnswers: _decodeStringMap(
      map['questionnaire_answers'] as String? ?? '',
    ),
    questionnaireAnalysis: _decodeMap(
      map['questionnaire_analysis'] as String? ?? '{}',
    ),
    decisionTrace: _decodeMapList(map['decision_trace'] as String? ?? '[]'),
    waveform: _decodeDoubleList(map['waveform'] as String? ?? '[]'),
  );

  Map<String, dynamic> toSupabaseJson() => {
    'id': id,
    'session_id': id,
    'child_id': childUuid,
    'questionnaire_run_id': questionnaireRunId,
    'consent_id': consentId,
    'pseudonym': childName ?? childUuid ?? 'local-child',
    'anganwadi_id': anganwadiId,
    'district_code': districtCode,
    'child_age_months': childAgeMonths,
    'child_birth_date': childBirthDate?.toIso8601String(),
    'gestational_weeks': gestationalWeeks,
    'risk_level': riskLevel.name,
    'vttl_ms': vttlMs,
    'pfv_std': pfvStd,
    'cvr_ratio': cvrRatio,
    'vttl_flagged': vttlFlagged,
    'pfv_flagged': pfvFlagged,
    'pfv_raw_semitone_sd': pfvRawSemitoneSD,
    'pfv_age_z_score': pfvAgeZScore,
    'pfv_frames_used': pfvFramesUsed,
    'pfv_insufficient_data': pfvInsufficientData,
    'pfv_unit': pfvUnit,
    'pfv_analysis': {
      'raw_pfv_semitone_sd': pfvRawSemitoneSD,
      'age_z_score': pfvAgeZScore,
      'frames_used': pfvFramesUsed,
      'insufficient_data': pfvInsufficientData,
      'is_flagged': pfvFlagged,
      'unit': pfvUnit,
    },
    'cvr_flagged': cvrFlagged,
    'audio_source': audioSourceUsed,
    'session_date': sessionDate.toIso8601String(),
    'analysis_status': analysisStatus,
    'quality_reasons': qualityReasons,
    'transition_count': transitionCount,
    'voiced_seconds': voicedSeconds,
    'child_voiced_seconds': childVoicedSeconds,
    'demo_session': demoSession,
    'engine_version': questionnaireAnalysis['engine_version'],
    'questionnaire_state': questionnaireState,
    'answers': questionnaireAnswers,
    'questionnaire_analysis': questionnaireAnalysis,
    'decision_trace': decisionTrace,
    'waveform': waveform,
  };
}

Map<String, String> _decodeStringMap(String value) {
  if (value.trim().isEmpty) return const {};
  if (value.trim().startsWith('{')) {
    final decoded = jsonDecode(value) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }
  return value.split('|').where((e) => e.contains(':')).fold(
    <String, String>{},
    (out, item) {
      final index = item.indexOf(':');
      out[item.substring(0, index)] = item.substring(index + 1) == 'true'
          ? 'achieved'
          : 'notYet';
      return out;
    },
  );
}

Map<String, dynamic> _decodeMap(String value) {
  if (value.trim().isEmpty) return const {};
  final decoded = jsonDecode(value) as Map<String, dynamic>;
  return decoded;
}

List<Map<String, dynamic>> _decodeMapList(String value) {
  if (value.trim().isEmpty) return const [];
  final decoded = jsonDecode(value) as List<dynamic>;
  return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

List<double> _decodeDoubleList(String value) {
  if (value.trim().isEmpty) return const [];
  final decoded = jsonDecode(value) as List<dynamic>;
  return decoded.map((v) => (v as num).toDouble()).toList();
}
