import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/offline_helper.dart';
import '../providers/offline_providers.dart';
import '../../features/files/data/file_service.dart';
import '../../features/files/models/file_model.dart';
import '../../core/providers/providers.dart';

/// Serwis do synchronizacji offline queue
class SyncQueueService {
  final OfflineHelper _offlineHelper;
  final FileService _fileService;

  SyncQueueService(this._offlineHelper, this._fileService);

  /// Sprawdź i przetworz oczekujące uploady
  Future<SyncResult> processPendingUploads() async {
    final pending = _offlineHelper.getPendingUploads();
    
    if (pending.isEmpty) {
      return SyncResult(success: 0, failed: 0, total: 0);
    }

    int successCount = 0;
    int failedCount = 0;

    for (final upload in pending) {
      try {
        final uploadId = upload['id'] as String;
        final filePath = upload['filePath'] as String;
        final kind = FileKind.fromString(upload['kind'] as String);
        final interviewId = upload['interviewId'] as String?;
        final offerId = upload['offerId'] as String?;

        // Retry upload
        await _fileService.uploadFile(
          File(filePath),
          kind: kind,
          filename: filePath.split('/').last,
          interviewId: interviewId,
          offerId: offerId,
        );

        // Usuń z kolejki po sukcesie
        await _offlineHelper.removePendingUpload(uploadId);
        successCount++;
      } catch (e) {
        failedCount++;
        // Zostaw w kolejce - retry przy następnej synchronizacji
      }
    }

    return SyncResult(
      success: successCount,
      failed: failedCount,
      total: pending.length,
    );
  }

  /// Sprawdź czy są niesynchronizowane dane
  bool hasUnsyncedData() {
    return _offlineHelper.hasUnsyncedData();
  }

  /// Wyczyść wszystkie lokalne szkice (tylko na żądanie użytkownika)
  Future<void> clearAllDrafts() async {
    await _offlineHelper.clearAllDrafts();
  }
}

class SyncResult {
  final int success;
  final int failed;
  final int total;

  SyncResult({
    required this.success,
    required this.failed,
    required this.total,
  });

  bool get hasFailures => failed > 0;
  bool get allSuccess => success == total;
  String get summary => 'Zsynchronizowano: $success/$total${hasFailures ? ' (błędy: $failed)' : ''}';
}

/// Provider dla SyncQueueService
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final offlineHelper = ref.watch(offlineHelperProvider);
  final fileService = ref.watch(fileServiceProvider);
  return SyncQueueService(offlineHelper, fileService);
});
