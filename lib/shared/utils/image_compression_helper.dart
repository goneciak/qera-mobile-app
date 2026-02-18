import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionHelper {
  /// Compress image file to reduce size while maintaining quality
  /// 
  /// [file] - Original image file
  /// [quality] - Compression quality (0-100), default 85
  /// [maxWidth] - Maximum width in pixels, default 1920
  /// [maxHeight] - Maximum height in pixels, default 1920
  /// 
  /// Returns compressed file or null if compression fails
  static Future<File?> compressImage(
    File file, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      // Get file extension
      final fileExtension = path.extension(file.path).toLowerCase();
      
      // Only compress jpg, jpeg, png formats
      if (!['.jpg', '.jpeg', '.png'].contains(fileExtension)) {
        return file; // Return original if not supported format
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(
        tempDir.path,
        '${timestamp}_compressed$fileExtension',
      );

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: fileExtension == '.png' 
            ? CompressFormat.png 
            : CompressFormat.jpeg,
      );

      if (result == null) {
        return null;
      }

      // Convert XFile to File
      return File(result.path);
    } catch (e) {
      // Return original file if compression fails
      return file;
    }
  }

  /// Compress multiple images
  /// 
  /// Returns list of compressed files (original files if compression fails)
  static Future<List<File>> compressImages(
    List<File> files, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
    Function(int current, int total)? onProgress,
  }) async {
    final List<File> compressedFiles = [];

    for (int i = 0; i < files.length; i++) {
      onProgress?.call(i + 1, files.length);
      
      final compressed = await compressImage(
        files[i],
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
      compressedFiles.add(compressed ?? files[i]);
    }

    return compressedFiles;
  }

  /// Get file size in MB
  static Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Estimate compression savings
  static Future<Map<String, dynamic>> getCompressionStats(
    File original,
    File compressed,
  ) async {
    final originalSize = await getFileSizeMB(original);
    final compressedSize = await getFileSizeMB(compressed);
    final savedSize = originalSize - compressedSize;
    final savedPercent = (savedSize / originalSize) * 100;

    return {
      'originalSizeMB': originalSize,
      'compressedSizeMB': compressedSize,
      'savedMB': savedSize,
      'savedPercent': savedPercent,
    };
  }
}
