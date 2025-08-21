import 'package:empty/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_msg.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options:DefaultFirebaseOptions.currentPlatform

  );

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _notification = 'No notifications yet.';
  final FirebaseMsg _firebaseMsg = FirebaseMsg();

  @override
  void initState() {
    super.initState();
    _firebaseMsg.setNotificationCallback((title, body) {
      setState(() {
        _notification = '${title ?? 'No title'}: ${body ?? 'No body'}';
      });
    });
    _firebaseMsg.initFirebaseMessaging();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FCM Notification Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Latest notification:'),
              Text(_notification),
            ],
          ),
        ),
      ),
    );
  }
}
