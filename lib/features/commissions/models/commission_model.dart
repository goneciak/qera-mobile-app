class CommissionPostingModel {
  final String description;
  final double baseAmount;
  final double rate;
  final double amount;

  CommissionPostingModel({
    required this.description,
    required this.baseAmount,
    required this.rate,
    required this.amount,
  });

  factory CommissionPostingModel.fromJson(Map<String, dynamic> json) {
    return CommissionPostingModel(
      description: json['description'] as String,
      baseAmount: (json['baseAmount'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'baseAmount': baseAmount,
      'rate': rate,
      'amount': amount,
    };
  }
}

class CommissionLedgerModel {
  final String id;
  final String repId;
  final String offerId;
  final List<CommissionPostingModel> postings;
  final double totalCommission;
  final String currency;
  final DateTime createdAt;

  CommissionLedgerModel({
    required this.id,
    required this.repId,
    required this.offerId,
    required this.postings,
    required this.totalCommission,
    required this.currency,
    required this.createdAt,
  });

  factory CommissionLedgerModel.fromJson(Map<String, dynamic> json) {
    return CommissionLedgerModel(
      id: json['id'] as String,
      repId: json['repId'] as String,
      offerId: json['offerId'] as String,
      postings: (json['postings'] as List<dynamic>)
          .map((e) => CommissionPostingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCommission: (json['totalCommission'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'PLN',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repId': repId,
      'offerId': offerId,
      'postings': postings.map((e) => e.toJson()).toList(),
      'totalCommission': totalCommission,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedTotal => '$totalCommission $currency';
}

// Backwards compatibility - stary model dla UI
class CommissionModel {
  final String id;
  final double total;
  final String? offerId;
  final DateTime createdAt;

  CommissionModel({
    required this.id,
    required this.total,
    this.offerId,
    required this.createdAt,
  });

  factory CommissionModel.fromLedger(CommissionLedgerModel ledger) {
    return CommissionModel(
      id: ledger.id,
      total: ledger.totalCommission,
      offerId: ledger.offerId,
      createdAt: ledger.createdAt,
    );
  }

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    // Jeśli to jest CommissionLedger z API
    if (json.containsKey('postings')) {
      final ledger = CommissionLedgerModel.fromJson(json);
      return CommissionModel.fromLedger(ledger);
    }
    
    // Fallback do prostego modelu
    return CommissionModel(
      id: json['id'] as String,
      total: (json['totalCommission'] ?? json['total'] ?? 0) as double,
      offerId: json['offerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total': total,
      'offerId': offerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isPaid => false; // Backend nie ma tego pola w MVP
  
  // Compatibility getters
  double get baseCommission => total * 0.8; // Mock value
  double get bonus => total * 0.2; // Mock value
  String? get offerClientName => null; // Nie mamy tego w API
  DateTime? get paidAt => null; // Backend nie ma
}
