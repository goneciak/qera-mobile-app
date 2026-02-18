import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_tracking_service.dart';

/// Sync operation model
class SyncOperation {
  final String id;
  final String type; // 'CREATE', 'UPDATE', 'DELETE'
  final String resource; // 'interviews', 'offers', 'files'
  final String? resourceId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  SyncOperation({
    required this.id,
    required this.type,
    required this.resource,
    this.resourceId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'resource': resource,
      'resourceId': resourceId,
      'data': jsonEncode(data),
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'error': error,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as String,
      type: map['type'] as String,
      resource: map['resource'] as String,
      resourceId: map['resourceId'] as String?,
      data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['createdAt'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
      error: map['error'] as String?,
    );
  }

  SyncOperation copyWith({
    int? retryCount,
    String? error,
  }) {
    return SyncOperation(
      id: id,
      type: type,
      resource: resource,
      resourceId: resourceId,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }
}

/// Sync Queue Manager
class SyncQueue {
  static Database? _database;
  static const String _tableName = 'sync_queue';
  static const int maxRetries = 3;

  /// Initialize database
  static Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'qera_sync.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            resource TEXT NOT NULL,
            resourceId TEXT,
            data TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            retryCount INTEGER DEFAULT 0,
            error TEXT
          )
        ''');
      },
    );

    return _database!;
  }

  /// Add operation to queue
  static Future<void> enqueue(SyncOperation operation) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        operation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Enqueued: ${operation.type} ${operation.resource} ${operation.resourceId ?? ""}');
      
      ErrorTrackingService.addBreadcrumb(
        message: 'Sync operation enqueued',
        category: 'sync',
        data: {
          'type': operation.type,
          'resource': operation.resource,
        },
      );
    } catch (e, stackTrace) {
      print('❌ Error enqueuing operation: $e');
      ErrorTrackingService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Failed to enqueue sync operation',
      );
    }
  }

  /// Get all pending operations
  static Future<List<SyncOperation>> getPending() async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        orderBy: 'createdAt ASC',
        where: 'retryCount < ?',
        whereArgs: [maxRetries],
      );
      
      return maps.map((map) => SyncOperation.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting pending operations: $e');
      return [];
    }
  }

  /// Remove operation from queue
  static Future<void> remove(String operationId) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [operationId],
      );
      print('✅ Removed operation: $operationId');
    } catch (e) {
      print('❌ Error removing operation: $e');
    }
  }

  /// Update operation (for retry)
  static Future<void> update(SyncOperation operation) async {
    try {
      final db = await database;
      await db.update(
        _tableName,
        operation.toMap(),
        where: 'id = ?',
        whereArgs: [operation.id],
      );
    } catch (e) {
      print('❌ Error updating operation: $e');
    }
  }

  /// Get queue size
  static Future<int> getQueueSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error getting queue size: $e');
      return 0;
    }
  }

  /// Clear all operations
  static Future<void> clear() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      print('✅ Sync queue cleared');
    } catch (e) {
      print('❌ Error clearing queue: $e');
    }
  }

  /// Get failed operations (exceeded max retries)
  static Future<List<SyncOperation>> getFailed() async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'retryCount >= ?',
        whereArgs: [maxRetries],
      );
      
      return maps.map((map) => SyncOperation.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting failed operations: $e');
      return [];
    }
  }

  /// Remove all failed operations
  static Future<void> clearFailed() async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'retryCount >= ?',
        whereArgs: [maxRetries],
      );
      print('✅ Failed operations cleared');
    } catch (e) {
      print('❌ Error clearing failed operations: $e');
    }
  }
}

// Riverpod providers
final syncQueueSizeProvider = StreamProvider<int>((ref) async* {
  while (true) {
    await Future.delayed(const Duration(seconds: 5));
    yield await SyncQueue.getQueueSize();
  }
});
