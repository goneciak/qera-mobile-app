import 'dart:async';

/// Helper do automatycznego zapisywania danych z debounce
class AutoSaveHelper {
  final Future<void> Function() onSave;
  final int debounceMs;
  
  Timer? _debounceTimer;
  
  AutoSaveHelper({
    required this.onSave,
    this.debounceMs = 2000,
  });
  
  /// Wywołaj auto-save (z debounce)
  void trigger() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: debounceMs), () async {
      await onSave();
    });
  }
  
  /// Wymuś natychmiastowy zapis (bez debounce)
  Future<void> forceSave() async {
    _debounceTimer?.cancel();
    await onSave();
  }
  
  void dispose() {
    _debounceTimer?.cancel();
  }
}
