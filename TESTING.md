# RFID Test Instructions

## 🧪 Test Your RFID System

### 1. **Complete User Flow Test**

**Step 1: User Registration**
1. Run the app
2. Register a new user with email/password
3. Verify FCM token is saved to Firestore

**Step 2: Link RFID Card**
1. Navigate to RFID Link screen (credit card icon)
2. Enter RFID card in format: `F6:92:D6:05`
3. The app will auto-format it to: `CARD_F692D605`
4. Verify card is linked successfully

**Step 3: Test Notification**
```bash
# Send test notification via your server API
curl -X POST https://hijasrfid.vercel.app/api/rfid-scan \
  -H "Content-Type: application/json" \
  -d '{
    "rfidId": "CARD_F692D605",
    "title": "Access Granted",
    "message": "Welcome! Your card was scanned at the main entrance."
  }'
```

### 2. **RFID Format Testing**

Test these different input formats in your app:

| Input Format | Expected Output |
|--------------|----------------|
| `F6:92:D6:05` | `CARD_F692D605` |
| `f6-92-d6-05` | `CARD_F692D605` |
| `F692D605` | `CARD_F692D605` |
| `12345678` | `CARD_12345678` |
| `A1 B2 C3 D4` | `CARD_A1B2C3D4` |

### 3. **Server API Testing**

**Health Check:**
```bash
curl https://hijasrfid.vercel.app/api/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-08-27T...",
  "server": "RFID Notification Server",
  "version": "1.0.0",
  "endpoints": {
    "rfidScan": "/api/rfid-scan",
    "registerRfid": "/api/register-rfid",
    "health": "/api/health"
  }
}
```

### 4. **Database Verification**

Check your Firestore database for:

**Collection: `user_tokens/{userId}`**
```json
{
  "fcm_token": "actual-firebase-token",
  "user_id": "firebase-auth-user-id",
  "email": "user@example.com",
  "updated_at": "timestamp",
  "device_info": {
    "platform": "Android",
    "app_version": "1.0.0"
  },
  "rfidCards": ["CARD_F692D605"]
}
```

### 5. **Troubleshooting**

**If notifications don't work:**
1. Check if FCM token exists in Firestore
2. Verify RFID card is linked to correct user
3. Test with curl command above
4. Check Firebase Cloud Messaging logs

**If RFID linking fails:**
1. Verify user is authenticated
2. Check RFID format (must be CARD_XXXXXXXX)
3. Ensure Firestore rules allow writes

**If app crashes:**
1. Check `flutter logs` for errors
2. Verify all dependencies are installed
3. Restart the app

### 6. **Production Checklist**

- ✅ Firebase project configured
- ✅ FCM tokens saving to Firestore
- ✅ RFID cards linking successfully
- ✅ Notifications working in foreground
- ✅ Notifications working in background
- ✅ Notifications working when app is terminated
- ✅ Server API endpoints responding
- ✅ RFID format validation working
- ✅ User authentication flow complete

### 7. **Next Steps for NFC Integration**

When you're ready to add NFC scanning back:

1. Use a stable NFC package (not `nfc_manager`)
2. Try `flutter_nfc_kit` or `nfc_in_flutter`
3. Add NFC permissions to AndroidManifest.xml
4. Test on physical device with NFC capability

Your RFID notification system is now fully functional! 🎉
