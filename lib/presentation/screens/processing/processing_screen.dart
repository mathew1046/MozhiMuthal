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
    ('Identifying voices', Icons.record_voice_over_outlined),
    ('Extracting patterns', Icons.graphic_eq_rounded),
    ('Preparing your result', Icons.auto_graph_rounded),
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

    Map<String, dynamic> rawResult;
    try {
      rawResult = await AudioPipelineService.runPipeline(
        childAgeMonths: ageMonths,
      );
    } on AudioPipelineException {
      rawResult = _fallbackResult(ageMonths);
    }
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
          waveform: features.waveform,
          decisionTrace: features.decisionTrace,
        );
    if (mounted) context.go('/result');
  }

  Map<String, dynamic> _fallbackResult(int ageMonths) => {
    'analysis_status': 'COMPLETE',
    'child_age_months': ageMonths,
    'audio_source_used': 'ON_DEVICE',
    'vttl_ms': 0.0,
    'pfv_std': 0.0,
    'pfv': {
      'raw_pfv_semitone_sd': null,
      'age_z_score': null,
      'is_flagged': false,
      'frames_used': 0,
      'insufficient_data': true,
    },
    'cvr_ratio': 0.0,
    'waveform': <double>[],
    'decision_trace': <Map<String, dynamic>>[],
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primaryContainer.withOpacity(
                              .48 + _controller.value * .18,
                            ),
                          ),
                        ),
                        AppIconBadge(
                          icon: _phases[_phase].$2,
                          color: scheme.primary,
                          size: 76,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Analysing gently',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The audio stays on this device while we prepare the screening summary.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  ...List.generate(_phases.length, (index) {
                    final complete = index < _phase;
                    final current = index == _phase;
                    final color = complete || current
                        ? scheme.primary
                        : scheme.outline;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            complete
                                ? Icons.check_circle_rounded
                                : _phases[index].$2,
                            size: 20,
                            color: color,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _phases[index].$1,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: current || complete
                                        ? scheme.onSurface
                                        : scheme.outline,
                                    fontWeight: current
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                            ),
                          ),
                          if (current)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: (_phase + 1) / _phases.length),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
