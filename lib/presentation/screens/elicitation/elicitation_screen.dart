import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../services/audio_pipeline_service.dart';
import '../../widgets/app_ui.dart';
import 'protocol_card.dart';

class ElicitationScreen extends StatefulWidget {
  const ElicitationScreen({super.key});

  @override
  State<ElicitationScreen> createState() => _ElicitationScreenState();
}

class _ElicitationScreenState extends State<ElicitationScreen>
    with WidgetsBindingObserver {
  int _currentProtocol = 0;
  int _elapsed = 0;
  bool _recording = false;
  String? _error;
  final List<double> _waveform = [];
  StreamSubscription<double>? _waveformSubscription;
  bool _reviewReady = false;
  bool _hasReplayCopy = false;
  bool _isReplaying = false;

  static const _protocols = [
    ProtocolInfo(
      title: 'Rattle',
      instruction:
          'Shake the rattle near the child. Give them time to respond naturally.',
      icon: Icons.toys_outlined,
      durationSec: AppConstants.rattleDuration,
    ),
    ProtocolInfo(
      title: 'Toy hide & reveal',
      instruction:
          'Hide and reveal a toy. Pause between turns and wait for the child.',
      icon: Icons.visibility_outlined,
      durationSec: AppConstants.toyHideDuration,
    ),
    ProtocolInfo(
      title: 'Imitate “aaa”',
      instruction: 'Say “aaa”, pause, and let the child try to imitate you.',
      icon: Icons.record_voice_over_outlined,
      durationSec: AppConstants.imitationDuration,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveformSubscription = AudioPipelineService.waveform.listen((level) {
      if (!mounted) return;
      setState(() {
        _waveform.add(level);
        if (_waveform.length > 42) _waveform.removeAt(0);
      });
    });
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      await AudioPipelineService.requestPermission();
      await AudioPipelineService.startSession();
      if (!mounted) return;
      setState(() {
        _recording = true;
        _elapsed = 0;
        _error = null;
      });
      _tick();
    } on AudioPipelineException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? 'Microphone unavailable');
      }
    }
  }

  Future<void> _restartRecording() async {
    // A native recording cannot be safely resumed after the microphone was
    // interrupted. Start the guided sequence again so every retained sample
    // belongs to the same complete session.
    await AudioPipelineService.stopSession();
    if (!mounted) return;
    setState(() {
      _currentProtocol = 0;
      _elapsed = 0;
      _recording = false;
      _reviewReady = false;
      _hasReplayCopy = false;
      _error = null;
      _waveform.clear();
    });
    await _startRecording();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_recording) return;
      setState(() => _elapsed++);
      if (_elapsed < _protocols[_currentProtocol].durationSec) {
        _tick();
      } else {
        setState(() => _recording = false);
      }
    });
  }

  Future<void> _nextProtocol() async {
    if (_currentProtocol < 2) {
      setState(() {
        _currentProtocol++;
        _elapsed = 0;
        _recording = true;
      });
      _tick();
    } else {
      await AudioPipelineService.stopSession();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _reviewReady = true;
        _hasReplayCopy = AudioPipelineService.supportsReplay;
      });
    }
  }

  Future<void> _replay() async {
    setState(() => _isReplaying = true);
    try {
      await AudioPipelineService.replayTemporaryRecording();
      if (mounted) setState(() => _hasReplayCopy = false);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? 'Could not replay recording');
      }
    } finally {
      if (mounted) setState(() => _isReplaying = false);
    }
  }

  void _analyze() {
    AudioPipelineService.deleteTemporaryRecording();
    context.push('/processing');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_recording ||
        (state != AppLifecycleState.inactive &&
            state != AppLifecycleState.paused &&
            state != AppLifecycleState.detached)) {
      return;
    }

    // Android stops the recorder when the activity is interrupted. Do not let
    // the visible timer continue and imply that the capture is still usable.
    setState(() {
      _recording = false;
      _error = 'Recording was interrupted. Please restart the activities.';
    });
    unawaited(AudioPipelineService.stopSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveformSubscription?.cancel();
    // Route disposal does not destroy MainActivity, so explicitly release the
    // microphone instead of relying on Android activity teardown.
    unawaited(AudioPipelineService.stopSession());
    AudioPipelineService.deleteTemporaryRecording();
    super.dispose();
  }

  bool get _canProceed => _elapsed >= AppConstants.minProtocolDuration;

  @override
  Widget build(BuildContext context) {
    final protocol = _protocols[_currentProtocol];
    final scheme = Theme.of(context).colorScheme;
    final waitSeconds = AppConstants.minProtocolDuration - _elapsed;

    return Scaffold(
      appBar: AppBar(title: Text('Activity ${_currentProtocol + 1} of 3')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              AppStepIndicator(
                current: _currentProtocol + 1,
                total: 3,
                label: 'Guided voice activity',
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ProtocolCard(
                  protocol: protocol,
                  elapsed: _elapsed,
                  isRecording: _recording,
                ),
              ),
              const SizedBox(height: 14),
              _LiveWaveform(samples: _waveform, active: _recording),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AppSurface(
                  color: scheme.errorContainer,
                  borderColor: scheme.error,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.mic_off_outlined, color: scheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recording unavailable: $_error',
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_reviewReady) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _recording ? null : _restartRecording,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Restart activities'),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 14),
              if (!_reviewReady && !_canProceed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Keep going for $waitSeconds more seconds before continuing.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _reviewReady
                      ? _analyze
                      : (_canProceed ? _nextProtocol : null),
                  icon: Icon(
                    _reviewReady || _currentProtocol == 2
                        ? Icons.auto_graph_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    _reviewReady
                        ? 'Analyse recording'
                        : _currentProtocol < 2
                        ? 'Next activity'
                        : 'Finish recording',
                  ),
                ),
              ),
              if (_reviewReady && _hasReplayCopy) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isReplaying ? null : _replay,
                  icon: _isReplaying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.replay_rounded),
                  label: Text(
                    _isReplaying ? 'Replaying…' : 'Replay once, then delete',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveWaveform extends StatelessWidget {
  const _LiveWaveform({required this.samples, required this.active});
  final List<double> samples;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: active ? 'Live microphone waveform' : 'Recording waveform paused',
      child: AppSurface(
        color: scheme.surfaceContainerHighest.withOpacity(.7),
        borderColor: scheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(42, (index) {
              final level = index < samples.length ? samples[index] : .04;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 4 + (level * 32),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(active ? .85 : .28),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
