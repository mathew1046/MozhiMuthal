import '../data/models/biomarker_result.dart';
import '../core/constants.dart';
import 'my_child_engine.dart';

/// Structured PFV output produced by the Android frame-level pitch analyzer.
class PfvScreeningResult {
  final double? rawPfvSemitoneSD;
  final double? ageZScore;
  final bool isFlagged;
  final int framesUsed;
  final bool insufficientData;

  const PfvScreeningResult({
    required this.rawPfvSemitoneSD,
    required this.ageZScore,
    required this.isFlagged,
    required this.framesUsed,
    required this.insufficientData,
  });

  factory PfvScreeningResult.fromJson(Map<String, dynamic> json) =>
      PfvScreeningResult(
        rawPfvSemitoneSD: (json['raw_pfv_semitone_sd'] as num?)?.toDouble(),
        ageZScore: (json['age_z_score'] as num?)?.toDouble(),
        isFlagged: json['is_flagged'] as bool? ?? false,
        framesUsed: (json['frames_used'] as num?)?.toInt() ?? 0,
        insufficientData: json['insufficient_data'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'raw_pfv_semitone_sd': rawPfvSemitoneSD,
    'age_z_score': ageZScore,
    'is_flagged': isFlagged,
    'frames_used': framesUsed,
    'insufficient_data': insufficientData,
  };
}

/// Input features from the native audio pipeline.
class SessionFeatures {
  final double vttlMs;
  final double pfvStd;
  final double cvrRatio;
  final int childAgeMonths;
  final String audioSourceUsed;
  final String analysisStatus;
  final PfvScreeningResult? pfv;
  final List<String> qualityReasons;
  final int transitionCount;
  final double voicedSeconds;
  final double childVoicedSeconds;
  final List<double> waveform;
  final List<Map<String, dynamic>> decisionTrace;

  const SessionFeatures({
    required this.vttlMs,
    required this.pfvStd,
    required this.cvrRatio,
    required this.childAgeMonths,
    this.audioSourceUsed = 'UNPROCESSED',
    this.analysisStatus = 'COMPLETE',
    this.pfv,
    this.qualityReasons = const [],
    this.transitionCount = 0,
    this.voicedSeconds = 0,
    this.childVoicedSeconds = 0,
    this.waveform = const [],
    this.decisionTrace = const [],
  });

