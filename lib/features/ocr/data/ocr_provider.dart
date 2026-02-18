import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../data/ocr_service.dart';

final ocrServiceProviderAlias = Provider<OcrService>((ref) {
  return ref.watch(ocrServiceProvider);
});
