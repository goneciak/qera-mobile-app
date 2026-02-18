class OfferModel {
  final String id;
  final String repId;
  final String interviewId;
  final String status; // 'DRAFT' | 'SENT' | 'CLIENT_ACCEPTED' | 'REJECTED' | 'APPROVED'
  final Map<String, dynamic>? totals;
  final List<Map<String, dynamic>>? lineItems;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;

  OfferModel({
    required this.id,
    required this.repId,
    required this.interviewId,
    required this.status,
    this.totals,
    this.lineItems,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      repId: json['repId'] as String,
      interviewId: json['interviewId'] as String,
      status: json['status'] as String,
      totals: json['totals'] as Map<String, dynamic>?,
      lineItems: (json['lineItems'] as List<dynamic>?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
    );
  }

  String get displayStatus {
    switch (status) {
      case 'DRAFT':
        return 'Szkic';
      case 'SENT':
        return 'Wysłana';
      case 'CLIENT_ACCEPTED':
        return 'Zaakceptowana przez klienta';
      case 'REJECTED':
        return 'Odrzucona';
      case 'APPROVED':
        return 'Zatwierdzona';
      default:
        return status;
    }
  }

  String get clientName {
    // Pobierz z totals lub lineItems jeśli dostępne
    return 'Klient'; // TODO: dodać po rozszerzeniu API
  }

  double get totalPrice {
    if (totals != null && totals!['total'] != null) {
      return (totals!['total'] as num).toDouble();
    }
    return 0.0;
  }
}

enum OfferStatus {
  draft('DRAFT'),
  sent('SENT'),
  clientAccepted('CLIENT_ACCEPTED'),
  rejected('REJECTED'),
  approved('APPROVED');

  final String value;
  const OfferStatus(this.value);

  static OfferStatus fromString(String value) {
    return OfferStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OfferStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case OfferStatus.draft:
        return 'Szkic';
      case OfferStatus.sent:
        return 'Wysłana';
      case OfferStatus.clientAccepted:
        return 'Zaakceptowana przez klienta';
      case OfferStatus.rejected:
        return 'Odrzucona';
      case OfferStatus.approved:
        return 'Zatwierdzona przez firmę';
    }
  }
}
