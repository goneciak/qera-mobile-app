import '../../../core/api/api_client.dart';
import '../models/document_model.dart';

class DocumentService {
  final ApiClient _apiClient;

  DocumentService(this._apiClient);

  /// Lista wszystkich dokumentów użytkownika
  Future<List<DocumentModel>> getDocuments() async {
    final response = await _apiClient.get('/rep/documents');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => DocumentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Pobierz szczegóły dokumentu
  Future<DocumentModel> getDocument(String id) async {
    final response = await _apiClient.get('/rep/documents/$id');
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Generuj PDF wywiadu (wywołuje POST /rep/interviews/{id}/pdf)
  Future<DocumentModel> generateInterviewPdf(String interviewId) async {
    final response = await _apiClient.post('/rep/interviews/$interviewId/pdf');
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Generuj URL do pobrania PDF
  /// W produkcji backend powinien zwrócić presigned URL z S3/MinIO
  Future<String> getDownloadUrl(String documentId) async {
    final doc = await getDocument(documentId);
    // Backend zwraca storageKey - konwertujemy na URL
    // TODO: Backend powinien mieć endpoint GET /rep/documents/{id}/download który zwraca presigned URL
    return 'http://192.168.1.178:3000/api/v1/files/${doc.storageKey}';
  }

  /// Pobierz PDF dla wywiadu (jeśli istnieje)
  Future<DocumentModel?> getInterviewPdf(String interviewId) async {
    try {
      final docs = await getDocuments();
      return docs.firstWhere(
        (doc) => doc.interviewId == interviewId && doc.type == 'INTERVIEW_PDF',
      );
    } catch (e) {
      return null; // Brak PDF dla tego wywiadu
    }
  }

  /// Pobierz PDF dla oferty (jeśli istnieje)
  Future<DocumentModel?> getOfferPdf(String offerId) async {
    try {
      final docs = await getDocuments();
      return docs.firstWhere(
        (doc) => doc.offerId == offerId && doc.type == 'OFFER_PDF',
      );
    } catch (e) {
      return null; // Brak PDF dla tej oferty
    }
  }
}
