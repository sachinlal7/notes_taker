import 'dart:convert';

class SocketMessage {
  const SocketMessage({
    required this.event,
    required this.payload,
    this.id,
    this.sentAt,
  });

  final String event;
  final Map<String, dynamic> payload;
  final String? id;
  final DateTime? sentAt;

  bool get isValid => event.trim().isNotEmpty;

  T? payloadValue<T>(String key) {
    final value = payload[key];
    if (value is T) return value;

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      'event': event.trim(),
      'payload': payload,
      if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
    };
  }

  String encode() {
    return jsonEncode(toJson());
  }

  static SocketMessage? tryParse(dynamic rawMessage) {
    try {
      final decodedMessage = rawMessage is String
          ? jsonDecode(rawMessage)
          : rawMessage;

      if (decodedMessage is! Map<String, dynamic>) return null;

      return fromJson(decodedMessage);
    } on FormatException {
      return null;
    }
  }

  static SocketMessage? fromJson(Map<String, dynamic> json) {
    final event = json['event'];
    final payload = json['payload'];

    if (event is! String || event.trim().isEmpty) return null;
    if (payload is! Map<String, dynamic>) return null;

    return SocketMessage(
      id: json['id'] is String ? json['id'] as String : null,
      event: event.trim(),
      payload: payload,
      sentAt: _parseDateTime(json['sentAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;

    return DateTime.tryParse(value);
  }
}
