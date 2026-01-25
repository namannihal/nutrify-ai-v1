import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Cache entry metadata
class CacheEntry {
  final String key;
  final String data;
  final DateTime cachedAt;
  final DateTime? serverModifiedAt;
  final bool isDirty;

  CacheEntry({
    required this.key,
    required this.data,
    required this.cachedAt,
    this.serverModifiedAt,
    this.isDirty = false,
  });

  Map<String, dynamic> toMap() => {
        'key': key,
        'data': data,
        'cached_at': cachedAt.toIso8601String(),
        'server_modified_at': serverModifiedAt?.toIso8601String(),
        'is_dirty': isDirty ? 1 : 0,
      };

  factory CacheEntry.fromMap(Map<String, dynamic> map) => CacheEntry(
        key: map['key'] as String,
        data: map['data'] as String,
        cachedAt: DateTime.parse(map['cached_at'] as String),
        serverModifiedAt: map['server_modified_at'] != null
            ? DateTime.parse(map['server_modified_at'] as String)
            : null,
        isDirty: (map['is_dirty'] as int) == 1,
      );
}

/// Local cache service using SQLite
class CacheService {
  static CacheService? _instance;
  Database? _database;

  CacheService._();

  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nutrify_cache.db');

    _logger.i('Initializing cache database at: $path');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main cache table for JSON data
    await db.execute('''
      CREATE TABLE cache (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        server_modified_at TEXT,
        is_dirty INTEGER DEFAULT 0
      )
    ''');

    // Index for faster lookups
    await db.execute('CREATE INDEX idx_cache_dirty ON cache(is_dirty)');

    // Table for user-specific data (nutrition plans, fitness plans, etc.)
    await db.execute('''
      CREATE TABLE user_data (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        server_modified_at TEXT,
        is_dirty INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_user_data_type ON user_data(type)');
    await db.execute('CREATE INDEX idx_user_data_dirty ON user_data(is_dirty)');

    // Table for custom exercises (stored locally)
    await db.execute('''
      CREATE TABLE custom_exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        primary_muscle TEXT,
        equipment TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    _logger.i('Cache database created successfully');
  }

  // === Generic Cache Methods ===

  /// Get cached data by key
  Future<String?> get(String key) async {
    final db = await database;
    final results = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['data'] as String;
  }

  /// Get cache entry with metadata
  Future<CacheEntry?> getEntry(String key) async {
    final db = await database;
    final results = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return CacheEntry.fromMap(results.first);
  }

  /// Store data in cache
  Future<void> set(
    String key,
    String data, {
    DateTime? serverModifiedAt,
    bool isDirty = false,
  }) async {
    final db = await database;
    final entry = CacheEntry(
      key: key,
      data: data,
      cachedAt: DateTime.now(),
      serverModifiedAt: serverModifiedAt,
      isDirty: isDirty,
    );

    await db.insert(
      'cache',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete cached data
  Future<void> delete(String key) async {
    final db = await database;
    await db.delete('cache', where: 'key = ?', whereArgs: [key]);
  }

  /// Check if cache has newer data than server
  Future<bool> hasNewerThan(String key, DateTime serverModified) async {
    final entry = await getEntry(key);
    if (entry == null) return false;
    if (entry.serverModifiedAt == null) return false;
    return entry.serverModifiedAt!.isAfter(serverModified);
  }

  /// Get all dirty entries that need syncing
  Future<List<CacheEntry>> getDirtyEntries() async {
    final db = await database;
    final results = await db.query(
      'cache',
      where: 'is_dirty = ?',
      whereArgs: [1],
    );

    return results.map((r) => CacheEntry.fromMap(r)).toList();
  }

  /// Mark entry as synced (not dirty)
  Future<void> markSynced(String key) async {
    final db = await database;
    await db.update(
      'cache',
      {'is_dirty': 0},
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // === User Data Methods ===

  /// Get user data by type (e.g., 'nutrition_plan', 'fitness_plan')
  Future<Map<String, dynamic>?> getUserData(String type) async {
    final db = await database;
    final results = await db.query(
      'user_data',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'cached_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return json.decode(results.first['data'] as String) as Map<String, dynamic>;
  }

  /// Store user data
  Future<void> setUserData(
    String id,
    String type,
    Map<String, dynamic> data, {
    DateTime? serverModifiedAt,
    bool isDirty = false,
  }) async {
    final db = await database;
    await db.insert(
      'user_data',
      {
        'id': id,
        'type': type,
        'data': json.encode(data),
        'cached_at': DateTime.now().toIso8601String(),
        'server_modified_at': serverModifiedAt?.toIso8601String(),
        'is_dirty': isDirty ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all user data of a specific type
  Future<List<Map<String, dynamic>>> getAllUserData(String type) async {
    final db = await database;
    final results = await db.query(
      'user_data',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'cached_at DESC',
    );

    return results
        .map((r) => json.decode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // === Custom Exercise Methods ===

  /// Save custom exercise
  Future<void> saveCustomExercise({
    required String id,
    required String name,
    required String exerciseType,
    String? primaryMuscle,
    String? equipment,
  }) async {
    final db = await database;
    await db.insert(
      'custom_exercises',
      {
        'id': id,
        'name': name,
        'exercise_type': exerciseType,
        'primary_muscle': primaryMuscle,
        'equipment': equipment,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all custom exercises
  Future<List<Map<String, dynamic>>> getCustomExercises() async {
    final db = await database;
    return db.query('custom_exercises', orderBy: 'created_at DESC');
  }

  /// Delete custom exercise
  Future<void> deleteCustomExercise(String id) async {
    final db = await database;
    await db.delete('custom_exercises', where: 'id = ?', whereArgs: [id]);
  }

  // === Utility Methods ===

  /// Clear all cache
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cache');
    await db.delete('user_data');
    _logger.i('Cache cleared');
  }

  /// Clear cache for a specific type
  Future<void> clearType(String type) async {
    final db = await database;
    await db.delete('user_data', where: 'type = ?', whereArgs: [type]);
    _logger.i('Cleared cache for type: $type');
  }

  /// Get cache size info
  Future<Map<String, int>> getCacheStats() async {
    final db = await database;
    final cacheCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM cache'));
    final userDataCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM user_data'));
    final customExercisesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM custom_exercises'));

    return {
      'cache_entries': cacheCount ?? 0,
      'user_data_entries': userDataCount ?? 0,
      'custom_exercises': customExercisesCount ?? 0,
    };
  }

  /// Check if cache is stale (older than duration)
  Future<bool> isStale(String key, Duration maxAge) async {
    final entry = await getEntry(key);
    if (entry == null) return true;

    final age = DateTime.now().difference(entry.cachedAt);
    return age > maxAge;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _logger.i('Cache database closed');
  }
}

/// Cache keys constants
class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String currentNutritionPlan = 'current_nutrition_plan';
  static const String currentFitnessPlan = 'current_fitness_plan';
  static const String workoutHistory = 'workout_history';
  static const String mealLogs = 'meal_logs';
  static const String progressEntries = 'progress_entries';
  static const String personalRecords = 'personal_records';
}

/// Data types for user_data table
class DataTypes {
  static const String nutritionPlan = 'nutrition_plan';
  static const String fitnessPlan = 'fitness_plan';
  static const String workoutSession = 'workout_session';
  static const String mealLog = 'meal_log';
  static const String progressEntry = 'progress_entry';
}
