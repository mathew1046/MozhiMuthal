import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      await AudioPipelineService.requestPermission();
      await AudioPipelineService.startSession();
      if (!mounted) return;
      setState(() { _recording = true; _elapsed = 0; _error = null; });
      _tick();
    } on AudioPipelineException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Microphone unavailable');
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

  void _nextProtocol() {
    if (_currentProtocol < 2) {
      setState(() { _currentProtocol++; _elapsed = 0; });
      _tick();
    } else {
      AudioPipelineService.stopSession();
      context.push('/processing');
    }
  }

  bool get _canProceed => _elapsed >= AppConstants.minProtocolDuration;

  @override
  Widget build(BuildContext context) {
    final protocol = _protocols[_currentProtocol];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Protocol ${_currentProtocol + 1} of 3'),
      ),
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
              child: ProtocolCard(
                protocol: protocol,
                elapsed: _elapsed,
                isRecording: _recording,
              ),
            ),

            const SizedBox(height: 24),
            if (_error != null)
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(
                'Recording unavailable: $_error\nCheck microphone permission and try again.',
                style: TextStyle(color: theme.colorScheme.error),
              ))),

            // Next button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canProceed ? _nextProtocol : null,
                icon: Icon(
                    _currentProtocol < 2 ? Icons.arrow_forward : Icons.analytics),
                label: Text(
                    _currentProtocol < 2 ? 'Next Protocol' : 'Finish & Analyze'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
