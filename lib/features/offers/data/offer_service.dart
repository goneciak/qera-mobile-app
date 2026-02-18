import '../../../core/api/api_client.dart';
import '../models/offer_model.dart';

class OfferService {
  final ApiClient _apiClient;

  OfferService(this._apiClient);

  /// Lista ofert
  Future<List<OfferModel>> getOffers() async {
    final response = await _apiClient.get('/rep/offers');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => OfferModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Szczegóły oferty
  Future<OfferModel> getOffer(String id) async {
    final response = await _apiClient.get('/rep/offers/$id');
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Generuj ofertę z zatwierdzonego wywiadu
  Future<OfferModel> generateOffer(String interviewId) async {
    final response = await _apiClient.post('/rep/interviews/$interviewId/offers/generate');
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Wyślij ofertę do klienta
  Future<OfferModel> sendOffer(String offerId) async {
    final response = await _apiClient.post('/rep/offers/$offerId/send');
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }
}
