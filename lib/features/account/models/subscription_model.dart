enum SubscriptionStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  pastDue('PAST_DUE'),
  canceled('CANCELED'),
  trialing('TRIALING'),
  manualActive('MANUAL_ACTIVE');

  final String value;
  const SubscriptionStatus(this.value);

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.inactive,
    );
  }

  bool get isActive =>
      this == SubscriptionStatus.active ||
      this == SubscriptionStatus.trialing ||
      this == SubscriptionStatus.manualActive;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Aktywna';
      case SubscriptionStatus.inactive:
        return 'Nieaktywna';
      case SubscriptionStatus.pastDue:
        return 'Zaległa';
      case SubscriptionStatus.canceled:
        return 'Anulowana';
      case SubscriptionStatus.trialing:
        return 'Okres próbny';
      case SubscriptionStatus.manualActive:
        return 'Aktywna (ręcznie)';
    }
  }
}

enum SubscriptionProvider {
  stripe('STRIPE'),
  manual('MANUAL');

  final String value;
  const SubscriptionProvider(this.value);

  static SubscriptionProvider fromString(String value) {
    return SubscriptionProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => SubscriptionProvider.manual,
    );
  }

  String get displayName {
    switch (this) {
      case SubscriptionProvider.stripe:
        return 'Stripe';
      case SubscriptionProvider.manual:
        return 'Ręczna';
    }
  }
}

class SubscriptionModel {
  final String? id;
  final String? repId;
  final SubscriptionStatus status;
  final SubscriptionProvider? provider;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? currentPeriodEnd;
  final DateTime? manualValidUntil;
  final DateTime? canceledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionModel({
    this.id,
    this.repId,
    required this.status,
    this.provider,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.currentPeriodEnd,
    this.manualValidUntil,
    this.canceledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String?,
      repId: json['repId'] as String?,
      status: SubscriptionStatus.fromString(json['status'] as String),
      provider: json['provider'] != null
          ? SubscriptionProvider.fromString(json['provider'] as String)
          : null,
      stripeCustomerId: json['stripeCustomerId'] as String?,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'] as String)
          : null,
      manualValidUntil: json['manualValidUntil'] != null
          ? DateTime.parse(json['manualValidUntil'] as String)
          : null,
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repId': repId,
      'status': status.value,
      'provider': provider?.value,
      'stripeCustomerId': stripeCustomerId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'manualValidUntil': manualValidUntil?.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isManual => provider == SubscriptionProvider.manual;
  bool get isStripe => provider == SubscriptionProvider.stripe;
  
  DateTime? get validUntil {
    if (isManual && manualValidUntil != null) {
      return manualValidUntil;
    }
    return currentPeriodEnd;
  }

  bool get isExpired {
    final until = validUntil;
    if (until == null) return false;
    return DateTime.now().isAfter(until);
  }

  String get providerDisplayName => provider?.displayName ?? 'Nieznany';
}

class CheckoutSessionResponse {
  final String url;

  CheckoutSessionResponse({required this.url});

  factory CheckoutSessionResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionResponse(url: json['url'] as String);
  }
}
