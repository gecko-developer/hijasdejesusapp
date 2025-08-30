class FirebaseMsg {
  final msgService = FirebaseMessaging.instance;

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

    // Get the token
    String? token = await msgService.getToken();
    print("Firebase Messaging Token: $token");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground: ${message.notification?.title}');
    });
  }
}
