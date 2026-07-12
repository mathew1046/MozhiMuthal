import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/session_provider.dart';
import '../../providers/sync_provider.dart';
import '../../../data/models/biomarker_result.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh sync count and sessions on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider.notifier).refreshCount();
      ref.invalidate(pastSessionsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    final sessionsAsync = ref.watch(pastSessionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MozhiMuthal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sync bar
          if (syncState.pendingCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: theme.colorScheme.primary.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${syncState.pendingCount} unsynced',
                    style: TextStyle(
                        fontSize: 13, color: theme.colorScheme.onSurface),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    child: TextButton(
                      onPressed: syncState.isSyncing
                          ? null
                          : () => ref.read(syncProvider.notifier).syncAll(),
                      child: syncState.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sync Now', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

          // Sessions list
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.graphic_eq,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No screenings yet',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to start a new screening',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Risk dot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _riskColor(s.riskLevel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.childName ?? 'Child (${s.childAgeMonths}m)',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.anganwadiId} · ${_formatDate(s.sessionDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _riskColor(s.riskLevel).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.riskLevel.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _riskColor(s.riskLevel),
                              ),
                            ),
                          ),
                          if (!s.syncedToCloud) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.cloud_off,
                                size: 14,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3)),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(sessionProvider.notifier).reset();
          context.push('/child-profile');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Screening'),
      ),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.red:
        return const Color(0xFFC62828);
      case RiskLevel.yellow:
        return const Color(0xFFF9A825);
      case RiskLevel.green:
        return const Color(0xFF2E7D32);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}
