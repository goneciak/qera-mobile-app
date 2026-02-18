enum OcrJobStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  failed('FAILED');

  final String value;
  const OcrJobStatus(this.value);

  static OcrJobStatus fromString(String value) {
    return OcrJobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OcrJobStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case OcrJobStatus.pending:
        return 'Oczekujące';
      case OcrJobStatus.processing:
        return 'Przetwarzanie';
      case OcrJobStatus.completed:
        return 'Zakończone';
      case OcrJobStatus.failed:
        return 'Błąd';
    }
  }

  bool get isCompleted => this == OcrJobStatus.completed;
  bool get isFailed => this == OcrJobStatus.failed;
  bool get isInProgress =>
      this == OcrJobStatus.pending || this == OcrJobStatus.processing;
}

class OcrJobModel {
  final String id;
  final String repId;
  final String fileId;
  final OcrJobStatus status;
  final Map<String, dynamic>? result;
  final DateTime createdAt;
  final DateTime updatedAt;

  OcrJobModel({
    required this.id,
    required this.repId,
    required this.fileId,
    required this.status,
    this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OcrJobModel.fromJson(Map<String, dynamic> json) {
    return OcrJobModel(
      id: json['id'] as String,
      repId: json['repId'] as String,
      fileId: json['fileId'] as String,
      status: OcrJobStatus.fromString(json['status'] as String),
      result: json['result'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repId': repId,
      'fileId': fileId,
      'status': status.value,
      'result': result,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters for extracting specific fields from OCR result
  String? get extractedName => result?['name'] as String?;
  String? get extractedAddress => result?['address'] as String?;
  String? get extractedPhone => result?['phone'] as String?;
  String? get extractedEmail => result?['email'] as String?;
  
  Map<String, dynamic> get extractedFields => result ?? {};
}
