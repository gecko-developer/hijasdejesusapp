class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  // Create NotificationItem from Map (Firestore data)
  factory NotificationItem.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationItem(
      id: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      time: map['timestamp']?.toDate() ?? DateTime.now(),
      isRead: map['read'] ?? false,
    );
  }

  // Convert NotificationItem to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': time,
      'read': isRead,
    };
  }

  // Create a copy with updated values
  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'NotificationItem(id: $id, title: $title, body: $body, time: $time, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationItem &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.time == time &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        body.hashCode ^
        time.hashCode ^
        isRead.hashCode;
  }
}
