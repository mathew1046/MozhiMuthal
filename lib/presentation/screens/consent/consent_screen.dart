import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/tts_service.dart';

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
    setState(() => _isPlaying = true);
    try {
      await _tts.playConsent();
      if (mounted) setState(() => _audioPlayed = true);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Consent audio is unavailable. Install a Malayalam text-to-speech voice and try again.',
        );
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Consent')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Audio player area
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _isPlaying ? Icons.volume_up : Icons.play_circle_outline,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isPlaying
                        ? 'Playing consent audio...'
                        : _audioPlayed
                        ? 'Audio complete'
                        : 'Play consent audio',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isPlaying)
                    const LinearProgressIndicator()
                  else
                    OutlinedButton.icon(
                      onPressed: _playAudio,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_audioPlayed ? 'Replay' : 'Play'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (_error != null) const SizedBox(height: 12),
            Text(
              'Read the consent statement aloud to the parent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _audioPlayed
                  ? () => context.push('/elicitation')
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Parent Has Consented'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
