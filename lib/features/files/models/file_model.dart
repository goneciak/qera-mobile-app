enum FileKind {
  photo('PHOTO'),
  document('DOCUMENT'),
  signature('SIGNATURE');

  final String value;
  const FileKind(this.value);

  static FileKind fromString(String value) {
    return FileKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => FileKind.photo,
    );
  }

  String get displayName {
    switch (this) {
      case FileKind.photo:
        return 'Zdjęcie';
      case FileKind.document:
        return 'Dokument';
      case FileKind.signature:
        return 'Podpis';
    }
  }
}

class FileModel {
  final String id;
  final String repId;
  final String? interviewId;
  final String? offerId;
  final FileKind kind;
  final String storageKey;
  final String mime;
  final int size;
  final int? width;
  final int? height;
  final String hash;
  final DateTime createdAt;

  FileModel({
    required this.id,
    required this.repId,
    this.interviewId,
    this.offerId,
    required this.kind,
    required this.storageKey,
    required this.mime,
    required this.size,
    this.width,
    this.height,
    required this.hash,
    required this.createdAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] as String,
      repId: json['repId'] as String,
      interviewId: json['interviewId'] as String?,
      offerId: json['offerId'] as String?,
      kind: FileKind.fromString(json['kind'] as String),
      storageKey: json['storageKey'] as String,
      mime: json['mime'] as String,
      size: json['size'] as int,
      width: json['width'] as int?,
      height: json['height'] as int?,
      hash: json['hash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repId': repId,
      'interviewId': interviewId,
      'offerId': offerId,
      'kind': kind.value,
      'storageKey': storageKey,
      'mime': mime,
      'size': size,
      'width': width,
      'height': height,
      'hash': hash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get sizeFormatted {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  bool get isImage => mime.startsWith('image/');
}

class FileWithUrl {
  final FileModel file;
  final String url;

  FileWithUrl({
    required this.file,
    required this.url,
  });

  factory FileWithUrl.fromJson(Map<String, dynamic> json) {
    return FileWithUrl(
      file: FileModel.fromJson(json['file'] as Map<String, dynamic>),
      url: json['url'] as String,
    );
  }
}
