import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/session_model.dart';

class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'mozhimuthal.db';
  static const _dbVersion = 4;
  static const _tableSessions = 'sessions';
  static final List<SessionModel> _webSessions = [];

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final sql in const [
            'ALTER TABLE sessions ADD COLUMN child_uuid TEXT',
            "ALTER TABLE sessions ADD COLUMN analysis_status TEXT NOT NULL DEFAULT 'COMPLETE'",
            "ALTER TABLE sessions ADD COLUMN quality_reasons TEXT NOT NULL DEFAULT ''",
            'ALTER TABLE sessions ADD COLUMN transition_count INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE sessions ADD COLUMN voiced_seconds REAL NOT NULL DEFAULT 0',
            'ALTER TABLE sessions ADD COLUMN child_voiced_seconds REAL NOT NULL DEFAULT 0',
            'ALTER TABLE sessions ADD COLUMN demo_session INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE sessions ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0',
          ]) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE sessions ADD COLUMN questionnaire_state TEXT',
          );
          await db.execute(
            "ALTER TABLE sessions ADD COLUMN questionnaire_answers TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 4) {
          for (final sql in const [
            'ALTER TABLE sessions ADD COLUMN child_birth_date TEXT',
            'ALTER TABLE sessions ADD COLUMN gestational_weeks INTEGER',
            'ALTER TABLE sessions ADD COLUMN questionnaire_run_id TEXT',
            'ALTER TABLE sessions ADD COLUMN consent_id TEXT',
            "ALTER TABLE sessions ADD COLUMN questionnaire_analysis TEXT NOT NULL DEFAULT '{}'",
            "ALTER TABLE sessions ADD COLUMN decision_trace TEXT NOT NULL DEFAULT '[]'",
            "ALTER TABLE sessions ADD COLUMN waveform TEXT NOT NULL DEFAULT '[]'",
          ]) {
            await db.execute(sql);
          }
        }
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableSessions (
        id TEXT PRIMARY KEY,
        anganwadi_id TEXT NOT NULL,
        worker_name TEXT,
        child_name TEXT,
        child_age_months INTEGER NOT NULL,
        child_birth_date TEXT,
        gestational_weeks INTEGER,
        session_date TEXT NOT NULL,
        risk_level TEXT NOT NULL,
        vttl_ms REAL,
        pfv_std REAL,
        cvr_ratio REAL,
        vttl_flagged INTEGER,
        pfv_flagged INTEGER,
        cvr_flagged INTEGER,
        audio_source TEXT,
        synced INTEGER DEFAULT 0,
        district_code TEXT,
        child_uuid TEXT,
        analysis_status TEXT NOT NULL DEFAULT 'COMPLETE',
        quality_reasons TEXT NOT NULL DEFAULT '',
        transition_count INTEGER NOT NULL DEFAULT 0,
        voiced_seconds REAL NOT NULL DEFAULT 0,
        child_voiced_seconds REAL NOT NULL DEFAULT 0,
        demo_session INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0
        ,questionnaire_state TEXT
        ,questionnaire_answers TEXT NOT NULL DEFAULT ''
        ,questionnaire_run_id TEXT
        ,consent_id TEXT
        ,questionnaire_analysis TEXT NOT NULL DEFAULT '{}'
        ,decision_trace TEXT NOT NULL DEFAULT '[]'
        ,waveform TEXT NOT NULL DEFAULT '[]'
      )
    ''');
  }

  // ── CRUD ──

  static Future<int> insertSession(SessionModel session) async {
    if (kIsWeb) {
      _webSessions.removeWhere((item) => item.id == session.id);
      _webSessions.add(session);
      return 1;
    }
    final db = await database;
    return db.insert(
      _tableSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<SessionModel>> getRecentSessions({int limit = 20}) async {
    if (kIsWeb) {
      final sessions = [..._webSessions]
        ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      return sessions.take(limit).toList();
    }
    final db = await _databaseOrNull();
    if (db == null) return const [];
    final maps = await db.query(
      _tableSessions,
      orderBy: 'session_date DESC',
      limit: limit,
    );
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  static Future<List<SessionModel>> getAllSessions() async {
    if (kIsWeb) {
      final sessions = [..._webSessions]
        ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      return sessions;
    }
    final db = await _databaseOrNull();
    if (db == null) return const [];
    final maps = await db.query(_tableSessions, orderBy: 'session_date DESC');
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  static Future<List<SessionModel>> getUnsyncedSessions() async {
    if (kIsWeb) return _webSessions.where((s) => !s.syncedToCloud).toList();
    final db = await _databaseOrNull();
    if (db == null) return const [];
    final maps = await db.query(
      _tableSessions,
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  static Future<int> markSynced(String sessionId) async {
    if (kIsWeb) return 1;
    final db = await database;
    return db.update(
      _tableSessions,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  static Future<int> getUnsyncedCount() async {
    if (kIsWeb) return 0;
    final db = await _databaseOrNull();
    if (db == null) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableSessions WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<Database?> _databaseOrNull() async {
    try {
      return await database;
    } catch (_) {
      return null;
    }
  }
}
