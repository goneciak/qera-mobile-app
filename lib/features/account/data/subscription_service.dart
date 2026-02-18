import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  SubscriptionService(this._apiClient, this._storage);

  /// Get subscription status
  Future<SubscriptionModel?> getSubscriptionStatus() async {
    final response = await _apiClient.get(ApiEndpoints.subscriptionStatus);
    
    // Backend returns { active: boolean, subscription: Subscription | null }
    final data = response.data as Map<String, dynamic>;
    final subscriptionData = data['subscription'];
    
    if (subscriptionData == null) {
      // No subscription exists yet
      return null;
    }
    
    final subscription = SubscriptionModel.fromJson(subscriptionData as Map<String, dynamic>);
    
    // Cache subscription status
    await _storage.saveSubscriptionStatus(jsonEncode(subscription.toJson()));
    
    return subscription;
  }

  /// Create Stripe checkout session
  Future<CheckoutSessionResponse> createCheckoutSession() async {
    final response = await _apiClient.post(ApiEndpoints.subscriptionCheckout);
    return CheckoutSessionResponse.fromJson(response.data);
  }

  /// Get cached subscription status
  SubscriptionModel? getCachedSubscription() {
    final statusString = _storage.getSubscriptionStatus();
    if (statusString == null) return null;
    
    try {
      final statusJson = jsonDecode(statusString) as Map<String, dynamic>;
      return SubscriptionModel.fromJson(statusJson);
    } catch (e) {
      return null;
    }
  }
}
