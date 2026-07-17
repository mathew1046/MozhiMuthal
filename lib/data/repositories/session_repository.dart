import '../local/database_helper.dart';
import '../models/session_model.dart';

class SessionRepository {
  Future<void> saveSession(SessionModel session) async {
    await DatabaseHelper.insertSession(session);
  }

  Future<List<SessionModel>> getRecentSessions({int limit = 20}) async {
    return DatabaseHelper.getRecentSessions(limit: limit);
  }

  Future<List<SessionModel>> getAllSessions() =>
      DatabaseHelper.getAllSessions();

  Future<List<SessionModel>> getUnsyncedSessions() async {
    return DatabaseHelper.getUnsyncedSessions();
  }

  Future<void> markSynced(String sessionId) async {
    await DatabaseHelper.markSynced(sessionId);
  }

  Future<int> getUnsyncedCount() async {
    return DatabaseHelper.getUnsyncedCount();
  }
}
