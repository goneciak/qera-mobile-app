import '../../../core/api/api_client.dart';
import '../models/ocr_job_model.dart';

class OcrService {
  final ApiClient _apiClient;

  OcrService(this._apiClient);

  /// Start OCR processing for a file
  Future<OcrJobModel> ingestOcrJob(String fileId) async {
    final response = await _apiClient.post(
      '/rep/ocr/ingest',
      data: {'fileId': fileId},
    );
    return OcrJobModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// List all OCR jobs for current user
  Future<List<OcrJobModel>> listOcrJobs() async {
    final response = await _apiClient.get('/rep/ocr/jobs');
    return (response.data as List)
        .map((job) => OcrJobModel.fromJson(job as Map<String, dynamic>))
        .toList();
  }

  /// Confirm OCR result with corrected fields
  Future<OcrJobModel> confirmOcrResult(
    String jobId,
    Map<String, dynamic> confirmedFields,
  ) async {
    final response = await _apiClient.post(
      '/rep/ocr/jobs/$jobId/confirm',
      data: {'confirmedFields': confirmedFields},
    );
    return OcrJobModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get single OCR job by ID (polling for status)
  Future<OcrJobModel> getOcrJob(String jobId) async {
    final jobs = await listOcrJobs();
    return jobs.firstWhere(
      (job) => job.id == jobId,
      orElse: () => throw Exception('OCR job not found'),
    );
  }

  /// Helper method to extract data from image (complete flow: upload → OCR → extract)
  /// Used for scanning documents in interview screen
  Future<Map<String, dynamic>> extractData(
    dynamic imageBytes,
    String documentType,
  ) async {
    // This is a simplified helper that would:
    // 1. Upload file (requires FileService)
    // 2. Start OCR job
    // 3. Poll for completion
    // 4. Return extracted fields
    
    // For now, return mock data based on document type
    // TODO: Implement full flow when FileService upload is integrated
    
    if (documentType == 'ID') {
      return {
        'firstName': 'Jan',
        'lastName': 'Kowalski',
        'pesel': '12345678901',
      };
    } else if (documentType == 'KW') {
      return {
        'street': 'ul. Kwiatowa',
        'buildingNumber': '10',
        'city': 'Warszawa',
        'postalCode': '00-001',
      };
    }
    
    return {};
  }
}
