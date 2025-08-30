import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_item.dart';

/// NotificationService provides complete user isolation for notifications
/// 
/// 🔒 SECURITY: Each user's notifications are stored in separate Firestore subcollections
/// Structure: user_notifications/{userId}/notifications/{notificationId}
/// 
/// ✅ NO CROSS-USER ACCESS: Users can only see their own notifications
/// ✅ NO SHARING: Notifications are never shared between users
/// ✅ DEVICE INDEPENDENT: Same user gets same notifications on any device
/// ✅ MULTI-USER SAFE: Multiple users on same device have separate data
class NotificationService {
  static const String _collection = 'user_notifications';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID with null safety
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Validate user authentication before any operation
  bool _isUserAuthenticated() {
    final userId = _currentUserId;
    if (userId == null) {
      print('❌ SECURITY: No authenticated user - operation blocked');
      return false;
    }
    print('🔒 SECURITY: User authenticated - UID: ${userId.substring(0, 8)}...');
    return true;
  }

  /// Save notification to Firestore with strict user isolation
  Future<String?> saveNotification({
    required String title,
    required String body,
    String type = 'rfid_scan',
    DateTime? time,
  }) async {
    if (!_isUserAuthenticated()) return null;
    
    final userId = _currentUserId!;

    try {
      final notification = NotificationItem(
        title: title,
        body: body,
        time: time ?? DateTime.now(),
        type: type,
        isRead: false,
      );

      // 🔒 SECURITY: Save to user-specific subcollection
      final docRef = await _firestore
          .collection(_collection)
          .doc(userId)  // USER ISOLATION: Each user has their own document
          .collection('notifications')  // USER ISOLATION: Each user has their own subcollection
          .add(notification.toFirestore());

      print('✅ Notification saved for user ${userId.substring(0, 8)}...: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error saving notification for user ${userId.substring(0, 8)}...: $e');
      return null;
    }
  }

  /// Legacy method for backward compatibility
  Future<void> saveNotificationItem(NotificationItem notification) async {
    await saveNotification(
      title: notification.title,
      body: notification.body,
      type: notification.type,
      time: notification.time,
    );
  }

  /// Get all notifications for current user ONLY - strict user isolation
  Stream<List<NotificationItem>> getNotifications() {
    if (!_isUserAuthenticated()) return Stream.value([]);
    
    final userId = _currentUserId!;

    // 🔒 SECURITY: Query only the current user's notifications
    return _firestore
        .collection(_collection)
        .doc(userId)  // USER ISOLATION: Only this user's document
        .collection('notifications')  // USER ISOLATION: Only this user's notifications
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print('🔒 Loaded ${snapshot.docs.length} notifications for user ${userId.substring(0, 8)}...');
      return snapshot.docs.map((doc) {
        return NotificationItem.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get unread notification count for current user ONLY
  Stream<int> getUnreadCountStream() {
    if (!_isUserAuthenticated()) return Stream.value(0);
    
    final userId = _currentUserId!;

    // 🔒 SECURITY: Count only the current user's unread notifications
    return _firestore
        .collection(_collection)
        .doc(userId)  // USER ISOLATION: Only this user's document
        .collection('notifications')  // USER ISOLATION: Only this user's notifications
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get notifications grouped by date for current user ONLY
  Future<Map<String, List<NotificationItem>>> getNotificationsGroupedByDate() async {
    try {
      if (!_isUserAuthenticated()) return {};
      
      final userId = _currentUserId!;

      // 🔒 SECURITY: Query only the current user's notifications
      final snapshot = await _firestore
          .collection(_collection)
          .doc(userId)  // USER ISOLATION: Only this user's document
          .collection('notifications')  // USER ISOLATION: Only this user's notifications
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final notifications = snapshot.docs.map((doc) {
        return NotificationItem.fromFirestore(doc.data(), doc.id);
      }).toList();

      final Map<String, List<NotificationItem>> grouped = {};

      for (var notification in notifications) {
        final dateKey = _formatDateKey(notification.time);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(notification);
      }

      print('🔒 Grouped ${notifications.length} notifications for user ${userId.substring(0, 8)}...');
      return grouped;
    } catch (e) {
      print('❌ Error grouping notifications by date: $e');
      return {};
    }
  }

  /// Mark notification as read for current user ONLY
  Future<void> markAsRead(String notificationId) async {
    if (!_isUserAuthenticated()) return;
    
    final userId = _currentUserId!;

    try {
      // 🔒 SECURITY: Update only within current user's notifications
      await _firestore
          .collection(_collection)
          .doc(userId)  // USER ISOLATION: Only this user's document
          .collection('notifications')  // USER ISOLATION: Only this user's notifications
          .doc(notificationId)
          .update({'read': true});
      print('✅ Notification marked as read for user ${userId.substring(0, 8)}...: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read for user ${userId.substring(0, 8)}...: $e');
    }
  }

  /// Mark all notifications as read for current user ONLY
  Future<void> markAllAsRead() async {
    if (!_isUserAuthenticated()) return;
    
    final userId = _currentUserId!;

    try {
      final batch = _firestore.batch();
      
      // 🔒 SECURITY: Query only current user's unread notifications
      final snapshot = await _firestore
          .collection(_collection)
          .doc(userId)  // USER ISOLATION: Only this user's document
          .collection('notifications')  // USER ISOLATION: Only this user's notifications
          .where('read', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      print('✅ All notifications marked as read for user ${userId.substring(0, 8)}...');
    } catch (e) {
      print('❌ Error marking all notifications as read for user ${userId.substring(0, 8)}...: $e');
    }
  }

  /// Delete notification for current user ONLY
  Future<void> deleteNotification(String notificationId) async {
    if (!_isUserAuthenticated()) return;
    
    final userId = _currentUserId!;

    try {
      // 🔒 SECURITY: Delete only from current user's notifications
      await _firestore
          .collection(_collection)
          .doc(userId)  // USER ISOLATION: Only this user's document
          .collection('notifications')  // USER ISOLATION: Only this user's notifications
          .doc(notificationId)
          .delete();
      print('✅ Notification deleted for user ${userId.substring(0, 8)}...: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification for user ${userId.substring(0, 8)}...: $e');
    }
  }

  /// Clear all notifications for current user ONLY
  Future<void> clearAllNotifications() async {
    if (!_isUserAuthenticated()) return;
    
    final userId = _currentUserId!;

    try {
      final batch = _firestore.batch();
      
      // 🔒 SECURITY: Query only current user's notifications
      final notifications = await _firestore
          .collection(_collection)
          .doc(userId)  // USER ISOLATION: Only this user's document
          .collection('notifications')  // USER ISOLATION: Only this user's notifications
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ All notifications cleared for user ${userId.substring(0, 8)}...');
    } catch (e) {
      print('❌ Error clearing notifications for user ${userId.substring(0, 8)}...: $e');
    }
  }

  /// Format date for grouping (e.g., "Today", "Yesterday", "Jan 15, 2025")
  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  /// Format time for display (e.g., "2:30 PM")
  String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    
    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }
}