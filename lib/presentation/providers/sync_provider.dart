import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/local/database_helper.dart';

class SyncState {
  final int pendingCount;
  final bool isSyncing;
  final DateTime? lastSyncTime;

  const SyncState({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastSyncTime,
  });

  SyncState copyWith({
    int? pendingCount,
    bool? isSyncing,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());

  Future<void> refreshCount() async {
    final count = await DatabaseHelper.getUnsyncedCount();
    state = state.copyWith(pendingCount: count);
  }

  Future<void> syncAll() async {
    state = state.copyWith(isSyncing: true);
    try {
      await SyncRepository().syncAll();
      final count = await DatabaseHelper.getUnsyncedCount();
      state = state.copyWith(
        pendingCount: count,
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (_) {
      state = state.copyWith(isSyncing: false);
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
