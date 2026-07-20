import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/scoring_engine.dart';
import '../../../services/audio_pipeline_service.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_ui.dart';

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
    ('Filtering noise', Icons.tune_rounded),
    ('Identifying voices', Icons.graphic_eq_rounded),
    ('Extracting patterns', Icons.auto_awesome_rounded),
    ('Preparing result', Icons.done_all_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _runPipeline();
  }

  Future<void> _runPipeline() async {
    final session = ref.read(sessionProvider);
    final ageMonths = session.childProfile?.childAgeMonths ?? 24;
    for (var index = 0; index < _phases.length; index++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _phase = index);
    }
    final rawResult = await AudioPipelineService.runPipeline(
      childAgeMonths: ageMonths,
    );
    final features = SessionFeatures.fromJson(rawResult);
    final result = ScoringEngine.score(features);
    ref
        .read(sessionProvider.notifier)
        .setResult(
          result: result,
          vttlMs: features.vttlMs,
          pfvStd: features.pfvStd,
          cvrRatio: features.cvrRatio,
          audioSource: features.audioSourceUsed,
        );
    if (mounted) context.go('/result');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: SoftCard(
              color: colors.primaryContainer.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => SizedBox(
                      height: 82,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(7, (index) {
                          final value =
                              (_controller.value * math.pi * 2) + index * .7;
                          final height = 20 + ((math.sin(value) + 1) * 18);
                          return Container(
                            width: 7,
                            height: height,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha: 0.45 + (index % 3) * .16,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Making sense of the session',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This takes just a moment.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  ...List.generate(_phases.length, (index) {
                    final isCurrent = index == _phase;
                    final complete = index < _phase;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          RoundIcon(
                            icon: complete
                                ? Icons.check_rounded
                                : _phases[index].$2,
                            size: 36,
                            color: (isCurrent || complete)
                                ? colors.primaryContainer
                                : colors.surfaceContainerHighest,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              _phases[index].$1,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: (isCurrent || complete)
                                    ? colors.onSurface
                                    : colors.onSurface.withValues(alpha: 0.42),
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
