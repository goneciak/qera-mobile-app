import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../models/file_model.dart';

class FileService {
  final ApiClient _apiClient;

  FileService(this._apiClient);

  /// Upload file (File object or Uint8List)
  Future<FileModel> uploadFile(
    dynamic fileData, {
    required FileKind kind,
    String? filename,
    String? interviewId,
    String? offerId,
  }) async {
    final bytes = fileData is File ? await fileData.readAsBytes() : fileData as Uint8List;
    final base64Data = base64Encode(bytes);
    final mimeType = _getMimeType(filename ?? 'file');

    final response = await _apiClient.post(
      '/rep/files/upload',
      data: {
        'filename': filename ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
        'mime': mimeType,
        'data': base64Data,
        'kind': kind.value,
        if (interviewId != null) 'interviewId': interviewId,
        if (offerId != null) 'offerId': offerId,
      },
    );
    
    return FileModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Upload file from Uint8List (camera/gallery)
  Future<FileModel> uploadBytes(
    Uint8List bytes, {
    required FileKind kind,
    String? filename,
    String? mimeType,
    String? interviewId,
    String? offerId,
  }) async {
    final base64Data = base64Encode(bytes);
    final finalMimeType = mimeType ?? _getMimeType(filename ?? 'file');

    final response = await _apiClient.post(
      '/rep/files/upload',
      data: {
        'filename': filename ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
        'mime': finalMimeType,
        'data': base64Data,
        'kind': kind.value,
        if (interviewId != null) 'interviewId': interviewId,
        if (offerId != null) 'offerId': offerId,
      },
    );
    
    return FileModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get file by ID (returns file info with download URL)
  Future<FileWithUrl> getFile(String fileId) async {
    final response = await _apiClient.get('/rep/files/$fileId');
    return FileWithUrl.fromJson(response.data as Map<String, dynamic>);
  }

  /// Download file bytes from URL
  Future<Uint8List> downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  String _getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'avif':
        return 'image/avif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
