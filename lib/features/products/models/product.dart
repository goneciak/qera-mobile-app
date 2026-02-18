class Product {
  final String id;
  final String sku;
  final String name;
  final String? category;
  final double basePriceNet;
  final int vatRateWithInstallation;        // 8% (VAT rate)
  final int vatRateWithoutInstallation;     // 23% (VAT rate)
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    this.category,
    required this.basePriceNet,
    required this.vatRateWithInstallation,
    required this.vatRateWithoutInstallation,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      basePriceNet: (json['basePriceNet'] as num).toDouble(),
      vatRateWithInstallation: json['vatRateWithInstallation'] as int,
      vatRateWithoutInstallation: json['vatRateWithoutInstallation'] as int,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      'basePriceNet': basePriceNet,
      'vatRateWithInstallation': vatRateWithInstallation,
      'vatRateWithoutInstallation': vatRateWithoutInstallation,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods dla obliczania cen brutto
  double get basePriceGross {
    // Zakładamy "bez montażu" jako domyślne
    return basePriceNet * (1 + vatRateWithoutInstallation / 100);
  }

  double get basePriceGrossWithInstallation {
    return basePriceNet * (1 + vatRateWithInstallation / 100);
  }

  double calculateGrossPrice({bool withInstallation = false}) {
    final vatRate = withInstallation ? vatRateWithInstallation : vatRateWithoutInstallation;
    return basePriceNet * (1 + vatRate / 100);
  }

  // Compatibility getters dla starego kodu
  String? get description => null; // Backend nie ma tego pola
  bool get isActive => active; // Alias
}
