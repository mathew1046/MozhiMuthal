import '../data/models/biomarker_result.dart';
import '../core/constants.dart';

/// Input features from the native audio pipeline.
class SessionFeatures {
  final double vttlMs;
  final double pfvStd;
  final double cvrRatio;
  final int childAgeMonths;
  final String audioSourceUsed;
  final String analysisStatus;
  final List<String> qualityReasons;
  final int transitionCount;
  final double voicedSeconds;
  final double childVoicedSeconds;

  const SessionFeatures({
    required this.vttlMs,
    required this.pfvStd,
    required this.cvrRatio,
    required this.childAgeMonths,
    this.audioSourceUsed = 'UNPROCESSED',
    this.analysisStatus = 'COMPLETE',
    this.qualityReasons = const [],
    this.transitionCount = 0,
    this.voicedSeconds = 0,
    this.childVoicedSeconds = 0,
  });

  factory SessionFeatures.fromJson(Map<String, dynamic> json) =>
      SessionFeatures(
        vttlMs: (json['vttl_ms'] as num).toDouble(),
        pfvStd: (json['pfv_std'] as num).toDouble(),
        cvrRatio: (json['cvr_ratio'] as num).toDouble(),
        childAgeMonths: json['child_age_months'] as int,
        audioSourceUsed:
            json['audio_source_used'] as String? ?? 'UNPROCESSED',
        analysisStatus: json['analysis_status'] as String? ?? 'COMPLETE',
        qualityReasons: (json['quality_reasons'] as List? ?? const [])
            .map((e) => e.toString()).toList(),
        transitionCount: (json['transition_count'] as num?)?.toInt() ?? 0,
        voicedSeconds: (json['voiced_seconds'] as num?)?.toDouble() ?? 0,
        childVoicedSeconds:
            (json['child_voiced_seconds'] as num?)?.toDouble() ?? 0,
      );
}

class ScoringEngine {
  ScoringEngine._();

  static BiomarkerResult score(SessionFeatures f) {
    if (f.analysisStatus != 'COMPLETE' || f.qualityReasons.isNotEmpty ||
        f.audioSourceUsed == 'DEMO') {
      return BiomarkerResult.incomplete(f.qualityReasons.isEmpty
          ? const ['Audio quality did not meet the minimum requirements']
          : f.qualityReasons);
    }
    final bool vttlFlagged = f.vttlMs > AppConstants.vttlThresholdMs;

    bool pfvFlagged = false;
    if (f.childAgeMonths >= AppConstants.pfvMinAgeMonths) {
      pfvFlagged = f.pfvStd < AppConstants.pfvFlatThreshold;
    }

    final String ageBucket = AppConstants.getAgeBucket(f.childAgeMonths);
    final double cvrThreshold = AppConstants.cvrThresholds[ageBucket]!;
    final bool cvrFlagged = f.cvrRatio < cvrThreshold;

    final int flagCount =
        [vttlFlagged, pfvFlagged, cvrFlagged].where((f) => f).length;

    final RiskLevel level = flagCount >= 2
        ? RiskLevel.red
        : flagCount == 1
            ? RiskLevel.yellow
            : RiskLevel.green;

    return BiomarkerResult(
      riskLevel: level,
      vttlFlagged: vttlFlagged,
      pfvFlagged: pfvFlagged,
      cvrFlagged: cvrFlagged,
      malayalamExplanation: _getExplanation(level),
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
