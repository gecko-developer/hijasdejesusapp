# RFID Notification System

## Server Setup

1. Navigate to the server directory:
```bash
cd server
```

2. Install dependencies:
```bash
npm install
```

3. Set up Firebase Admin SDK:
   - Go to Firebase Console → Project Settings → Service Accounts
   - Generate a new private key
   - Replace the credentials in the API files

4. Start the server:
```bash
npm run dev
```

## API Endpoints

### POST /api/rfid-scan
Triggered when an RFID card is scanned. Sends notification to the associated user.

**Body:**
```json
{
  "rfidId": "your-rfid-card-id",
  "title": "Optional notification title",
  "message": "Optional notification message"
}
```

### POST /api/register-rfid  
Register an RFID card to a user account.

**Body:**
```json
{
  "userId": "firebase-user-id",
  "rfidId": "rfid-card-id"
}
```

## Flutter App Integration

The Flutter app now:
- Saves FCM tokens to Firestore when users register/login
- Links RFID cards to user accounts
- Displays notifications when RFID cards are scanned

## Firestore Structure

```
user_tokens/{userId}
├── fcm_token: string
├── user_id: string
├── email: string
├── updated_at: timestamp
├── device_info: object
│   ├── platform: "Android" | "iOS"
│   └── app_version: string
└── rfidCards: array of strings

rfidScans/{scanId}
├── rfidId: string
├── userId: string
├── timestamp: timestamp
├── notificationSent: boolean
└── messageId: string
```

## Usage Flow

1. User registers/logs in → FCM token saved
2. User links RFID card via app
3. RFID scanner sends POST to `/api/rfid-scan`
4. Server finds user by RFID → sends notification
5. User receives notification on their phone
