import 'package:flutter/material.dart';

import '../../../data/models/biomarker_result.dart';
import '../../../data/models/session_model.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(session.riskLevel);
    final analysis = session.questionnaireAnalysis;
    final domains = _mapList(analysis['domains']);
    final questions = _mapList(analysis['questions']);

    return Scaffold(
      appBar: AppBar(title: const Text('Screening insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              border: Border.all(color: color.withOpacity(.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.childName ??
                      'Child (${session.childAgeMonths} months)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  session.riskLevel.name.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_date(session.sessionDate)} · ${session.childAgeMonths} months · ${session.anganwadiId}',
                ),
                if (session.childUuid != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Child ID: ${session.childUuid}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Acoustic screening',
            child: Column(
              children: [
                _MetricRow(
                  label: 'VTTL',
                  value: '${session.vttlMs.toStringAsFixed(0)} ms',
                  flagged: session.vttlFlagged,
                ),
                _MetricRow(
                  label: 'CVR',
                  value: session.cvrRatio.toStringAsFixed(3),
                  flagged: session.cvrFlagged,
                ),
                _MetricRow(
                  label: 'PFV',
                  value: _pfvValue(session),
                  flagged: session.pfvFlagged,
                ),
                _LabelValue(
                  label: 'Audio source',
                  value: session.audioSourceUsed,
                ),
                _LabelValue(
                  label: 'Child voiced time',
                  value:
                      '${session.childVoicedSeconds.toStringAsFixed(1)} seconds',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Development questionnaire',
            child: analysis.isEmpty
                ? const Text(
                    'Detailed questionnaire data was not saved for this session.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabelValue(
                        label: 'Questionnaire result',
                        value:
                            '${_text(analysis['tier'])} · ${_text(analysis['state'])}',
                      ),
                      if (_text(analysis['message']).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_text(analysis['message'])),
                        ),
                      if (analysis['effective_age_months'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Scored age: ${_number(analysis['effective_age_months']).toStringAsFixed(1)} months${analysis['corrected_age_used'] == true ? ' (corrected)' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      if (domains.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Domain insights',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...domains.map(
                          (domain) => ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(_text(domain['domain'])),
                            subtitle: Text(
                              _text(domain['status']).replaceAll('_', ' '),
                            ),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(_text(domain['explanation'])),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Flags ${_text(_map(domain['vector'])['flag_count'])} · Warnings ${_text(_map(domain['vector'])['warning_count'])} · Precautions ${_text(_map(domain['vector'])['precaution_count'])}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (questions.isNotEmpty)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Question-by-question details'),
                          subtitle: Text('${questions.length} saved answers'),
                          children: questions
                              .map((item) => _QuestionDetail(item: item))
                              .toList(),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            session.syncedToCloud
                ? 'This session is stored locally and synced.'
                : 'This session is stored locally and waiting to sync.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SessionDetailMissingScreen extends StatelessWidget {
  const SessionDetailMissingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Open a saved screening from the home screen.')),
  );
}

class _QuestionDetail extends StatelessWidget {
  const _QuestionDetail({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final question = _map(item['question']);
    final detail = _map(item['detail']);
    final prompt = _text(question['text_ml']).isNotEmpty
        ? _text(question['text_ml'])
        : _text(question['text']);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(prompt),
      subtitle: Text(
        'Answer: ${_answerLabel(_text(item['answer']))} · ${_text(item['severity'])}\n${_text(item['explanation'])}\n${_text(detail['recommended_action'])}',
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.flagged,
  });

  final String label, value;
  final bool flagged;

  @override
  Widget build(BuildContext context) => _LabelValue(
    label: label,
    value: value,
    trailing: Icon(
      flagged ? Icons.warning_amber_rounded : Icons.check_circle_outline,
      color: flagged ? Colors.orange.shade800 : Colors.green.shade700,
      size: 20,
    ),
  );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value, this.trailing});

  final String label, value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}

Color _riskColor(RiskLevel level) => switch (level) {
  RiskLevel.red => const Color(0xFFC62828),
  RiskLevel.yellow => const Color(0xFFF9A825),
  RiskLevel.green => const Color(0xFF2E7D32),
};

String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

String _text(Object? value) => value?.toString() ?? '';

double _number(Object? value) => value is num ? value.toDouble() : 0;

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is List) return value.map(_map).toList();
  if (value is Map) return value.values.map(_map).toList();
  return const [];
}

String _answerLabel(String answer) => switch (answer) {
  'achieved' => 'Yes',
  'notYet' => 'No',
  'unsure' => 'Unsure',
  _ => answer.isEmpty ? 'Not recorded' : answer,
};

String _pfvValue(SessionModel session) {
  if (session.pfvUnit != 'semitones') {
    return '${session.pfvStd.toStringAsFixed(2)} Hz SD (legacy session)';
  }
  final sd = session.pfvRawSemitoneSD ?? session.pfvStd;
  final z = session.pfvAgeZScore;
  return '${sd.toStringAsFixed(2)} semitones SD${z == null ? '' : ' · z ${z.toStringAsFixed(2)}'}';
}
