import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';

class SyncRepository {
  final SupabaseClient _supabase;

  SyncRepository({SupabaseClient? supabase}) : _supabase = supabase ?? Supabase.instance.client;

  Future<void> syncSessions(List<SessionModel> sessions) async {
    if (sessions.isEmpty) return;

    final List<Map<String, dynamic>> payload = sessions.map((s) => {
      'id': s.id,
      'anganwadi_id': s.anganwadiId,
      'district_code': s.districtCode,
      'child_age_months': s.childAgeMonths,
      'risk_level': s.riskLevel.name,
      'vttl_ms': s.vttlMs,
      'pfv_std': s.pfvStd,
      'cvr_ratio': s.cvrRatio,
      'vttl_flagged': s.vttlFlagged,
      'pfv_flagged': s.pfvFlagged,
      'cvr_flagged': s.cvrFlagged,
      'audio_source': s.audioSourceUsed,
      'session_date': s.sessionDate.toIso8601String(),
    }).toList();

    try {
      await _supabase.from('screenings').insert(payload);
    } catch (e) {
      throw Exception('Failed to sync sessions: $e');
    }
  }
}
