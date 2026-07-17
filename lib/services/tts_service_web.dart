import 'dart:async';
import 'dart:html' as html;

/// Browser-native consent playback. Chrome selects an installed Malayalam voice
/// when one is available and otherwise uses its normal language fallback.
class TtsService {
  Future<void> playConsent() {
    final completer = Completer<void>();
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      return Future.error(
        StateError('Browser speech synthesis is unavailable'),
      );
    }
    final utterance =
        html.SpeechSynthesisUtterance(
            'നിങ്ങളുടെ കുട്ടിയുടെ ശബ്ദത്തിലെ ഭാഷാ വികാസ സൂചനകൾ പരിശോധിക്കുന്നതിനാണ് ഈ സ്ക്രീനിംഗ്. ഇത് രോഗനിർണയം അല്ല. ശബ്ദ റെക്കോർഡിംഗ് ഈ ഫോണിൽ മാത്രം വിശകലനം ചെയ്യും; ഓഡിയോ സംഭരിക്കുകയോ പങ്കിടുകയോ ചെയ്യില്ല. നിങ്ങൾക്ക് സമ്മതമാണോ?',
          )
          ..lang = 'ml-IN'
          ..rate = 0.9;
    utterance.onEnd.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    utterance.onError.listen((_) {
      if (!completer.isCompleted)
        completer.completeError(StateError('Browser speech synthesis failed'));
    });
    synth
      ..cancel()
      ..speak(utterance);
    return completer.future;
  }

  void dispose() => html.window.speechSynthesis?.cancel();
}
