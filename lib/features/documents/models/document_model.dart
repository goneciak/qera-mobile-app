class DocumentModel {
  final String id;
  final String repId;
  final String? interviewId;
  final String? offerId;
  final String type;
  final int version;
  final String storageKey;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.repId,
    this.interviewId,
    this.offerId,
    required this.type,
    required this.version,
    required this.storageKey,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      repId: json['repId'] as String,
      interviewId: json['interviewId'] as String?,
      offerId: json['offerId'] as String?,
      type: json['type'] as String,
      version: json['version'] as int,
      storageKey: json['storageKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repId': repId,
      'interviewId': interviewId,
      'offerId': offerId,
      'type': type,
      'version': version,
      'storageKey': storageKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayType {
    switch (type) {
      case 'INTERVIEW_PDF':
        return 'PDF Wywiadu';
      case 'OFFER_PDF':
        return 'PDF Oferty';
      default:
        return type;
    }
  }

  /// Generuj URL do pliku
  /// Backend powinien zwracać presigned URL z S3/MinIO dla storageKey
  String get downloadUrl {
    // W produkcji to będzie presigned URL z S3
    // Dla MVP używamy bezpośredniego URL do backendu
    return 'http://192.168.1.178:3000/api/v1/files/$storageKey';
  }

  bool get isInterviewPdf => type == 'INTERVIEW_PDF';
  bool get isOfferPdf => type == 'OFFER_PDF';
}
