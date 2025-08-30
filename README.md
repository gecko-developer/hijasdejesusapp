# 🏢 Hijas de Jesus RFID Notification App

A comprehensive Flutter application for RFID card management, push notifications, and user authentication built for the Hijas de Jesus organization.

## 📱 What This App Does

This is a multi-platform Flutter application that provides:

- **🔐 User Authentication**: Secure login/signup with Firebase Auth
- **🎯 RFID Card Management**: Link and manage RFID cards for users
- **📢 Push Notifications**: Real-time notifications via Firebase Cloud Messaging (FCM)
- **📱 NFC Integration**: Scan RFID cards using device NFC capabilities
- **📊 Notification History**: View and manage notification history
- **🎨 Modern UI**: Material Design 3 with professional animations
- **🔒 Security**: Secure configuration management and data protection

## 🚀 Key Features

### Authentication & User Management
- Email/password authentication via Firebase
- User profile management
- Secure session handling

### RFID Functionality
- Link RFID cards to user accounts
- NFC scanning for card reading
- Manual RFID ID entry option
- Card unlinking capabilities

### Notification System
- Real-time push notifications
- Notification history with timestamps
- Custom notification handling
- Background notification processing

### Cross-Platform Support
- Android (primary target)
- iOS
- Web
- Windows
- macOS
- Linux

## 🛠️ Setup Instructions

### Prerequisites

Before you start, ensure you have:

- **Flutter SDK**: Version 3.9.0 or higher
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control
- **Firebase CLI** (optional, for advanced Firebase management)

### 1. Clone the Repository

```bash
git clone https://github.com/gecko-developer/hijasdejesusapp.git
cd hijasdejesusapp
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

#### 🔥 Firebase Project Setup

This app uses the **hijasdejesusnotif** Firebase project. You'll need:

**Project Details:**
- **Project ID**: `hijasdejesusnotif`
- **Project Number**: `575931048789`
- **Web API Key**: `AIzaSyAq3MaYem2mO2WLusFHf6PsbXj8fYfGVwo`

#### Required Firebase Services

Enable these services in the Firebase Console:

1. **Authentication**
   - Email/Password provider
   - Configure authorized domains

2. **Cloud Firestore**
   - Set up security rules (see `firestore.rules`)
   - Initialize database

3. **Cloud Messaging (FCM)**
   - Enable push notifications
   - Configure sender credentials

4. **Storage** (if needed for future features)

#### Configuration Files Setup

**⚠️ IMPORTANT**: Never commit actual Firebase config files to version control!

1. **Android Configuration**:
   ```bash
   # Copy template and fill with actual values
   cp android/app/google-services-template.json android/app/google-services.json
   # Edit google-services.json with your Firebase project details
   ```

2. **Firebase Options**:
   ```bash
   # Copy template and configure
   cp lib/firebase_options_template.dart lib/firebase_options.dart
   # Update lib/firebase_options.dart with your project configuration
   ```

3. **Environment Variables** (optional):
   ```bash
   # Copy template and configure
   cp .env.template .env
   # Add any additional environment variables
   ```

#### Firebase Configuration Template

Your `lib/firebase_options.dart` should look like this:

```dart
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '575931048789',
    projectId: 'hijasdejesusnotif',
    // ... other web config
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: '575931048789',
    projectId: 'hijasdejesusnotif',
    // ... other android config
  );

  // ... iOS, macOS, Windows configurations
}
```

### 4. Android Setup

#### Permissions
The app requires these permissions (already configured in `AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

#### Build Configuration
Minimum SDK version: 21 (Android 5.0)

### 5. iOS Setup (if targeting iOS)

1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Configure iOS permissions in `Info.plist`
3. Set minimum iOS version to 11.0

### 6. Development vs Production

#### Development Build
```bash
flutter run -d android
# or
flutter run -d ios
```

#### Production Build
```bash
# Android APK
flutter build apk --release --dart-define=FIREBASE_PROJECT_ID="hijasdejesusnotif" --dart-define=PRODUCTION=true

# Android App Bundle
flutter build appbundle --release --dart-define=FIREBASE_PROJECT_ID="hijasdejesusnotif" --dart-define=PRODUCTION=true
```

## 📦 Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_messaging: ^14.7.10
  cloud_firestore: ^4.13.6
  
  # UI & Animations
  flutter_animate: ^4.5.0
  
  # NFC & Hardware
  nfc_manager: ^3.3.0
  
  # Utilities
  intl: ^0.19.0
  
  # Platform Integration
  cupertino_icons: ^1.0.2
