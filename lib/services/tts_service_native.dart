import 'package:flutter/services.dart';

/// Speaks consent on-device through Android's text-to-speech engine.
class TtsService {
  static const _channel = MethodChannel('com.mozhimuthal/tts');
  Future<void> playConsent() => _channel.invokeMethod('speakConsent');
  void dispose() {}
}
