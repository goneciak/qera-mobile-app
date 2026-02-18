enum EsignStatus {
  pending('PENDING'),
  signed('SIGNED'),
  rejected('REJECTED'),
  expired('EXPIRED');

  final String value;
  const EsignStatus(this.value);

  static EsignStatus fromString(String value) {
    return EsignStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EsignStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case EsignStatus.pending:
        return 'Oczekujący';
      case EsignStatus.signed:
        return 'Podpisany';
      case EsignStatus.rejected:
        return 'Odrzucony';
      case EsignStatus.expired:
        return 'Wygasły';
    }
  }

  // Alias dla kompatybilności ze starym kodem
  String get displayStatus => displayName;
}

enum EsignProvider {
  autenti('AUTENTI'),
  manual('MANUAL');

  final String value;
  const EsignProvider(this.value);

  static EsignProvider fromString(String value) {
    return EsignProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => EsignProvider.autenti,
    );
  }

  String get displayName {
    switch (this) {
      case EsignProvider.autenti:
        return 'Autenti (e-podpis)';
      case EsignProvider.manual:
        return 'Podpis ręczny';
    }
  }
}

class EsignEnvelopeModel {
  final String id;
  final EsignProvider provider;
  final String? providerId;
  final EsignStatus status;
  final String? interviewId;
  final String? offerId;
  final Map<String, dynamic>? callbackPayloadJsonb;
  final DateTime createdAt;
  final DateTime updatedAt;

  EsignEnvelopeModel({
    required this.id,
    required this.provider,
    this.providerId,
    required this.status,
    this.interviewId,
    this.offerId,
    this.callbackPayloadJsonb,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EsignEnvelopeModel.fromJson(Map<String, dynamic> json) {
    return EsignEnvelopeModel(
      id: json['id'] as String,
      provider: EsignProvider.fromString(json['provider'] as String),
      providerId: json['providerId'] as String?,
      status: EsignStatus.fromString(json['status'] as String),
      interviewId: json['interviewId'] as String?,
      offerId: json['offerId'] as String?,
      callbackPayloadJsonb: json['callbackPayloadJsonb'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.value,
      'providerId': providerId,
      'status': status.value,
      'interviewId': interviewId,
      'offerId': offerId,
      'callbackPayloadJsonb': callbackPayloadJsonb,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Alias getter dla kompatybilności
  String get displayStatus => status.displayName;
}
