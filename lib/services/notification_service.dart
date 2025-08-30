import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save notification to Firestore
  Future<void> saveNotification(NotificationItem notification) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('user_notifications')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': notification.title,
        'body': notification.body,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'rfid_scan',
      });
      print('✅ Notification saved to Firestore');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // Get all notifications for current user
  Stream<List<NotificationItem>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('user_notifications')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          id: doc.id,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          time: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['read'] ?? false,
        );
      }).toList();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('user_notifications')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('user_notifications')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('user_notifications')
          .doc(user.uid)
          .collection('notifications')
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ All notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }
}