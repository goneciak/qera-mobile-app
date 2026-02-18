enum FloorType {
  basement('BASEMENT', 'Piwnica'),
  semiBasement('SEMI_BASEMENT', 'Suterena'),
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

class RoomModel {
  final String id;
  final String name;
  final double area;
  final bool heated;
  final WindowOverride? windowOverride;
  final String? notes;

  RoomModel({
    required this.id,
    required this.name,
    required this.area,
    required this.heated,
    this.windowOverride,
    this.notes,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      area: (json['area'] as num).toDouble(),
      heated: json['heated'] as bool,
      windowOverride: json['windowOverrides'] != null
          ? WindowOverride.fromJson(json['windowOverrides'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'name': name,
      'area': area,
      'heated': heated,
    };
    
    // Backend wymaga obiektu (nie null) dla windowOverrides
    if (windowOverride != null) {
      json['windowOverrides'] = windowOverride!.toJson();
    } else {
      // Puste obiekty zamiast null
      json['windowOverrides'] = {};
    }
    
    // Backend wymaga stringa (nie null) dla notes
    json['notes'] = notes ?? '';
    
    return json;
  }

  RoomModel copyWith({
    String? id,
    String? name,
    double? area,
    bool? heated,
    WindowOverride? windowOverride,
    String? notes,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      heated: heated ?? this.heated,
      windowOverride: windowOverride ?? this.windowOverride,
      notes: notes ?? this.notes,
    );
  }
}

class WindowOverride {
  final String? glassType;
  final int? year;
  final int? count;
  final double? totalArea;
  final int? balconyWindows;
  final int? largeWindows;

  WindowOverride({
    this.glassType,
    this.year,
    this.count,
    this.totalArea,
    this.balconyWindows,
    this.largeWindows,
  });

  factory WindowOverride.fromJson(Map<String, dynamic> json) {
    return WindowOverride(
      glassType: json['glassType'] as String?,
      year: json['year'] as int?,
      count: json['count'] as int?,
      totalArea: json['totalArea'] != null ? (json['totalArea'] as num).toDouble() : null,
      balconyWindows: json['balconyWindows'] as int?,
      largeWindows: json['largeWindows'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'glassType': glassType,
      'year': year,
      'count': count,
      'totalArea': totalArea,
      'balconyWindows': balconyWindows,
      'largeWindows': largeWindows,
    };
  }
}

class FloorModel {
  final String id;
  final FloorType type;
  final double area;
  final double height;
  final Map<String, dynamic>? structure;
  final List<RoomModel> rooms;

  FloorModel({
    required this.id,
    required this.type,
    required this.area,
    required this.height,
    this.structure,
    this.rooms = const [],
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] as String,
      type: FloorType.fromString(json['type'] as String),
      area: (json['area'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      structure: json['structure'] as Map<String, dynamic>?,
      rooms: (json['rooms'] as List?)
              ?.map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'area': area,
      'height': height,
      'structure': structure,
      'rooms': rooms.map((r) => r.toJson()).toList(),
    };
  }

  int get heatedRoomsCount => rooms.where((r) => r.heated).length;
  double get heatedArea => rooms.where((r) => r.heated).fold(0.0, (sum, r) => sum + r.area);
  double get totalRoomsArea => rooms.fold(0.0, (sum, r) => sum + r.area);

  FloorModel copyWith({
    String? id,
    FloorType? type,
    double? area,
    double? height,
    Map<String, dynamic>? structure,
    List<RoomModel>? rooms,
  }) {
    return FloorModel(
      id: id ?? this.id,
      type: type ?? this.type,
      area: area ?? this.area,
      height: height ?? this.height,
      structure: structure ?? this.structure,
      rooms: rooms ?? this.rooms,
    );
  }
}
