import 'package:flutter/material.dart';

enum InterviewStatus {
  draft('DRAFT'),
  submitted('SUBMITTED'),
  approved('APPROVED'),
  rejected('REJECTED'),
  pdfSent('PDF_SENT'),
  signedAutenti('SIGNED_AUTENTI'),
  signedManualUpload('SIGNED_MANUAL_UPLOAD');

  final String value;
  const InterviewStatus(this.value);

  static InterviewStatus fromString(String value) {
    return InterviewStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InterviewStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case InterviewStatus.draft:
        return 'Szkic';
      case InterviewStatus.submitted:
        return 'Wysłany do firmy';
      case InterviewStatus.approved:
        return 'Zatwierdzony';
      case InterviewStatus.rejected:
        return 'Odrzucony';
      case InterviewStatus.pdfSent:
        return 'Wysłano PDF';
      case InterviewStatus.signedAutenti:
        return 'Podpisano (e-podpis)';
      case InterviewStatus.signedManualUpload:
        return 'Podpisano (skan)';
    }
  }

  // Czy można edytować wywiad w tym statusie
  bool get canEdit => this == InterviewStatus.draft || this == InterviewStatus.rejected;
  
  // Czy można wysłać do zatwierdzenia
  bool get canSubmit => this == InterviewStatus.draft;
  
  // Czy można generować PDF
  bool get canGeneratePdf => this == InterviewStatus.approved || this == InterviewStatus.submitted;
  
  // Czy można wysłać PDF do klienta
  bool get canSendPdf => this == InterviewStatus.approved || this == InterviewStatus.pdfSent;
  
  // Czy można zbierać podpis
  bool get canCollectSignature => this == InterviewStatus.approved || this == InterviewStatus.pdfSent;
  
  // Czy można utworzyć ofertę
  bool get canCreateOffer => this == InterviewStatus.signedAutenti || this == InterviewStatus.signedManualUpload;
  
  // Kolor badge'a
  Color get badgeColor {
    switch (this) {
      case InterviewStatus.draft:
        return Colors.grey;
      case InterviewStatus.submitted:
        return Colors.blue;
      case InterviewStatus.approved:
        return Colors.green;
      case InterviewStatus.rejected:
        return Colors.red;
      case InterviewStatus.pdfSent:
        return Colors.teal;
      case InterviewStatus.signedAutenti:
      case InterviewStatus.signedManualUpload:
        return Colors.green.shade700;
    }
  }
}

enum FloorType {
  basement('BASEMENT', 'Piwnica'),
  groundFloor('GROUND_FLOOR', 'Parter'),
  floor('FLOOR', 'Piętro'),
  attic('ATTIC', 'Poddasze');

  final String value;
  final String displayName;
  
  const FloorType(this.value, this.displayName);

  static FloorType fromString(String value) {
    return FloorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FloorType.groundFloor,
    );
  }
}

