import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'rfid_service.dart';

class FCMTokenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RFIDService _rfidService = RFIDService();

  Future<void> saveTokenToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // First, remove this token from any other user who might have it
        await _removeTokenFromOtherUsers(token, user.uid);
        
        // Then save it to the current user
        await _firestore.collection('user_tokens').doc(user.uid).set({
          'fcm_token': token,
          'user_id': user.uid,
          'email': user.email,
          'updated_at': FieldValue.serverTimestamp(),
          'device_info': {
            'platform': Platform.isAndroid ? 'Android' : 'iOS',
            'app_version': '1.0.0',
          }
        }, SetOptions(merge: true));
        
        print('✅ FCM token saved to Firestore for user: ${user.email}');
      }
    } catch (e) {
      print('❌ Error saving token to Firestore: $e');
    }
  }

  Future<void> _removeTokenFromOtherUsers(String token, String currentUserId) async {
    try {
      // Find all users who have this token
      final query = await _firestore.collection('user_tokens')
          .where('fcm_token', isEqualTo: token)
          .get();

      // Remove the token from users who are not the current user
      for (final doc in query.docs) {
        if (doc.id != currentUserId) {
          await doc.reference.update({
            'fcm_token': FieldValue.delete(),
          });
          print('🔄 Removed token from previous user: ${doc.data()['email']}');
        }
      }
    } catch (e) {
      print('❌ Error removing token from other users: $e');
    }
  }

  Future<void> linkRFIDCard(String rfidId) async {
    // Delegate to RFIDService which enforces one card per user
    await _rfidService.linkRFIDCard(rfidId);
  }

  void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM token refreshed');
      saveTokenToFirestore();
    });
  }

  Future<void> removeTokenFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Remove the FCM token from the current user's document
      await _firestore.collection('user_tokens').doc(user.uid).update({
        'fcm_token': FieldValue.delete(),
        'logged_out_at': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token removed from Firestore for user: ${user.email}');
    } catch (e) {
      print('❌ Error removing token: $e');
    }
  }
}
