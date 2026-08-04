class QrRecord {
  final String id;
  final String name;
  final String content;
  final String type; // 'scanned' or 'generated'
  final DateTime timestamp;

  QrRecord({
    required this.id,
    required this.name,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  factory QrRecord.fromJson(Map<String, dynamic> json) => QrRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        content: json['content'] as String,
        type: json['type'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
