class QrRecord {
  final String id;
  final String name;
  final String content;
  final String type; // 'scanned' or 'generated'
  final DateTime timestamp;
  final bool isFavorite;
  final String? qrColor;     // Hex string e.g. "0xFF2563EB"
  final String? qrEyeStyle;   // 'square' or 'circle'
  final String? qrDataStyle;  // 'square' or 'circle'
  final String? logoType;     // 'none', 'link', 'text', 'wifi', 'email', 'phone'

  QrRecord({
    required this.id,
    required this.name,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isFavorite = false,
    this.qrColor,
    this.qrEyeStyle,
    this.qrDataStyle,
    this.logoType,
  });

  QrRecord copyWith({
    String? id,
    String? name,
    String? content,
    String? type,
    DateTime? timestamp,
    bool? isFavorite,
    String? qrColor,
    String? qrEyeStyle,
    String? qrDataStyle,
    String? logoType,
  }) {
    return QrRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      qrColor: qrColor ?? this.qrColor,
      qrEyeStyle: qrEyeStyle ?? this.qrEyeStyle,
      qrDataStyle: qrDataStyle ?? this.qrDataStyle,
      logoType: logoType ?? this.logoType,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'content': content,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isFavorite': isFavorite,
    'qrColor': qrColor,
    'qrEyeStyle': qrEyeStyle,
    'qrDataStyle': qrDataStyle,
    'logoType': logoType,
  };

  factory QrRecord.fromJson(Map<String, dynamic> json) => QrRecord(
    id: json['id'] as String,
    name: json['name'] as String,
    content: json['content'] as String,
    type: json['type'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    qrColor: json['qrColor'] as String?,
    qrEyeStyle: json['qrEyeStyle'] as String?,
    qrDataStyle: json['qrDataStyle'] as String?,
    logoType: json['logoType'] as String?,
  );
}