```

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/                      # Data models
│   ├── notification_item.dart
│   └── user_model.dart
├── screens/                     # UI screens
│   ├── auth_gate.dart          # Authentication wrapper
│   ├── login_signup_screen.dart # Auth screen
│   ├── notification_home.dart   # Main dashboard
│   ├── notification_history_screen.dart
│   └── rfid_link_screen.dart   # RFID management
├── services/                    # Business logic
│   ├── fcm_token_service.dart  # FCM token management
│   ├── nfc_service.dart        # NFC functionality
│   ├── notification_service.dart
│   ├── rfid_service.dart
│   └── user_service.dart
├── theme/                       # App theming
│   └── app_theme.dart          # Material Design 3 theme
└── widgets/                     # Reusable components
    ├── logout_dialog.dart      # Modern logout dialog
    └── status_chip.dart        # Status indicators
```

## 🔧 Configuration Files

### Security Templates
- `.env.template` - Environment variables template
- `android/app/google-services-template.json` - Firebase Android config template
- `lib/firebase_options_template.dart` - Firebase options template

### Build Scripts
- `scripts/build_secure.bat` - Windows secure build script
- `scripts/build_secure.sh` - Unix secure build script
- `scripts/security_check.sh` - Security validation script

## 🔒 Security Best Practices

### File Security
The following files contain sensitive information and should NEVER be committed:

```
# Never commit these files:
google-services.json
firebase_options.dart
.env
service-account-key.json
*.json.backup
```

### Environment Variables
Use the `.env` file for sensitive configuration:

```env
FIREBASE_PROJECT_ID=hijasdejesusnotif
FIREBASE_API_KEY=your_api_key_here
# Add other sensitive keys as needed
```

### Build Security
Always use the secure build scripts for production:

```bash
# Windows
scripts/build_secure.bat

# Unix/Linux/macOS
./scripts/build_secure.sh
```

## 🚀 Development Workflow

### 1. Initial Setup
```bash
# Clone repo
git clone https://github.com/gecko-developer/hijasdejesusapp.git
cd hijasdejesusapp

# Install dependencies
flutter pub get

# Set up Firebase config files (copy from templates)
cp android/app/google-services-template.json android/app/google-services.json
cp lib/firebase_options_template.dart lib/firebase_options.dart
# Edit the files with actual Firebase config
```

### 2. Daily Development
```bash
# Pull latest changes
git pull origin master

# Run app in development
flutter run -d android

# Hot reload is enabled - just save files to see changes
```

### 3. Testing
```bash
# Run tests
flutter test

# Run security check
./scripts/security_check.sh

# Test notifications using Firebase Console
```

### 4. Production Deployment
```bash
# Build for production
./scripts/build_secure.sh

# The APK will be in build/app/outputs/flutter-apk/
```

## 📱 Testing the App

### 1. Authentication Testing
- Create test accounts with email/password
- Test login/logout functionality
- Verify user session persistence

### 2. RFID Testing
- Use NFC-enabled device for card scanning
- Test manual RFID ID entry
- Verify card linking/unlinking

### 3. Notification Testing
- Use Firebase Console to send test notifications
- Test foreground/background notification handling
- Verify notification history

### 4. FCM Token Testing
```bash
# The app logs FCM tokens to console
# Copy token and use in Firebase Console for testing
```

## 🔧 Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk
```

#### Firebase Connection Issues
- Verify `google-services.json` is in `android/app/`
- Check Firebase project configuration
- Ensure all required Firebase services are enabled

#### NFC Issues
- Test on physical device (NFC doesn't work in emulator)
- Verify NFC is enabled in device settings
- Check NFC permissions in app settings

#### Notification Issues
- Test in release mode (debug mode may have limitations)
- Check device notification permissions
- Verify FCM token generation

### Debug Commands
```bash
# Check Flutter doctor
flutter doctor

# Run with verbose logging
flutter run --verbose

# Check device logs
flutter logs
```

## 🤝 Contributing

### Development Guidelines

1. **Code Style**: Follow Dart/Flutter conventions
2. **Commits**: Use conventional commit messages
3. **Security**: Never commit sensitive files
4. **Testing**: Test on both Android and iOS
5. **Documentation**: Update README for new features

### Conventional Commits
```
feat: add new RFID scanning feature
fix: resolve notification display issue
docs: update Firebase setup instructions
style: improve logout dialog UI
refactor: reorganize service classes
test: add notification service tests
```

## 📄 License

This project is proprietary software developed for Hijas de Jesus organization.

## 📞 Support

For technical support or questions:

1. Check this README first
2. Review existing GitHub issues
3. Create a new issue with detailed description
4. Include device logs and error messages

---

## 🎯 Quick Start Checklist

- [ ] Clone repository
- [ ] Install Flutter dependencies (`flutter pub get`)
- [ ] Set up Firebase configuration files
- [ ] Configure Android permissions
- [ ] Test authentication flow
- [ ] Test RFID functionality
- [ ] Test push notifications
- [ ] Build for production

**Happy coding! 🚀**

by: Ryan Angelo Abapo & AI