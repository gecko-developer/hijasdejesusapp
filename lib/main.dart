import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// Background message handler for when app is terminated
/// 🔒 SECURITY: Saves to user-specific Firestore collection based on FCM token
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('🔥 Background message received: ${message.notification?.title}');
  
  // 🔒 SECURITY: NotificationService automatically uses authenticated user's UID
  // The FCM message is already targeted to specific user, so this is user-isolated
  final notificationService = NotificationService();
  await notificationService.saveNotification(
    title: message.notification?.title ?? 'RFID Notification',
    body: message.notification?.body ?? 'Your RFID card was scanned',
    type: 'rfid_scan',
  );
  
  print('✅ Background notification saved to user-specific Firestore collection');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Starting Firebase initialization...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
    print('Firebase initialized successfully!');
    
    // Set background message handler for terminated app
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Background message handler registered');
    
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'RFID Notification System',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.system,
        home: AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
