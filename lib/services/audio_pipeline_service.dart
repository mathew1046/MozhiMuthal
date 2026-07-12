import 'dart:math';
import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Wraps the Kotlin native audio pipeline via method channel.
/// In demo/mock mode, returns synthetic biomarker data.
class AudioPipelineService {
  static const _channel = MethodChannel(AppConstants.audioPipelineChannel);
  static bool useMock = true; // Toggle for development

  /// Start recording audio via the native pipeline.
  static Future<void> startRecording() async {
    if (useMock) return;
    await _channel.invokeMethod('startRecording');
  }

  /// Stop recording.
  static Future<void> stopRecording() async {
    if (useMock) return;
    await _channel.invokeMethod('stopRecording');
  }

  /// Run the full analysis pipeline and return biomarker features.
  static Future<Map<String, dynamic>> runPipeline({
    required int childAgeMonths,
  }) async {
    if (useMock) return _mockPipeline(childAgeMonths);

    final result = await _channel.invokeMethod('runPipeline', {
      'child_age_months': childAgeMonths,
    });
    return Map<String, dynamic>.from(result);
  }

  /// Returns synthetic data for UI development.
  static Map<String, dynamic> _mockPipeline(int childAgeMonths) {
    final rng = Random();
    // Bias towards RED for demo impact
    final vttl = 800.0 + rng.nextDouble() * 600; // 800–1400ms
    final pfv = 10.0 + rng.nextDouble() * 15; // 10–25
    final cvr = 0.04 + rng.nextDouble() * 0.14; // 0.04–0.18

    return {
      'vttl_ms': vttl,
      'pfv_std': pfv,
      'cvr_ratio': cvr,
      'child_age_months': childAgeMonths,
      'audio_source_used': 'MOCK',
    };
  }
}
