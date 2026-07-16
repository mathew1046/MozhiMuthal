import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';
import '../local/database_helper.dart';

class SyncRepository {
  final SupabaseClient _supabase;

  SyncRepository({SupabaseClient? supabase}) : _supabase = supabase ?? Supabase.instance.client;

  Future<void> syncSessions(List<SessionModel> sessions) async {
    if (sessions.isEmpty) return;

    final List<Map<String, dynamic>> payload = sessions.map((s) => s.toSupabaseJson()).toList();

    try {
      for (final item in payload) {
        if (item['demo_session'] == true) continue;
        await _supabase.rpc('sync_screening_bundle', params: {'bundle': item});
        await DatabaseHelper.markSynced(item['id'] as String);
      }
    } catch (e) {
      throw Exception('Failed to sync sessions: $e');
    }
  }

  Future<int> syncAll() async {
    final unsynced = await DatabaseHelper.getUnsyncedSessions();
    int synced = 0;

    for (final session in unsynced) {
      try {
        if (session.demoSession) continue;
        await _supabase.rpc('sync_screening_bundle', params: {'bundle': session.toSupabaseJson()});
        await DatabaseHelper.markSynced(session.id);
        synced++;
      } catch (e) {
        debugPrint('SyncRepository: Failed to sync session ${session.id}: $e');
      }
    }
    return synced;
  }
}
