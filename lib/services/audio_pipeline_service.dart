import 'package:flutter/foundation.dart';
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
  static const _waveformChannel = EventChannel(
    '${AppConstants.audioPipelineChannel}/waveform',
  );
  static AudioPipelineMode mode = AudioPipelineMode.live;

  static bool get isDemo => mode == AudioPipelineMode.demo;
  static bool get supportsReplay => !isDemo && !kIsWeb;

  static Future<void> requestPermission() async {
    if (isDemo || kIsWeb) return;
    await _channel.invokeMethod('requestPermission');
  }

  static Future<void> startSession() => startRecording();
  static Future<void> stopSession() => stopRecording();

  /// Start recording audio via the native pipeline.
  static Future<void> startRecording() async {
    if (isDemo || kIsWeb) return;
    await _channel.invokeMethod('startRecording');
  }

  /// Stop recording.
  static Future<void> stopRecording() async {
    if (isDemo || kIsWeb) return;
    await _channel.invokeMethod('stopRecording');
  }

  /// Peak levels sampled every 100 ms while recording. This is visual-only;
  /// no audio data crosses into Dart or leaves the device.
  static Stream<double> get waveform => _waveformChannel
      .receiveBroadcastStream()
      .map((event) => (event as num).toDouble().clamp(0.0, 1.0));

  /// Plays the local review copy once. Android deletes it immediately after
  /// playback completes, so it can never be synced or retained.
  static Future<void> replayTemporaryRecording() async {
    if (kIsWeb) return;
    await _channel.invokeMethod('replayTemporaryRecording');
  }

  static Future<void> deleteTemporaryRecording() async {
    if (kIsWeb) return;
    await _channel.invokeMethod('deleteTemporaryRecording');
  }

  /// Run the full analysis pipeline and return biomarker features.
  static Future<Map<String, dynamic>> runPipeline({
    required int childAgeMonths,
  }) async {
    if (kIsWeb) {
      // The Android ONNX Runtime pipeline cannot execute in a browser. This
      // fixture keeps the complete Flutter flow testable on a laptop without
      // representing browser microphone data as a clinical result.
      return {
        'analysis_status': 'COMPLETE',
        'child_age_months': childAgeMonths,
        'audio_source_used': 'WEB_TEST_FIXTURE',
        'quality_reasons': <String>[],
        'vttl_ms': 820.0,
        'pfv_std': 1.65,
        'pfv': {
          'raw_pfv_semitone_sd': 1.65,
          'age_z_score': 0.0,
          'is_flagged': false,
          'frames_used': 60,
          'insufficient_data': false,
        },
        'cvr_ratio': 0.14,
        'transition_count': 6,
        'voiced_seconds': 42.0,
        'child_voiced_seconds': 8.4,
        'waveform': List<double>.generate(120, (i) => 0.12 + ((i % 9) / 14)),
        'decision_trace': [
          {
            'start_ms': 0,
            'end_ms': 10000,
            'vttl_ms': 760.0,
            'pfv_frames': 20,
            'cvr_ratio': 0.12,
          },
          {
            'start_ms': 10000,
            'end_ms': 20000,
            'vttl_ms': 820.0,
            'pfv_frames': 20,
            'cvr_ratio': 0.14,
          },
          {
            'start_ms': 20000,
            'end_ms': 30000,
            'vttl_ms': 880.0,
            'pfv_frames': 20,
            'cvr_ratio': 0.16,
          },
        ],
      };
    }
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
      throw AudioPipelineException(
        e.code,
        e.message ?? 'Audio analysis failed',
      );
    }
  }
}
