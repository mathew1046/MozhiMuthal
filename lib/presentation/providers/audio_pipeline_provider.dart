import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RecordingState { idle, recording, processing, complete }

class AudioPipelineState {
  final RecordingState recordingState;
  final int currentProtocol; // 1, 2, or 3
  final int elapsedSeconds;

  const AudioPipelineState({
    this.recordingState = RecordingState.idle,
    this.currentProtocol = 1,
    this.elapsedSeconds = 0,
  });

  AudioPipelineState copyWith({
    RecordingState? recordingState,
    int? currentProtocol,
    int? elapsedSeconds,
  }) {
    return AudioPipelineState(
      recordingState: recordingState ?? this.recordingState,
      currentProtocol: currentProtocol ?? this.currentProtocol,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

class AudioPipelineNotifier extends StateNotifier<AudioPipelineState> {
  AudioPipelineNotifier() : super(const AudioPipelineState());

  void startRecording() {
    state = state.copyWith(
      recordingState: RecordingState.recording,
      elapsedSeconds: 0,
    );
  }

  void updateElapsed(int seconds) {
    state = state.copyWith(elapsedSeconds: seconds);
  }

  void nextProtocol() {
    if (state.currentProtocol < 3) {
      state = state.copyWith(
        currentProtocol: state.currentProtocol + 1,
        elapsedSeconds: 0,
      );
    }
  }

  void startProcessing() {
    state = state.copyWith(recordingState: RecordingState.processing);
  }

  void complete() {
    state = state.copyWith(recordingState: RecordingState.complete);
  }

  void reset() {
    state = const AudioPipelineState();
  }
}

final audioPipelineProvider =
    StateNotifierProvider<AudioPipelineNotifier, AudioPipelineState>((ref) {
  return AudioPipelineNotifier();
});
