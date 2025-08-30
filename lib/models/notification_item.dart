import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String? id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final String type;

  NotificationItem({
    this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    this.type = 'rfid_scan',
  });

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'timestamp': time,
      'read': isRead,
      'type': type,
    };
  }

  // Create from Firestore data
  factory NotificationItem.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationItem(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      time: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['read'] ?? false,
      type: data['type'] ?? 'rfid_scan',
    );
  }

  // Copy with changes
  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? time,
    bool? isRead,
    String? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
