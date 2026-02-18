import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../data/offer_service.dart';
import '../models/offer_model.dart';

// Service provider
final offerServiceProvider = Provider<OfferService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OfferService(apiClient);
});

// Offers list provider
final offersProvider = FutureProvider<List<OfferModel>>((ref) async {
  final offerService = ref.watch(offerServiceProvider);
  return offerService.getOffers();
});
