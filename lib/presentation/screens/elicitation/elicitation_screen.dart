import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../widgets/app_ui.dart';
import 'protocol_card.dart';

class ElicitationScreen extends StatefulWidget {
  const ElicitationScreen({super.key});

  @override
  State<ElicitationScreen> createState() => _ElicitationScreenState();
}

class _ElicitationScreenState extends State<ElicitationScreen> {
  int _currentProtocol = 0;
  int _elapsed = 0;
  bool _recording = false;

  static const _protocols = [
    ProtocolInfo(
      title: 'Rattle',
      instruction:
          'Shake the rattle nearby and give the child time to respond naturally.',
      icon: Icons.toys_rounded,
      durationSec: AppConstants.rattleDuration,
      tint: ProtocolTint.lilac,
    ),
    ProtocolInfo(
      title: 'Hide and reveal',
      instruction:
          'Hide a familiar toy, reveal it, and wait for the child’s reaction.',
      icon: Icons.visibility_rounded,
      durationSec: AppConstants.toyHideDuration,
      tint: ProtocolTint.blue,
    ),
    ProtocolInfo(
      title: 'Imitate “aaa”',
      instruction:
          'Make the sound “aaa”, then give the child room to imitate it.',
      icon: Icons.record_voice_over_rounded,
      durationSec: AppConstants.imitationDuration,
      tint: ProtocolTint.pink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      _elapsed = 0;
    });
    _tick();
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
    if (_currentProtocol < _protocols.length - 1) {
      setState(() {
        _currentProtocol++;
        _elapsed = 0;
        _recording = true;
      });
      _tick();
      return;
    }
    context.push('/processing');
  }

  bool get _canProceed => _elapsed >= AppConstants.minProtocolDuration;

  @override
  Widget build(BuildContext context) {
    final protocol = _protocols[_currentProtocol];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final remaining = (AppConstants.minProtocolDuration - _elapsed).clamp(
      0,
      AppConstants.minProtocolDuration,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Guided play session')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STEP ${_currentProtocol + 1} OF 3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'At least ${AppConstants.minProtocolDuration}s',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StepProgress(current: _currentProtocol, total: _protocols.length),
              const SizedBox(height: 22),
              Expanded(
                child: ProtocolCard(
                  protocol: protocol,
                  elapsed: _elapsed,
                  isRecording: _recording,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _canProceed ? _nextProtocol : null,
                icon: Icon(
                  _currentProtocol == _protocols.length - 1
                      ? Icons.auto_graph_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  _currentProtocol == _protocols.length - 1
                      ? 'Finish and analyse'
                      : 'Next activity',
                ),
              ),
              SizedBox(
                height: 30,
                child: Center(
                  child: _canProceed
                      ? Text(
                          'You can continue when the child is ready.',
                          style: theme.textTheme.bodySmall,
                        )
                      : Text(
                          'Please wait $remaining more second${remaining == 1 ? '' : 's'}.',
                          style: theme.textTheme.bodySmall,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
