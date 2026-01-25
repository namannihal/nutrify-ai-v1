import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../models/nutrition.dart';
import '../models/fitness.dart';
import '../models/exercise_library.dart';

// Type alias for consistency (model uses WorkoutPlan, we use FitnessPlan in UI)
typedef FitnessPlan = WorkoutPlan;

final _logger = Logger();

class LocalDatabase {
  static Database? _database;
  static const String _dbName = 'nutrify_local.db';
  static const int _dbVersion = 2; // Bumped for custom exercises table

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _logger.d('Initializing local database at: $path');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    _logger.d('Creating local database tables...');

    // Nutrition plans table
    await db.execute('''
      CREATE TABLE nutrition_plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        last_synced INTEGER NOT NULL,
        is_dirty INTEGER DEFAULT 0
      )
    ''');

    // Fitness plans table
    await db.execute('''
      CREATE TABLE fitness_plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        last_synced INTEGER NOT NULL,
        is_dirty INTEGER DEFAULT 0
      )
    ''');

    // Sync queue for pending changes
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Custom exercises table (user-created exercises)
    await db.execute('''
      CREATE TABLE custom_exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        primary_muscle TEXT,
        equipment TEXT,
        category TEXT DEFAULT 'strength',
        level TEXT DEFAULT 'intermediate',
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_nutrition_user ON nutrition_plans(user_id)');
    await db.execute('CREATE INDEX idx_fitness_user ON fitness_plans(user_id)');
    await db.execute('CREATE INDEX idx_sync_queue_created ON sync_queue(created_at)');
    await db.execute('CREATE INDEX idx_custom_exercises_name ON custom_exercises(name)');

    _logger.d('Local database tables created successfully');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.d('Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      // Add custom exercises table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_exercises (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          exercise_type TEXT NOT NULL,
          primary_muscle TEXT,
          equipment TEXT,
          category TEXT DEFAULT 'strength',
          level TEXT DEFAULT 'intermediate',
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_custom_exercises_name ON custom_exercises(name)');
      _logger.d('Added custom_exercises table in migration');
    }
  }

  // === Nutrition Plans ===

  static Future<void> saveNutritionPlan(NutritionPlan plan, String userId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'nutrition_plans',
      {
        'id': plan.id,
        'user_id': userId,
        'data_json': jsonEncode(plan.toJson()),
        'last_synced': now,
        'is_dirty': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _logger.d('Saved nutrition plan ${plan.id} to local storage');
  }

  static Future<NutritionPlan?> getNutritionPlan(String userId) async {
    final db = await database;

    final results = await db.query(
      'nutrition_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_synced DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      _logger.d('No nutrition plan found in local storage for user $userId');
      return null;
    }

    try {
      final jsonData = jsonDecode(results.first['data_json'] as String);
      final plan = NutritionPlan.fromJson(jsonData as Map<String, dynamic>);
      _logger.d('Loaded nutrition plan ${plan.id} from local storage');
      return plan;
    } catch (e) {
      _logger.e('Failed to parse nutrition plan from local storage: $e');
      return null;
    }
  }

  static Future<void> deleteNutritionPlan(String planId) async {
    final db = await database;
    await db.delete(
      'nutrition_plans',
      where: 'id = ?',
      whereArgs: [planId],
    );
    _logger.d('Deleted nutrition plan $planId from local storage');
  }

  // === Fitness Plans ===

  static Future<void> saveFitnessPlan(FitnessPlan plan, String userId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'fitness_plans',
      {
        'id': plan.id,
        'user_id': userId,
        'data_json': jsonEncode(plan.toJson()),
        'last_synced': now,
        'is_dirty': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _logger.d('Saved fitness plan ${plan.id} to local storage');
  }

  static Future<FitnessPlan?> getFitnessPlan(String userId) async {
    final db = await database;

    final results = await db.query(
      'fitness_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_synced DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      _logger.d('No fitness plan found in local storage for user $userId');
      return null;
    }

    try {
      final jsonData = jsonDecode(results.first['data_json'] as String);
      final plan = FitnessPlan.fromJson(jsonData as Map<String, dynamic>);
      _logger.d('Loaded fitness plan ${plan.id} from local storage');
      return plan;
    } catch (e) {
      _logger.e('Failed to parse fitness plan from local storage: $e');
      return null;
    }
  }

  static Future<void> deleteFitnessPlan(String planId) async {
    final db = await database;
    await db.delete(
      'fitness_plans',
      where: 'id = ?',
      whereArgs: [planId],
    );
    _logger.d('Deleted fitness plan $planId from local storage');
  }

  // === Sync Queue ===

  static Future<void> addToSyncQueue({
    required String tableName,
    required String recordId,
    required String action, // 'insert', 'update', 'delete'
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    _logger.d('Added $action for $tableName:$recordId to sync queue');
  }

  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  static Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
    _logger.d('Cleared sync queue');
  }

  // === Utility ===

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('nutrition_plans');
    await db.delete('fitness_plans');
    await db.delete('sync_queue');
    _logger.d('Cleared all local data');
  }

  static Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('nutrition_plans', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('fitness_plans', where: 'user_id = ?', whereArgs: [userId]);
    _logger.d('Cleared local data for user $userId');
  }

  // === Custom Exercises ===

  /// Save a custom exercise
  static Future<void> saveCustomExercise(LibraryExercise exercise) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'custom_exercises',
      {
        'id': exercise.id,
        'name': exercise.name,
        'exercise_type': exercise.exerciseType.name,
        'primary_muscle': exercise.primaryMuscles.isNotEmpty ? exercise.primaryMuscles.first : null,
        'equipment': exercise.equipment,
        'category': exercise.category,
        'level': exercise.level,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _logger.d('Saved custom exercise: ${exercise.name}');
  }

  /// Get all custom exercises
  static Future<List<LibraryExercise>> getCustomExercises() async {
    final db = await database;

    final results = await db.query(
      'custom_exercises',
      orderBy: 'created_at DESC',
    );

    return results.map((row) {
      return LibraryExercise(
        id: row['id'] as String,
        name: row['name'] as String,
        level: row['level'] as String? ?? 'intermediate',
        equipment: row['equipment'] as String? ?? 'other',
        category: row['category'] as String? ?? 'strength',
        primaryMuscles: row['primary_muscle'] != null
            ? [row['primary_muscle'] as String]
            : [],
      );
    }).toList();
  }

  /// Delete a custom exercise
  static Future<void> deleteCustomExercise(String exerciseId) async {
    final db = await database;
    await db.delete(
      'custom_exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
    _logger.d('Deleted custom exercise: $exerciseId');
  }

  /// Check if exercise is custom
  static Future<bool> isCustomExercise(String exerciseId) async {
    final db = await database;
    final results = await db.query(
      'custom_exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
      limit: 1,
    );
    return results.isNotEmpty;
  }
}
