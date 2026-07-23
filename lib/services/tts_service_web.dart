// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

/// Browser-native consent playback.
///
/// Browser voice lists are often populated asynchronously. Waiting for them
/// and explicitly assigning a voice avoids Chrome silently dropping an
/// utterance when a Malayalam voice has not finished loading. If Malayalam is
/// unavailable, an installed voice reads an English equivalent so the consent
/// step remains audible instead of failing silently.
class TtsService {
  static const _malayalamConsent =
      'നിങ്ങളുടെ കുട്ടിയുടെ ശബ്ദത്തിലെ ഭാഷാ വികാസ സൂചനകൾ പരിശോധിക്കുന്നതിനാണ് ഈ സ്ക്രീനിംഗ്. ഇത് രോഗനിർണയം അല്ല. ശബ്ദ റെക്കോർഡിംഗ് ഈ ഫോണിൽ മാത്രം വിശകലനം ചെയ്യും; ഓഡിയോ സംഭരിക്കുകയോ പങ്കിടുകയോ ചെയ്യില്ല. നിങ്ങൾക്ക് സമ്മതമാണോ?';

  static const _englishFallback =
      'This screening checks language-development signals in your child’s voice. It is not a diagnosis. The recording is analysed only on this device and will not be stored or shared. Do you consent?';

  Future<void> playConsent() async {
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      throw StateError('Browser speech synthesis is unavailable');
    }

    final voices = await _loadVoices(synth);
    final malayalamVoice = _firstVoiceMatching(voices, 'ml');
    final voice =
        malayalamVoice ??
        _firstVoiceMatching(voices, 'en') ??
        (voices.isEmpty ? null : voices.first);
    final hasMalayalamVoice = malayalamVoice != null;
    final utterance =
        html.SpeechSynthesisUtterance(
            hasMalayalamVoice ? _malayalamConsent : _englishFallback,
          )
          ..lang = hasMalayalamVoice ? 'ml-IN' : (voice?.lang ?? 'en-IN')
          ..rate = 0.9;
    if (voice != null) utterance.voice = voice;

    final completer = Completer<void>();
    utterance.onEnd.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    utterance.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Browser speech synthesis failed'));
      }
    });

    synth
      ..cancel()
      ..speak(utterance);
    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        synth.cancel();
        throw TimeoutException('Browser speech synthesis timed out');
      },
    );
  }

  Future<List<html.SpeechSynthesisVoice>> _loadVoices(
    html.SpeechSynthesis synth,
  ) async {
    final initialVoices = synth.getVoices();
    if (initialVoices.isNotEmpty) return initialVoices;

    final voicesChanged = Completer<void>();
    void onVoicesChanged(html.Event _) {
      if (!voicesChanged.isCompleted) voicesChanged.complete();
    }

    synth.addEventListener('voiceschanged', onVoicesChanged);
    await Future.any([
      voicesChanged.future,
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);
    synth.removeEventListener('voiceschanged', onVoicesChanged);
    return synth.getVoices();
  }

  html.SpeechSynthesisVoice? _firstVoiceMatching(
    List<html.SpeechSynthesisVoice> voices,
    String languagePrefix,
  ) {
    for (final voice in voices) {
      if ((voice.lang ?? '').toLowerCase().startsWith(languagePrefix)) {
        return voice;
      }
    }
    return null;
  }

  void dispose() => html.window.speechSynthesis?.cancel();
}
