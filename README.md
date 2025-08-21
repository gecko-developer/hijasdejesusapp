# Flutter FCM Notification App

This app demonstrates how to receive push notifications in a Flutter app using Firebase Cloud Messaging (FCM).

## Features
- Receives push notifications from Firebase
- Displays the latest notification in the app UI
- Prints the FCM token for use with server-side notification sending

## Setup
1. **Firebase Setup**
	- Add your app to Firebase Console
	- Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
	- Configure Firebase in your Flutter project
2. **Dependencies**
	- Add to `pubspec.yaml`:
	  ```yaml
	  dependencies:
		 firebase_core: ^latest
		 firebase_messaging: ^latest
	  ```
	- Run `flutter pub get`
3. **Run the App**
	- Use `flutter run` to start the app
	- Copy the FCM token from the console for testing

## Sending Test Notifications
- Use the Firebase Console (Cloud Messaging) to send a test message to your device's FCM token.

## Project Structure
- `lib/main.dart`: App entry point and UI
- `lib/firebase_msg.dart`: FCM setup and notification handling

## Version Control
- `.gitignore` included for Flutter/Dart/IDE files

## License
MIT