class Interview {
  final String id;
  final InterviewStatus status;
  final String? locality;
  final DateTime? visitDate;
  final String? ownerFirstName;
  final String? ownerLastName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? buildingStreet;
  final String? buildingCity;
  final double? usableArea;
  final int? yearBuilt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Interview({
    required this.id,
    required this.status,
    this.locality,
    this.visitDate,
    this.ownerFirstName,
    this.ownerLastName,
    this.ownerPhone,
    this.ownerEmail,
    this.buildingStreet,
    this.buildingCity,
    this.usableArea,
    this.yearBuilt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      id: json['id'] as String,
      status: InterviewStatus.fromString(json['status'] as String),
      locality: json['locality'] as String?,
      visitDate: json['visitDate'] != null
          ? DateTime.parse(json['visitDate'] as String)
          : null,
      ownerFirstName: json['ownerFirstName'] as String?,
      ownerLastName: json['ownerLastName'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      buildingStreet: json['buildingStreet'] as String?,
      buildingCity: json['buildingCity'] as String?,
      usableArea: json['usableArea'] != null
          ? (json['usableArea'] as num).toDouble()
          : null,
      yearBuilt: json['yearBuilt'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.value,
      'locality': locality,
      'visitDate': visitDate?.toIso8601String(),
      'ownerFirstName': ownerFirstName,
      'ownerLastName': ownerLastName,
      'ownerPhone': ownerPhone,
      'ownerEmail': ownerEmail,
      'buildingStreet': buildingStreet,
      'buildingCity': buildingCity,
      'usableArea': usableArea,
      'yearBuilt': yearBuilt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get ownerFullName {
    if (ownerFirstName != null && ownerLastName != null) {
      return '$ownerFirstName $ownerLastName';
    }
    return ownerEmail ?? 'Brak danych';
  }

  String get addressSummary {
    if (buildingStreet != null && buildingCity != null) {
      return '$buildingStreet, $buildingCity';
    }
    return locality ?? 'Brak adresu';
  }
}

class RoomModel {
  final String id;
  final String name;
  final double area;
  final bool heated;
  final Map<String, dynamic>? windowOverrides;
  final String? notes;

  RoomModel({
    String? id,
    required this.name,
    required this.area,
    this.heated = true,
    this.windowOverrides,
    this.notes,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      area: (json['area'] as num).toDouble(),
      heated: json['heated'] as bool? ?? true,
      windowOverrides: json['windowOverrides'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'heated': heated,
      if (windowOverrides != null) 'windowOverrides': windowOverrides,
      if (notes != null) 'notes': notes,
    };
  }
}

class FloorModel {
  final String id;
  final String type;
  final double area;
  final double height;
  final Map<String, dynamic>? structure;
  final List<RoomModel> rooms;

  FloorModel({
    String? id,
    required this.type,
    required this.area,
    required this.height,
    this.structure,
    this.rooms = const [],
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] as String?,
      type: json['type'] as String,
      area: (json['area'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      structure: json['structure'] as Map<String, dynamic>?,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'area': area,
      'height': height,
      if (structure != null) 'structure': structure,
      'rooms': rooms.map((e) => e.toJson()).toList(),
    };
  }
}

class InterviewModel {
  final String id;
  final String repId;
  final String status;
  final String? town;
  final DateTime? visitDate;
  final Map<String, dynamic>? ownerData;
  final Map<String, dynamic>? buildingAddress;
  final Map<String, dynamic>? buildingCore;
  final Map<String, dynamic>? heating;
  final String? notes;
  final bool consent;
  final List<FloorModel> floors;
  final DateTime createdAt;
  final DateTime updatedAt;

  InterviewModel({
    required this.id,
    required this.repId,
    required this.status,
    this.town,
    this.visitDate,
    this.ownerData,
    this.buildingAddress,
    this.buildingCore,
    this.heating,
    this.notes,
    this.consent = false,
    this.floors = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory InterviewModel.fromJson(Map<String, dynamic> json) {
    return InterviewModel(
      id: json['id'] as String,
      repId: json['repId'] as String,
      status: json['status'] as String,
      town: json['town'] as String?,
      visitDate: json['visitDate'] != null
          ? DateTime.parse(json['visitDate'] as String)
          : null,
      ownerData: json['ownerData'] as Map<String, dynamic>?,
      buildingAddress: json['buildingAddress'] as Map<String, dynamic>?,
      buildingCore: json['buildingCore'] as Map<String, dynamic>?,
      heating: json['heating'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      consent: json['consent'] as bool? ?? false,
      floors: (json['floors'] as List<dynamic>?)
              ?.map((e) => FloorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repId': repId,
      'status': status,
      if (town != null) 'town': town,
      if (visitDate != null) 'visitDate': visitDate!.toIso8601String(),
      if (ownerData != null) 'ownerData': ownerData,
      if (buildingAddress != null) 'buildingAddress': buildingAddress,
      if (buildingCore != null) 'buildingCore': buildingCore,
      if (heating != null) 'heating': heating,
      if (notes != null) 'notes': notes,
      'consent': consent,
      'floors': floors.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CreateInterviewRequest {
  final String? town;
  final DateTime? visitDate;
  final Map<String, dynamic>? ownerData;
  final Map<String, dynamic>? buildingAddress;
  final Map<String, dynamic>? buildingCore;
  final Map<String, dynamic>? heating;
  final String? notes;
  final bool consent;
  final List<FloorModel> floors;

  CreateInterviewRequest({
    this.town,
    this.visitDate,
    this.ownerData,
    this.buildingAddress,
    this.buildingCore,
    this.heating,
    this.notes,
    this.consent = false,
    this.floors = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (town != null) 'town': town,
      if (visitDate != null) 'visitDate': visitDate!.toIso8601String(),
      if (ownerData != null) 'ownerData': ownerData,
      if (buildingAddress != null) 'buildingAddress': buildingAddress,
      if (buildingCore != null) 'buildingCore': buildingCore,
      if (heating != null) 'heating': heating,
      if (notes != null) 'notes': notes,
      'consent': consent,
      'floors': floors.map((e) => e.toJson()).toList(),
    };
  }
}
