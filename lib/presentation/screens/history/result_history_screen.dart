import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/biomarker_result.dart';
import '../../../data/models/session_model.dart';
import '../../../data/repositories/session_repository.dart';
import '../../widgets/app_ui.dart';

class ResultHistoryScreen extends StatelessWidget {
  const ResultHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past screenings')),
      body: FutureBuilder<List<SessionModel>>(
        future: SessionRepository().getAllSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load results: ${snapshot.error}'),
            );
          }
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppSurface(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIconBadge(
                        icon: Icons.history_toggle_off_outlined,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved screenings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Saved screenings will appear here.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: sessions.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const AppSectionHeader(
                  title: 'Saved screenings',
                  subtitle:
                      'Review a previous result or its questionnaire insights.',
                );
              }
              return _HistoryItem(session: sessions[index - 1]);
            },
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
      RiskLevel.red => const Color(0xFFC43D42),
      RiskLevel.yellow => const Color(0xFFC78B19),
      RiskLevel.green => const Color(0xFF3B8B6A),
    };
    return AppSurface(
      onTap: () => context.push('/session-detail', extra: session),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          AppIconBadge(icon: Icons.assessment_outlined, color: color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.childName ??
                      'Child • ${session.childAgeMonths} months',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.sessionDate.day}/${session.sessionDate.month}/${session.sessionDate.year} • VTTL ${session.vttlMs.toStringAsFixed(0)} ms • CVR ${session.cvrRatio.toStringAsFixed(3)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppPill(label: session.riskLevel.name.toUpperCase(), color: color),
        ],
      ),
    );
  }
}
