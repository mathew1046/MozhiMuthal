import 'package:flutter/material.dart';
import '../../../core/constants.dart';

enum BiomarkerKind { vttl, cvr, pfv }

void showBiomarkerDetail(
  BuildContext context, {
  required BiomarkerKind kind,
  required int ageMonths,
  required double value,
  required bool flagged,
  required List<double> waveform,
  required List<Map<String, dynamic>> trace,
  double? pfvAgeZScore,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BiomarkerDetailSheet(
      kind: kind,
      ageMonths: ageMonths,
      value: value,
      flagged: flagged,
      waveform: waveform,
      trace: trace,
      pfvAgeZScore: pfvAgeZScore,
    ),
  );
}

class _BiomarkerDetailSheet extends StatelessWidget {
  const _BiomarkerDetailSheet({
    required this.kind,
    required this.ageMonths,
    required this.value,
    required this.flagged,
    required this.waveform,
    required this.trace,
    required this.pfvAgeZScore,
  });
  final BiomarkerKind kind;
  final int ageMonths;
  final double value;
  final bool flagged;
  final List<double> waveform;
  final List<Map<String, dynamic>> trace;
  final double? pfvAgeZScore;

  String get _name => switch (kind) {
    BiomarkerKind.vttl => 'Vocal turn-taking latency',
    BiomarkerKind.cvr => 'Child vocalisation ratio',
    BiomarkerKind.pfv => 'Pitch variability',
  };
  String get _short => switch (kind) {
    BiomarkerKind.vttl => 'VTTL',
    BiomarkerKind.cvr => 'CVR',
    BiomarkerKind.pfv => 'PFV',
  };
  String get _threshold => switch (kind) {
    BiomarkerKind.vttl =>
      'Flagged when the median adult-to-child response delay is over ${AppConstants.vttlThresholdMs.toStringAsFixed(0)} ms.',
    BiomarkerKind.cvr =>
      'For this age group, flagged when the child vocalisation ratio is below ${(AppConstants.cvrThresholds[AppConstants.getAgeBucket(ageMonths)]! * 100).toStringAsFixed(0)}%.',
    BiomarkerKind.pfv =>
      'Flagged when the age-normed PFV z-score is outside ±${AppConstants.pfvZScoreFlagThreshold.toStringAsFixed(2)}.',
  };
  String get _value => switch (kind) {
    BiomarkerKind.vttl => '${value.toStringAsFixed(0)} ms',
    BiomarkerKind.cvr => '${(value * 100).toStringAsFixed(1)}%',
    BiomarkerKind.pfv => '${value.toStringAsFixed(2)} semitones SD',
  };

  @override
  Widget build(BuildContext context) {
    final color = flagged ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final decisions = trace
        .where(
          (item) =>
              (item['end_ms'] as num? ?? 0) > (item['start_ms'] as num? ?? 0),
        )
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Text(
                '$_short — $_name',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                flagged
                    ? 'Flagged for follow-up'
                    : 'Within this screening threshold',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Measured value: $_value\nAge z-score: ${pfvAgeZScore?.toStringAsFixed(2) ?? 'not available'}\n$_threshold',
              ),
              const SizedBox(height: 24),
              const Text(
                'Recording energy trace',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _TraceChart(waveform: waveform, windows: decisions),
              const SizedBox(height: 8),
              const Text(
                'The waveform is a derived loudness trace, not playable or stored audio. Orange markers show the completed 10-second windows used by the model.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Text(
                'Model decision positions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (decisions.isEmpty)
                const Text('No individual analysis windows were saved.')
              else
                ...decisions.map((item) {
                  final start = ((item['start_ms'] as num).toDouble() / 1000)
                      .toStringAsFixed(0);
                  final end = ((item['end_ms'] as num).toDouble() / 1000)
                      .toStringAsFixed(0);
                  final windowValue = switch (kind) {
                    BiomarkerKind.vttl =>
                      '${((item['vttl_ms'] as num?) ?? 0).toStringAsFixed(0)} ms',
                    BiomarkerKind.cvr =>
                      '${(((item['cvr_ratio'] as num?) ?? 0) * 100).toStringAsFixed(1)}%',
                    BiomarkerKind.pfv =>
                      '${(item['pfv_frames'] as num?)?.toInt() ?? 0} contour frames',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('$start–$end s: $windowValue'),
                  );
                }),
              const SizedBox(height: 16),
              const Text(
                'This is a screening explanation, not a diagnosis.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TraceChart extends StatelessWidget {
  const _TraceChart({required this.waveform, required this.windows});
  final List<double> waveform;
  final List<Map<String, dynamic>> windows;
  @override
  Widget build(BuildContext context) {
    final samples = waveform.isEmpty
        ? List<double>.filled(60, .04)
        : List<double>.generate(
            60,
            (i) =>
                waveform[(i * waveform.length / 60)
                    .floor()
                    .clamp(0, waveform.length - 1)
                    .toInt()],
          );
    return Container(
      height: 92,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          samples.length,
          (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: .5),
              height: 4 + samples[i] * 65,
              color: i % 10 == 0 && windows.isNotEmpty
                  ? Colors.orange
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
