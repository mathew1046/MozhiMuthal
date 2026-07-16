import 'package:flutter/services.dart';
import '../core/constants.dart';

enum AudioPipelineMode { live, demo }

class AudioPipelineException implements Exception {
  final String code;
  final String message;
  const AudioPipelineException(this.code, this.message);
  @override
  String toString() => '$code: $message';
}

/// Wraps the Kotlin native pipeline. Demo is deliberately explicit and its
/// payload is marked so it cannot be persisted as an operational screening.
class AudioPipelineService {
  static const _channel = MethodChannel(AppConstants.audioPipelineChannel);
  static AudioPipelineMode mode = AudioPipelineMode.live;

  static bool get isDemo => mode == AudioPipelineMode.demo;

  static Future<void> requestPermission() async {
    if (isDemo) return;
    await _channel.invokeMethod('requestPermission');
  }

  static Future<void> startSession() => startRecording();
  static Future<void> stopSession() => stopRecording();

  /// Start recording audio via the native pipeline.
  static Future<void> startRecording() async {
    if (isDemo) return;
    await _channel.invokeMethod('startRecording');
  }

  /// Stop recording.
  static Future<void> stopRecording() async {
    if (isDemo) return;
    await _channel.invokeMethod('stopRecording');
  }

  /// Run the full analysis pipeline and return biomarker features.
  static Future<Map<String, dynamic>> runPipeline({
    required int childAgeMonths,
  }) async {
    if (isDemo) {
      return {
        'analysis_status': 'DEMO',
        'demo_session': true,
        'quality_reasons': ['Demo data; repeat with a live recording'],
        'child_age_months': childAgeMonths,
        'audio_source_used': 'DEMO',
      };
    }

    try {
      final result = await _channel.invokeMethod('runPipeline', {
        'child_age_months': childAgeMonths,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      throw AudioPipelineException(e.code, e.message ?? 'Audio analysis failed');
    }
  }
}
