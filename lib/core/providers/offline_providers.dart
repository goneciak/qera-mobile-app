import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../helpers/offline_helper.dart';
import '../services/sync_queue_service.dart';

/// Provider dla SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Provider dla OfflineHelper
final offlineHelperProvider = Provider<OfflineHelper>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineHelper(prefs);
});

/// Provider sprawdzający czy jest internet (z prawdziwym listenerem)
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    // Jeśli lista zawiera wifi lub mobile - mamy internet
    return result.contains(ConnectivityResult.wifi) ||
           result.contains(ConnectivityResult.mobile) ||
           result.contains(ConnectivityResult.ethernet);
  });
});

/// Synchroniczny getter do aktualnego stanu połączenia
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.when(
    data: (isOnline) => isOnline,
    loading: () => true, // Domyślnie zakładamy że jest internet
    error: (_, __) => true,
  );
});

/// Provider dla statusu offline mode
final offlineModeProvider = StateProvider<bool>((ref) {
  final offline = ref.watch(offlineHelperProvider);
  return offline.isOfflineModeEnabled;
});

/// Provider który nasłuchuje powrotu internetu i uruchamia sync
final connectivitySyncProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  final syncService = ref.watch(syncQueueServiceProvider);
  
  connectivity.whenData((isOnline) async {
    if (isOnline && syncService.hasUnsyncedData()) {
      // Internet wrócił i są niesynchronizowane dane - uruchom sync
      try {
        final result = await syncService.processPendingUploads();
        if (result.success > 0) {
          // TODO: Pokaż komunikat o synchronizacji
          print('✅ Sync completed: ${result.summary}');
        }
      } catch (e) {
        print('❌ Sync error: $e');
      }
    }
  });
});
