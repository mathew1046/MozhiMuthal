/// App-wide constants for MozhiMuthal screening.

class AppConstants {
  AppConstants._();

  // ── Age validation ──
  static const int minAgeMonths = 12;
  static const int maxAgeMonths = 60;

  // ── Biomarker thresholds ──
  static const double vttlThresholdMs = 1000;
  static const double pfvFlatThreshold = 15.0; // std dev below = flat
  static const int pfvMinAgeMonths = 36; // PFV only applies ≥ 36 months

  static const Map<String, double> cvrThresholds = {
    '12_24': 0.08,
    '24_36': 0.12,
    '36_plus': 0.15,
  };

  // ── Protocol durations (seconds) ──
  static const int rattleDuration = 60;
  static const int toyHideDuration = 80;
  static const int imitationDuration = 60;
  static const int minProtocolDuration = 45; // "Next" locked until this

  // ── Method channel ──
  static const String audioPipelineChannel = 'com.mozhimuthal/audio_pipeline';

  // ── Age bucket helper ──
  static String getAgeBucket(int months) {
    if (months < 24) return '12_24';
    if (months < 36) return '24_36';
    return '36_plus';
  }
}
