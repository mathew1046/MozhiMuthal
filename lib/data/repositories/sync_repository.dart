import '../models/session_model.dart';
import '../local/database_helper.dart';

/// Handles syncing local sessions to Supabase.
/// Supabase client integration will be added when backend is ready.
class SyncRepository {
  /// Upload all unsynced sessions to Supabase.
  Future<int> syncAll() async {
    final unsynced = await DatabaseHelper.getUnsyncedSessions();
    int synced = 0;

    for (final session in unsynced) {
      try {
        // TODO: Supabase insert using session.toSupabaseJson()
        // await supabase.from('screenings').insert(session.toSupabaseJson());
        await DatabaseHelper.markSynced(session.id);
        synced++;
      } catch (_) {
        // Skip failed uploads — will retry on next sync
      }
    }
    return synced;
  }
}
