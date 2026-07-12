import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session_model.dart';

class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'mozhimuthal.db';
  static const _dbVersion = 1;
  static const _tableSessions = 'sessions';

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
        district_code TEXT
      )
    ''');
  }

  // ── CRUD ──

  static Future<int> insertSession(SessionModel session) async {
    final db = await database;
    return db.insert(_tableSessions, session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<SessionModel>> getRecentSessions({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      _tableSessions,
      orderBy: 'session_date DESC',
      limit: limit,
    );
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  static Future<List<SessionModel>> getUnsyncedSessions() async {
    final db = await database;
    final maps = await db.query(
      _tableSessions,
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  static Future<int> markSynced(String sessionId) async {
    final db = await database;
    return db.update(
      _tableSessions,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  static Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableSessions WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
