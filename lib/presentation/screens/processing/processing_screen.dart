import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/audio_pipeline_service.dart';
import '../../../domain/scoring_engine.dart';
import '../../providers/session_provider.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _phase = 0;

  static const _phases = [
    'Filtering noise...',
    'Identifying voices...',
    'Extracting patterns...',
    'Scoring...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _runPipeline();
  }

  Future<void> _runPipeline() async {
    final session = ref.read(sessionProvider);
    final ageMonths = session.childProfile?.childAgeMonths ?? 24;

    // Animate through phases
    for (int i = 0; i < _phases.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _phase = i);
    }

    // Run mock pipeline
    final rawResult = await AudioPipelineService.runPipeline(
      childAgeMonths: ageMonths,
    );

    final features = SessionFeatures.fromJson(rawResult);
    final result = ScoringEngine.score(features);

    ref.read(sessionProvider.notifier).setResult(
          result: result,
          vttlMs: features.vttlMs,
          pfvStd: features.pfvStd,
          cvrRatio: features.cvrRatio,
          audioSource: features.audioSourceUsed,
        );

    if (mounted) {
      context.go('/result');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated wave dots
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final offset =
                          (_controller.value * 2 * 3.14159 + i * 0.5);
                      final scale =
                          0.5 + 0.5 * ((offset % (2 * 3.14159)) / (2 * 3.14159));
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: 12 + 20 * scale,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withOpacity(0.3 + 0.7 * scale),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'Analyzing...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                _phases[_phase],
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 32),
              LinearProgressIndicator(
                value: (_phase + 1) / _phases.length,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
