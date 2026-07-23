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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            const AppIconBadge(icon: Icons.graphic_eq_rounded, size: 40),
            const SizedBox(width: 10),
            Text('MozhiMuthal', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Past results',
            onPressed: () => context.push('/history'),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        top: false,
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(error: error.toString()),
          data: (sessions) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: 'Screening, made calmer.',
                        subtitle:
                            'Capture a short, guided voice screening with the family.',
                      ),
                      const SizedBox(height: 16),
                      AppSurface(
                        color: scheme.secondaryContainer.withValues(alpha: .5),
                        borderColor: scheme.secondary.withValues(alpha: .45),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppIconBadge(
                              icon: Icons.info_outline_rounded,
                              color: scheme.secondary,
                              size: 38,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Important',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'This is developmental monitoring, not a diagnosis.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (syncState.pendingCount > 0)
                        AppSurface(
                          color: scheme.tertiaryContainer.withValues(
                            alpha: .45,
                          ),
                          borderColor: scheme.tertiaryContainer,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              AppIconBadge(
                                icon: syncState.isSyncing
                                    ? Icons.cloud_sync_rounded
                                    : Icons.cloud_upload_outlined,
                                color: scheme.tertiary,
                                size: 38,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${syncState.pendingCount} screening${syncState.pendingCount == 1 ? '' : 's'} ready to sync',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      'Only numeric screening data is shared.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: syncState.isSyncing
                                    ? null
                                    : () => ref
                                          .read(syncProvider.notifier)
                                          .syncAll(),
                                child: syncState.isSyncing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sync'),
                              ),
                            ],
                          ),
                        )
                      else
                        AppSurface(
                          color: scheme.primaryContainer.withValues(alpha: .42),
                          borderColor: scheme.primaryContainer,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              AppIconBadge(
                                icon: Icons.verified_user_outlined,
                                color: scheme.primary,
                                size: 38,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ready for the next family',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      'Audio stays on this phone; results can be synced later.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 28),
                      AppSectionHeader(
                        title: sessions.isEmpty
                            ? 'Your first screening'
                            : 'Recent screenings',
                        subtitle: sessions.isEmpty
                            ? 'Start when the parent and child are comfortable.'
                            : 'Tap a result to see its details.',
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (sessions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Center(
                      child: AppSurface(
                        color: scheme.surface,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIconBadge(
                              icon: Icons.waving_hand_rounded,
                              color: scheme.secondary,
                              size: 64,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Nothing recorded yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A guided screening takes you from child details to a clear, easy-to-read result.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final riskColor = _riskColor(session.riskLevel);
                      return AppSurface(
                        onTap: () =>
                            context.push('/session-detail', extra: session),
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            AppIconBadge(
                              icon: Icons.child_care_outlined,
                              color: riskColor,
                              size: 44,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.childName ??
                                        'Child • ${session.childAgeMonths} months',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${session.anganwadiId} • ${_formatDate(session.sessionDate)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppPill(
                                  label: session.riskLevel.name.toUpperCase(),
                                  color: riskColor,
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  session.syncedToCloud
                                      ? Icons.cloud_done_outlined
                                      : Icons.cloud_queue_outlined,
                                  size: 16,
                                  color: scheme.outline,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
        label: const Text('Start screening'),
      ),
    );
  }

  Color _riskColor(RiskLevel level) => switch (level) {
    RiskLevel.red => const Color(0xFFC43D42),
    RiskLevel.yellow => const Color(0xFFC78B19),
    RiskLevel.green => const Color(0xFF3B8B6A),
  };

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIconBadge(icon: Icons.cloud_off_outlined),
              const SizedBox(height: 14),
              Text(
                'Could not load screenings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
