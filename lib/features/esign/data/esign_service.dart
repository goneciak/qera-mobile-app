import '../../../core/api/api_client.dart';
import '../models/esign_model.dart';

class EsignService {
  final ApiClient _apiClient;

  EsignService(this._apiClient);

  /// Utwórz e-podpis przez Autenti
  Future<EsignEnvelopeModel> createEnvelope({
    required String interviewId,
    String provider = 'AUTENTI',
    String? offerId,
  }) async {
    final response = await _apiClient.post(
      '/rep/interviews/$interviewId/esign/create-envelope',
      data: {
        'provider': provider,
        if (offerId != null) 'offerId': offerId,
      },
    );
    return EsignEnvelopeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Upload ręcznego podpisu
  Future<EsignEnvelopeModel> uploadManualSignature({
    required String interviewId,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      '/rep/interviews/$interviewId/signature/manual-upload',
      data: {
        if (notes != null) 'notes': notes,
      },
    );
    return EsignEnvelopeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Pobierz status e-podpisu
  Future<EsignEnvelopeModel> getEnvelopeStatus(String envelopeId) async {
    final response = await _apiClient.get('/rep/esign/$envelopeId/status');
    return EsignEnvelopeModel.fromJson(response.data as Map<String, dynamic>);
  }
}
