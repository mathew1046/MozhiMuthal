import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_ui.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _audioPlayed = false;
  bool _isPlaying = false;

  void _playAudio() {
    setState(() => _isPlaying = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _audioPlayed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Parent consent')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageIntro(
                eyebrow: 'Step 2 of 4',
                title: 'Share the consent message.',
                subtitle:
                    'Play it in Malayalam, then confirm the parent agrees to the screening.',
              ),
              const Spacer(),
              SoftCard(
                color: colors.secondaryContainer.withValues(alpha: 0.62),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.volume_up_rounded
                            : Icons.play_arrow_rounded,
                        size: 42,
                        color: colors.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isPlaying
                          ? 'Playing consent audio'
                          : _audioPlayed
                          ? 'Consent audio complete'
                          : 'Consent audio in Malayalam',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPlaying
                          ? 'Please allow the message to finish.'
                          : 'Make sure the parent has time to listen and ask questions.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    if (_isPlaying)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: const LinearProgressIndicator(minHeight: 7),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _playAudio,
                        icon: Icon(
                          _audioPlayed
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _audioPlayed ? 'Play again' : 'Play message',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The screening stores numeric voice patterns, not the recorded audio.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _audioPlayed
                    ? () => context.push('/elicitation')
                    : null,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Parent has consented'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
