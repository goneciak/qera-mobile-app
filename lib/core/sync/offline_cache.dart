import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

/// Local cache for offline data
class OfflineCache {
  static Database? _database;
  static const String _cacheTable = 'offline_cache';

  /// Initialize database
  static Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'qera_cache.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_cacheTable (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            expiresAt TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  /// Store data in cache
  static Future<void> set({
    required String key,
    required dynamic value,
    Duration? ttl,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final expiresAt = ttl != null ? now.add(ttl) : null;

      await db.insert(
        _cacheTable,
        {
          'key': key,
          'value': jsonEncode(value),
          'expiresAt': expiresAt?.toIso8601String(),
          'createdAt': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ Cached: $key');
    } catch (e) {
      print('❌ Error caching data: $e');
    }
  }

  /// Get data from cache
  static Future<dynamic> get(String key) async {
    try {
      final db = await database;
      final maps = await db.query(
        _cacheTable,
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isEmpty) return null;

      final data = maps.first;
      final expiresAt = data['expiresAt'] as String?;

      // Check if expired
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiry)) {
          await remove(key);
          return null;
        }
      }

      return jsonDecode(data['value'] as String);
    } catch (e) {
      print('❌ Error getting cached data: $e');
      return null;
    }
  }

  /// Remove data from cache
  static Future<void> remove(String key) async {
    try {
      final db = await database;
      await db.delete(
        _cacheTable,
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e) {
      print('❌ Error removing cached data: $e');
    }
  }

  /// Clear expired entries
  static Future<void> clearExpired() async {
    try {
      final db = await database;
      await db.delete(
        _cacheTable,
        where: 'expiresAt < ?',
        whereArgs: [DateTime.now().toIso8601String()],
      );
      print('✅ Expired cache entries cleared');
    } catch (e) {
      print('❌ Error clearing expired cache: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete(_cacheTable);
      print('✅ All cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_cacheTable');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error getting cache size: $e');
      return 0;
    }
  }
}
