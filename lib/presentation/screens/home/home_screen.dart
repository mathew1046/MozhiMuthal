import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/biomarker_result.dart';
import '../../providers/session_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/app_ui.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
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
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MozhiMuthal', style: theme.textTheme.titleLarge),
            Text('Early childhood screening', style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(syncProvider.notifier).refreshCount();
            ref.invalidate(pastSessionsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const PageIntro(
                      eyebrow: 'Screening workspace',
                      title: 'Every voice deserves to be heard.',
                      subtitle:
                          'Record a guided play session and keep a clear local record for follow-up.',
                    ),
                    const SizedBox(height: 24),
                    if (syncState.pendingCount > 0) ...[
                      _SyncCard(syncState: syncState),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent screenings',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'ON THIS DEVICE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.44),
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              sessionsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SoftCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const RoundIcon(icon: Icons.cloud_off_rounded),
                          const SizedBox(height: 14),
                          Text(
                            'Unable to load screenings',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text('$error', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                        child: SoftCard(
                          color: colors.secondaryContainer.withValues(
                            alpha: 0.58,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RoundIcon(
                                icon: Icons.graphic_eq_rounded,
                                size: 68,
                                color: colors.secondary,
                                iconColor: colors.onSecondary,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Your screening list is ready',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start your first guided session when the child and parent are comfortable.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) => _SessionTile(
                        riskLevel: sessions[index].riskLevel,
                        childName: sessions[index].childName,
                        ageMonths: sessions[index].childAgeMonths,
                        anganwadiId: sessions[index].anganwadiId,
                        sessionDate: sessions[index].sessionDate,
                        synced: sessions[index].syncedToCloud,
                      ),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(sessionProvider.notifier).reset();
          context.push('/child-profile');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New screening'),
      ),
    );
  }
}

class _SyncCard extends ConsumerWidget {
  final SyncState syncState;

  const _SyncCard({required this.syncState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SoftCard(
      color: colors.primaryContainer.withValues(alpha: 0.72),
      child: Row(
        children: [
          RoundIcon(
            icon: Icons.cloud_upload_outlined,
            color: colors.primary,
            iconColor: colors.onPrimary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${syncState.pendingCount} record${syncState.pendingCount == 1 ? '' : 's'} ready to sync',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'Stored safely on this device',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: syncState.isSyncing
                ? null
                : () => ref.read(syncProvider.notifier).syncAll(),
            child: syncState.isSyncing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sync'),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final RiskLevel riskLevel;
  final String? childName;
  final int ageMonths;
  final String anganwadiId;
  final DateTime sessionDate;
  final bool synced;

  const _SessionTile({
    required this.riskLevel,
    required this.childName,
    required this.ageMonths,
    required this.anganwadiId,
    required this.sessionDate,
    required this.synced,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final riskColor = _riskColor(riskLevel);
    final label = riskLevel.name.toUpperCase();
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          RoundIcon(
            icon: riskLevel == RiskLevel.green
                ? Icons.check_rounded
                : riskLevel == RiskLevel.yellow
                ? Icons.visibility_outlined
                : Icons.priority_high_rounded,
            size: 44,
            color: riskColor.withValues(alpha: 0.13),
            iconColor: riskColor,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName ?? 'Child, $ageMonths months',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '$anganwadiId  ·  ${_formatDate(sessionDate)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                size: 16,
                color: colors.onSurface.withValues(alpha: 0.38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.red:
        return const Color(0xFFB53A4A);
      case RiskLevel.yellow:
        return const Color(0xFFB98216);
      case RiskLevel.green:
        return const Color(0xFF367E62);
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}