  factory SessionFeatures.fromJson(Map<String, dynamic> json) =>
      SessionFeatures(
        vttlMs: (json['vttl_ms'] as num?)?.toDouble() ?? 0,
        pfvStd: (json['pfv_std'] as num?)?.toDouble() ?? 0,
        pfv: json['pfv'] is Map
            ? PfvScreeningResult.fromJson(
                Map<String, dynamic>.from(json['pfv'] as Map),
              )
            : null,
        cvrRatio: (json['cvr_ratio'] as num?)?.toDouble() ?? 0,
        childAgeMonths: json['child_age_months'] as int,
        audioSourceUsed: json['audio_source_used'] as String? ?? 'UNPROCESSED',
        analysisStatus: json['analysis_status'] as String? ?? 'COMPLETE',
        qualityReasons: (json['quality_reasons'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        transitionCount: (json['transition_count'] as num?)?.toInt() ?? 0,
        voicedSeconds: (json['voiced_seconds'] as num?)?.toDouble() ?? 0,
        childVoicedSeconds:
            (json['child_voiced_seconds'] as num?)?.toDouble() ?? 0,
        waveform: (json['waveform'] as List? ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
        decisionTrace: (json['decision_trace'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
}

class ScoringEngine {
  ScoringEngine._();

  static BiomarkerResult score(SessionFeatures f) {
    // Quality failures are not clinical findings. Callers should direct the
    // worker to retry instead of presenting zero/partial features as a score.
    if (f.analysisStatus != 'COMPLETE') {
      return BiomarkerResult.incomplete(f.qualityReasons);
    }

    final bool vttlFlagged = f.vttlMs > AppConstants.vttlThresholdMs;

    final pfv = f.pfv;
    final bool pfvFlagged =
        pfv != null && !pfv.insufficientData && pfv.isFlagged;

    final String ageBucket = AppConstants.getAgeBucket(f.childAgeMonths);
    final double cvrThreshold = AppConstants.cvrThresholds[ageBucket]!;
    final bool cvrFlagged = f.cvrRatio < cvrThreshold;

    final int flagCount = [
      vttlFlagged,
      pfvFlagged,
      cvrFlagged,
    ].where((f) => f).length;

    final RiskLevel level = flagCount >= 2
        ? RiskLevel.red
        : flagCount == 1
        ? RiskLevel.yellow
        : RiskLevel.green;

    return BiomarkerResult(
      riskLevel: level,
      vttlFlagged: vttlFlagged,
      pfvFlagged: pfvFlagged,
      pfvRawSemitoneSD: pfv?.rawPfvSemitoneSD,
      pfvAgeZScore: pfv?.ageZScore,
      pfvFramesUsed: pfv?.framesUsed ?? 0,
      pfvInsufficientData: pfv?.insufficientData ?? true,
      cvrFlagged: cvrFlagged,
      malayalamExplanation: _getExplanation(level),
    );
  }

  /// Escalate (but never downgrade) the acoustic screening outcome with the
  /// parent's developmental questionnaire. The combined result is the one
  /// saved and used to decide whether a referral is offered.
  static BiomarkerResult combineWithQuestionnaire(
    BiomarkerResult acousticResult,
    MyChildState? questionnaireState,
  ) {
    if (questionnaireState == null) return acousticResult;

    final combined = CombinedScreeningResult.combine(
      questionnaire: questionnaireState,
      acousticTier: acousticResult.riskLabel,
      audioQualityPassed: !acousticResult.incomplete,
    );
    final riskLevel = switch (combined.tier) {
      'RED' => RiskLevel.red,
      'YELLOW' => RiskLevel.yellow,
      _ => RiskLevel.green,
    };

    if (riskLevel == acousticResult.riskLevel) return acousticResult;
    return acousticResult.copyWith(
      riskLevel: riskLevel,
      malayalamExplanation: _getExplanation(riskLevel),
    );
  }

  /// Builds a result from the completed parent questionnaire when a worker
  /// deliberately uses the temporary acoustic-test skip. No acoustic signal
  /// is inferred, displayed, or marked as passed.
  static BiomarkerResult questionnaireOnly(MyChildState? questionnaireState) {
    if (questionnaireState == null) {
      return const BiomarkerResult.incomplete([
        'The parent questionnaire has not been completed.',
      ]);
    }
    const questionnaireBaseline = BiomarkerResult(
      riskLevel: RiskLevel.green,
      vttlFlagged: false,
      pfvFlagged: false,
      cvrFlagged: false,
      malayalamExplanation: '',
    );
    return combineWithQuestionnaire(
      questionnaireBaseline,
      questionnaireState,
    ).copyWith(
      malayalamExplanation:
          'ശബ്ദ പരിശോധന ഒഴിവാക്കി. ഈ ഫലം മാതാപിതാക്കളുടെ ചോദ്യാവലിയിൽ മാത്രം അടിസ്ഥാനപ്പെടുത്തിയതാണ്; ഇത് രോഗനിർണയം അല്ല.',
    );
  }

  static String _getExplanation(RiskLevel level) {
    switch (level) {
      case RiskLevel.red:
        return 'ഈ കുട്ടിക്ക് ഉടൻ DEIC സന്ദർശനം ശുപാർശ ചെയ്യുന്നു. '
            'കൂടുതൽ വിവരങ്ങൾക്ക് ഇന്ന് ഒരു referral letter ലഭ്യമാണ്.';
      case RiskLevel.yellow:
        return 'ഒരു biomarker ആശങ്കാജനകമാണ്. '
            '3 മാസത്തിനുള്ളിൽ വീണ്ടും screening ശുപാർശ ചെയ്യുന്നു.';
      case RiskLevel.green:
        return 'ഈ കുട്ടിയുടെ ഭാഷാ വികാസം പ്രായത്തിന് അനുസൃതമാണ്.';
    }
  }
}
