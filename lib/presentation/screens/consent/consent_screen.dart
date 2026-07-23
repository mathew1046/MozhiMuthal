import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/tts_service.dart';
import '../../widgets/app_ui.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _audioPlayed = false;
  bool _isPlaying = false;
  String? _error;
  final _tts = TtsService();

  Future<void> _playAudio() async {
    setState(() {
      _isPlaying = true;
      _error = null;
    });
    try {
      await _tts.playConsent();
      if (mounted) setState(() => _audioPlayed = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Consent audio is unavailable. Install a Malayalam text-to-speech voice and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Parent consent')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppStepIndicator(
                current: 4,
                total: 4,
                label: 'Step 4 of 4 • Parent consent',
              ),
              const Spacer(),
              AppSurface(
                color: scheme.secondaryContainer.withOpacity(.38),
                borderColor: scheme.secondaryContainer,
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    AppIconBadge(
                      icon: _isPlaying
                          ? Icons.volume_up_rounded
                          : Icons.record_voice_over_outlined,
                      color: scheme.secondary,
                      size: 72,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Explain it in Malayalam',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Play the short consent statement, then confirm that the parent has agreed to the screening.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    if (_isPlaying) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        'Playing consent audio…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: _playAudio,
                        icon: Icon(
                          _audioPlayed
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _audioPlayed ? 'Play again' : 'Play consent audio',
                        ),
                      ),
                    if (_audioPlayed) ...[
                      const SizedBox(height: 18),
                      AppPill(
                        label: 'AUDIO COMPLETE',
                        color: scheme.primary,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                AppSurface(
                  color: scheme.errorContainer,
                  borderColor: scheme.error,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: scheme.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'The recording is analysed on this device. This screening is not a diagnosis.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _audioPlayed
                    ? () => context.push('/elicitation')
                    : null,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Parent has consented'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
