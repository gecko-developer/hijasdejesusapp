import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_token_service.dart';

typedef NotificationCallback = void Function(String? title, String? body);

class FirebaseMsg {
  final msgService = FirebaseMessaging.instance;
  final FCMTokenService _tokenService = FCMTokenService();
  NotificationCallback? onNotification;

  void setNotificationCallback(NotificationCallback callback) {
    onNotification = callback;
  }

  Future<void> initFirebaseMessaging() async {
    // Request permission for iOS
    NotificationSettings settings = await msgService.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get the token and save to Firestore
    String? token = await msgService.getToken();
    print("Firebase Messaging Token: $token");
    
    // Save token to Firestore for authenticated user
    await _tokenService.saveTokenToFirestore();
    
    // Listen for token refresh
    _tokenService.listenForTokenRefresh();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground: ${message.notification?.title}');
      if (onNotification != null) {
        onNotification!(message.notification?.title, message.notification?.body);
      }
    });

    // Handle background/terminated app messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.notification?.title}');
      if (onNotification != null) {
        onNotification!(message.notification?.title, message.notification?.body);
      }
    });

    // Handle notification when app is terminated and opened from notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App launched from notification: ${initialMessage.notification?.title}');
      if (onNotification != null) {
        onNotification!(initialMessage.notification?.title, initialMessage.notification?.body);
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
