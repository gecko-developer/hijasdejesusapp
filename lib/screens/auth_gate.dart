import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_signup_screen.dart';
import 'notification_home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('AuthGate connection state: ${snapshot.connectionState}');
        print('AuthGate has data: ${snapshot.hasData}');
        print('AuthGate error: ${snapshot.error}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Firebase...'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return LoginSignupScreen();
        }
        return NotificationHome();
      },
    );
  }
}
