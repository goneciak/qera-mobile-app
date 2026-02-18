import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../data/file_service.dart';

final fileServiceProviderAlias = Provider<FileService>((ref) {
  return ref.watch(fileServiceProvider);
});
