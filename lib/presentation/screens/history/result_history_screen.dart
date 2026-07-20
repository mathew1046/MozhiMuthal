import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/biomarker_result.dart';
import '../../../data/models/session_model.dart';
import '../../../data/repositories/session_repository.dart';

class ResultHistoryScreen extends StatelessWidget {
  const ResultHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Results')),
      body: FutureBuilder<List<SessionModel>>(
        future: SessionRepository().getAllSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Text('Could not load results: ${snapshot.error}'),
            );
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty)
            return const Center(child: Text('No saved screening results yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _HistoryItem(session: sessions[index]),
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final color = switch (session.riskLevel) {
      RiskLevel.red => const Color(0xFFC62828),
      RiskLevel.yellow => const Color(0xFFF9A825),
      RiskLevel.green => const Color(0xFF2E7D32),
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.12),
          child: Icon(Icons.assessment_outlined, color: color),
        ),
        title: Text(
          session.childName ?? 'Child (${session.childAgeMonths} months)',
        ),
        subtitle: Text(
          '${session.sessionDate.day}/${session.sessionDate.month}/${session.sessionDate.year} · VTTL ${session.vttlMs.toStringAsFixed(0)} ms · CVR ${session.cvrRatio.toStringAsFixed(3)}',
        ),
        trailing: Text(
          session.riskLevel.name.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        onTap: () => context.push('/session-detail', extra: session),
      ),
    );
  }
}
