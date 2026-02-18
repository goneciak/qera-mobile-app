import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../providers/providers.dart';
import 'sync_queue.dart';
import '../services/error_tracking_service.dart';
import '../services/analytics_service.dart';

class SyncService {
  final ApiClient _apiClient;
  final AnalyticsService _analytics;
  
  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncService(this._apiClient, this._analytics);

  /// Initialize sync service
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
      );
      
      if (isOnline && !_isSyncing) {
        print('🌐 Connection restored - starting sync');
        sync();
      }
    });

    // Start periodic sync every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sync();
    });

    print('✅ SyncService initialized');
  }

  /// Dispose service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Sync all pending operations
  Future<void> sync() async {
    if (_isSyncing) {
      print('⏳ Sync already in progress');
      return;
    }

    _isSyncing = true;

    try {
      final pendingOps = await SyncQueue.getPending();
      
      if (pendingOps.isEmpty) {
        print('✅ No pending operations to sync');
        _isSyncing = false;
        return;
      }

      print('🔄 Syncing ${pendingOps.length} operations...');
      
      int successCount = 0;
      int failCount = 0;

      for (final op in pendingOps) {
        try {
          await _executeSyncOperation(op);
          await SyncQueue.remove(op.id);
          successCount++;
          
          ErrorTrackingService.addBreadcrumb(
            message: 'Sync operation succeeded',
            category: 'sync',
            data: {
              'type': op.type,
              'resource': op.resource,
            },
          );
        } catch (e, stackTrace) {
          failCount++;
          print('❌ Failed to sync operation ${op.id}: $e');
          
          // Increment retry count
          final updatedOp = op.copyWith(
            retryCount: op.retryCount + 1,
            error: e.toString(),
          );
          
          await SyncQueue.update(updatedOp);
          
          ErrorTrackingService.captureException(
            e,
            stackTrace: stackTrace,
            hint: 'Sync operation failed',
            extras: {
              'operation_id': op.id,
              'type': op.type,
              'resource': op.resource,
              'retry_count': updatedOp.retryCount,
            },
          );
        }
      }

      print('✅ Sync completed: $successCount succeeded, $failCount failed');
      
      await _analytics.logEvent(
        name: 'sync_completed',
        parameters: {
          'success_count': successCount,
          'fail_count': failCount,
          'total': pendingOps.length,
        },
      );
    } catch (e, stackTrace) {
      print('❌ Sync error: $e');
      ErrorTrackingService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Sync process error',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute single sync operation
  Future<void> _executeSyncOperation(SyncOperation op) async {
    final endpoint = _buildEndpoint(op);
    
    switch (op.type) {
      case 'CREATE':
        await _apiClient.post(endpoint, data: op.data);
        break;
      case 'UPDATE':
        await _apiClient.patch(endpoint, data: op.data);
        break;
      case 'DELETE':
        await _apiClient.delete(endpoint);
        break;
      default:
        throw Exception('Unknown operation type: ${op.type}');
    }
  }

  /// Build API endpoint from operation
  String _buildEndpoint(SyncOperation op) {
    final baseEndpoint = '/rep/${op.resource}';
    
    if (op.resourceId != null) {
      return '$baseEndpoint/${op.resourceId}';
    }
    
    return baseEndpoint;
  }

  /// Force sync now
  Future<void> forceSyncNow() async {
    print('🔄 Force sync triggered');
    await sync();
  }

  /// Check if online
  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }
}

// Riverpod providers
final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return SyncService(apiClient, analytics);
});

final isSyncingProvider = StateProvider<bool>((ref) => false);

final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  });
});
