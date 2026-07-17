import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../services/audio_pipeline_service.dart';
import 'protocol_card.dart';

class ElicitationScreen extends StatefulWidget {
  const ElicitationScreen({super.key});

  @override
  State<ElicitationScreen> createState() => _ElicitationScreenState();
}

class _ElicitationScreenState extends State<ElicitationScreen> {
  int _currentProtocol = 0; // 0, 1, 2
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
      instruction: 'Shake the rattle near the child',
      icon: Icons.toys,
      durationSec: AppConstants.rattleDuration,
    ),
    ProtocolInfo(
      title: 'Toy Hide / Reveal',
      instruction: 'Hide and reveal a toy',
      icon: Icons.visibility,
      durationSec: AppConstants.toyHideDuration,
    ),
    ProtocolInfo(
      title: 'Imitation "aaa"',
      instruction: 'Say "aaa" and wait for the child to imitate',
      icon: Icons.record_voice_over,
      durationSec: AppConstants.imitationDuration,
    ),
  ];

  @override
  void initState() {
    super.initState();
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
    } on AudioPipelineException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PlatformException catch (e) {
      if (mounted)
        setState(() => _error = e.message ?? 'Microphone unavailable');
    }
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
    } on PlatformException catch (e) {
      if (mounted)
        setState(() => _error = e.message ?? 'Could not replay recording');
    } finally {
      if (mounted) setState(() => _isReplaying = false);
    }
  }

  void _analyze() {
    // The temporary recording is only for review; the numerical features are
    // already held by the native pipeline.
    AudioPipelineService.deleteTemporaryRecording();
    context.push('/processing');
  }

  @override
  void dispose() {
    _waveformSubscription?.cancel();
    AudioPipelineService.deleteTemporaryRecording();
    super.dispose();
  }

  bool get _canProceed => _elapsed >= AppConstants.minProtocolDuration;

  @override
  Widget build(BuildContext context) {
    final protocol = _protocols[_currentProtocol];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Protocol ${_currentProtocol + 1} of 3')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentProtocol ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i <= _currentProtocol
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Protocol card
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ProtocolCard(
                      protocol: protocol,
                      elapsed: _elapsed,
                      isRecording: _recording,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LiveWaveform(samples: _waveform, active: _recording),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Recording unavailable: $_error\nCheck microphone permission and try again.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),

            // Next button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _reviewReady
                    ? _analyze
                    : (_canProceed ? _nextProtocol : null),
                icon: Icon(
                  _reviewReady || _currentProtocol == 2
                      ? Icons.analytics
                      : Icons.arrow_forward,
                ),
                label: Text(
                  _reviewReady
                      ? 'Analyze Recording'
                      : (_currentProtocol < 2
                            ? 'Next Protocol'
                            : 'Finish Recording'),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_reviewReady && _hasReplayCopy)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: _isReplaying ? null : _replay,
                  icon: _isReplaying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.replay),
                  label: Text(
                    _isReplaying ? 'Replaying…' : 'Replay once (then delete)',
                  ),
                ),
              ),
            if (!_canProceed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Wait ${AppConstants.minProtocolDuration - _elapsed}s before proceeding',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
          ],
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
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: active ? 'Live microphone waveform' : 'Recording waveform paused',
      child: Container(
        height: 58,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(42, (index) {
            final level = index < samples.length ? samples[index] : 0.04;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: 4 + (level * 40),
                decoration: BoxDecoration(
                  color: color.withOpacity(active ? .85 : .3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
