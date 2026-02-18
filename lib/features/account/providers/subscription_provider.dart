import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../data/subscription_service.dart';
import '../../../core/providers/providers.dart';

class SubscriptionState {
  final SubscriptionModel? subscription;
  final bool isLoading;
  final String? error;

  SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionModel? subscription,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isActive =>
      subscription?.status.isActive ?? false;
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _subscriptionService;

  SubscriptionNotifier(this._subscriptionService) : super(SubscriptionState()) {
    _loadCachedSubscription();
  }

  void _loadCachedSubscription() {
    final cached = _subscriptionService.getCachedSubscription();
    if (cached != null) {
      state = state.copyWith(subscription: cached);
    }
  }

  Future<void> fetchSubscriptionStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final subscription = await _subscriptionService.getSubscriptionStatus();
      state = state.copyWith(
        subscription: subscription,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<String> createCheckoutSession() async {
    final response = await _subscriptionService.createCheckoutSession();
    return response.url;
  }

  /// Reset state (called on logout)
  void reset() {
    state = SubscriptionState();
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(subscriptionService);
});
