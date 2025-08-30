// pages/api/rfid-scan.js
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  // You'll need to add your Firebase Admin SDK credentials here
  admin.initializeApp({
    credential: admin.credential.cert({
      // Add your Firebase Admin SDK credentials
      projectId: "your-project-id",
      clientEmail: "your-client-email",
      privateKey: "your-private-key"
    }),
    projectId: "your-project-id"
  });
}

const db = admin.firestore();
const messaging = admin.messaging();

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { rfidId, message, title } = req.body;

    if (!rfidId) {
      return res.status(400).json({ error: 'RFID ID is required' });
    }

    // Find user associated with this RFID card
    const userQuery = await db.collection('user_tokens')
      .where('rfidCards', 'array-contains', rfidId)
      .get();

    if (userQuery.empty) {
      return res.status(404).json({ error: 'No user found for this RFID card' });
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();
    const fcmToken = userData.fcm_token;

    if (!fcmToken) {
      return res.status(404).json({ error: 'No FCM token found for user' });
    }

    // Send notification
    const notificationMessage = {
      token: fcmToken,
      notification: {
        title: title || 'RFID Card Scanned',
        body: message || `RFID card ${rfidId} was scanned`,
      },
      data: {
        rfidId: rfidId,
        timestamp: new Date().toISOString(),
      }
    };

    const response = await messaging.send(notificationMessage);
    
    // Log the scan event
    await db.collection('rfidScans').add({
      rfidId,
      userId: userDoc.id,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      notificationSent: true,
      messageId: response
    });

    res.status(200).json({ 
      success: true, 
      messageId: response,
      message: 'Notification sent successfully' 
    });

  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ 
      error: 'Failed to send notification',
      details: error.message 
    });
  }
}
