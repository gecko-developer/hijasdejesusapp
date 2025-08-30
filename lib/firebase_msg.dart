import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_token_service.dart';
import 'services/notification_service.dart';

typedef NotificationCallback = void Function(String? title, String? body);

class FirebaseMsg {
  final msgService = FirebaseMessaging.instance;
  final FCMTokenService _tokenService = FCMTokenService();
  final NotificationService _notificationService = NotificationService();
  NotificationCallback? onNotification;

  void setNotificationCallback(NotificationCallback callback) {
    onNotification = callback;
  }

  Future<void> initFirebaseMessaging() async {
    // Only initializes FCM after user authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ No authenticated user, skipping FCM initialization');
      return;
    }

    // Request permission for iOS
    NotificationSettings settings = await msgService.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted FCM permission');
    } else {
      print('❌ User declined FCM permission');
      return; // Gracefully exit if no permission
    }

    // Get the token and save to Firestore
    String? token = await msgService.getToken();
    print("Firebase Messaging Token: $token");
    
    // Save token to Firestore for authenticated user
    await _tokenService.saveTokenToFirestore();
    
    // Listen for token refresh
    _tokenService.listenForTokenRefresh();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Received a message in the foreground: ${message.notification?.title}');
      
      // Save notification to Firestore for persistence
      final title = message.notification?.title ?? 'RFID Notification';
      final body = message.notification?.body ?? 'Your RFID card was scanned';
      
      await _notificationService.saveNotification(
        title: title,
        body: body,
        type: 'rfid_scan',
      );

      if (onNotification != null) {
        onNotification!(title, body);
      }
    });

    // Handle background/terminated app messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('App opened from notification: ${message.notification?.title}');
      
      // Save notification if not already saved
      final title = message.notification?.title ?? 'RFID Notification';
      final body = message.notification?.body ?? 'Your RFID card was scanned';
      
      await _notificationService.saveNotification(
        title: title,
        body: body,
        type: 'rfid_scan',
      );

      if (onNotification != null) {
        onNotification!(title, body);
      }
    });

    // Handle notification when app is terminated and opened from notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App launched from notification: ${initialMessage.notification?.title}');
      
      // Save notification if not already saved
      final title = initialMessage.notification?.title ?? 'RFID Notification';
      final body = initialMessage.notification?.body ?? 'Your RFID card was scanned';
      
      await _notificationService.saveNotification(
        title: title,
        body: body,
        type: 'rfid_scan',
      );

      if (onNotification != null) {
        onNotification!(title, body);
      }
    }
  }

  Future<void> linkRFIDCard(String rfidId) async {
    await _tokenService.linkRFIDCard(rfidId);
  }

  Future<void> logout() async {
    await _tokenService.removeTokenFromFirestore();
  }
}
