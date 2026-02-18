import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper do obsługi offline mode - zapisuje dane lokalnie
class OfflineHelper {
  static const String _offlineModeKey = 'offline_mode_enabled';
  static const String _draftPrefix = 'draft_';
  static const String _pendingUploadsKey = 'pending_uploads';
  static const String _lastSyncKey = 'last_sync_';

  final SharedPreferences _prefs;

  OfflineHelper(this._prefs);

  /// Sprawdź czy offline mode jest włączony
  bool get isOfflineModeEnabled => _prefs.getBool(_offlineModeKey) ?? false;

  /// Włącz/wyłącz offline mode
  Future<void> setOfflineMode(bool enabled) async {
    await _prefs.setBool(_offlineModeKey, enabled);
  }

  /// Zapisz szkic lokalnie (auto-save)
  Future<void> saveDraft(String entityType, String id, Map<String, dynamic> data) async {
    final key = '$_draftPrefix${entityType}_$id';
    final jsonString = jsonEncode(data);
    await _prefs.setString(key, jsonString);
    await _updateLastSync(entityType, id);
  }

  /// Pobierz szkic z local storage
  Map<String, dynamic>? getDraft(String entityType, String id) {
    final key = '$_draftPrefix${entityType}_$id';
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Usuń szkic po wysłaniu
  Future<void> removeDraft(String entityType, String id) async {
    final key = '$_draftPrefix${entityType}_$id';
    await _prefs.remove(key);
    await _prefs.remove('$_lastSyncKey${entityType}_$id');
  }

  /// Pobierz wszystkie szkice danego typu
  List<String> getDraftIds(String entityType) {
    final prefix = '$_draftPrefix$entityType';
    return _prefs.getKeys()
        .where((key) => key.startsWith(prefix))
        .map((key) => key.replaceFirst(prefix, '').replaceFirst('_', ''))
        .toList();
  }

  /// Dodaj plik do kolejki uploadu (offline)
  Future<void> addPendingUpload(Map<String, dynamic> uploadData) async {
    final pending = getPendingUploads();
    pending.add(uploadData);
    await _prefs.setString(_pendingUploadsKey, jsonEncode(pending));
  }

  /// Pobierz listę oczekujących uploadów
  List<Map<String, dynamic>> getPendingUploads() {
    final jsonString = _prefs.getString(_pendingUploadsKey);
    if (jsonString == null) return [];
    
    try {
      final list = jsonDecode(jsonString) as List;
      return list.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Usuń upload z kolejki po wysłaniu
  Future<void> removePendingUpload(String uploadId) async {
    final pending = getPendingUploads();
    pending.removeWhere((upload) => upload['id'] == uploadId);
    await _prefs.setString(_pendingUploadsKey, jsonEncode(pending));
  }

  /// Sprawdź kiedy ostatnio zapisano dany obiekt
  DateTime? getLastSync(String entityType, String id) {
    final key = '$_lastSyncKey${entityType}_$id';
    final timestamp = _prefs.getString(key);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  Future<void> _updateLastSync(String entityType, String id) async {
    final key = '$_lastSyncKey${entityType}_$id';
    await _prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// Wyczyść wszystkie lokalne szkice (tylko na żądanie użytkownika)
  Future<void> clearAllDrafts() async {
    final draftKeys = _prefs.getKeys().where((key) => key.startsWith(_draftPrefix));
    for (final key in draftKeys) {
      await _prefs.remove(key);
    }
  }

  /// Sprawdź czy są niesynchronizowane dane
  bool hasUnsyncedData() {
    return getPendingUploads().isNotEmpty || 
           _prefs.getKeys().any((key) => key.startsWith(_draftPrefix));
  }
}
