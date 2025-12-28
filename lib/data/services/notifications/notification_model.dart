import '../../../utils/formatters/formatter.dart';

class NotificationModel {
  String id; // Unique ID for the notification
  final String title; // Notification title
  final String body; // Notification body
  final String senderId; // ID of the sender (e.g., system, admin, or user)
  final List<String>
  recipientIds; // List of IDs of recipients (can be one or multiple)
  final String
  type; // Notification type (e.g., order, message, promotion, etc.)
  final DateTime createdAt; // Timestamp when notification was created
  final DateTime? seenAt; // Timestamp when the notification was seen (optional)
  final Map<String, bool> seenBy; // Tracks who has seen it {userId: true/false}
  final String route; // Route for deep linking in the app
  final String routeId; // Route for deep linking in the app
  final bool
  isBroadcast; // If it's sent to multiple recipients (true if broadcast)

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.senderId,
    required this.recipientIds,
    required this.type,
    required this.createdAt,
    this.seenAt,
    required this.seenBy,
    required this.route,
    required this.routeId,
    required this.isBroadcast,
  });

  String get formattedDate => TFormatter.formatDate(createdAt);

  factory NotificationModel.fromJson(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map.containsKey('title') ? map['title'] ?? '' : '',
      body: map.containsKey('body') ? map['body'] ?? '' : '',
      senderId: map.containsKey('senderId') ? map['senderId'] ?? '' : '',
      recipientIds:
          map.containsKey('recipientIds')
              ? List<String>.from(map['recipientIds'] ?? [])
              : [],
      type: map.containsKey('type') ? map['type'] ?? '' : '',
      createdAt:
          map.containsKey('createdAt') && map['createdAt'] != null
              ? _parseDate(map['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      // default to current time if null
      seenAt:
          map.containsKey('seenAt') && map['seenAt'] != null
              ? _parseDate(map['seenAt'])
              : null,
      seenBy:
          map.containsKey('seenBy')
              ? Map<String, bool>.from(map['seenBy'] ?? {})
              : {},
      route: map.containsKey('route') ? map['route'] ?? '' : '',
      routeId: map.containsKey('routeId') ? map['routeId'] ?? '' : '',
      isBroadcast:
          map.containsKey('isBroadcast') ? map['isBroadcast'] ?? false : false,
    );
  }

  /// Factory to create a NotificationModel from a stored map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    final id = map.containsKey('id') ? map['id'] as String : '';
    return NotificationModel.fromJson(id, map);
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.parse(v);
      if (v is Map && v.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (v['_seconds'] as int) * 1000,
        );
      }
    } catch (_) {}
    return null;
  }

  static NotificationModel empty() => NotificationModel(
    id: '',
    createdAt: DateTime.now(),
    title: '',
    type: '',
    body: '',
    isBroadcast: true,
    recipientIds: [],
    route: '',
    routeId: '',
    seenBy: {},
    senderId: '',
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'senderId': senderId,
      'recipientIds': recipientIds,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'seenAt': seenAt?.toIso8601String(),
      'seenBy': seenBy,
      'route': route,
      'routeId': routeId,
      'isBroadcast': isBroadcast,
    };
  }
}
