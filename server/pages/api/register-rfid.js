// pages/api/register-rfid.js
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
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

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { userId, rfidId } = req.body;

    if (!userId || !rfidId) {
      return res.status(400).json({ error: 'User ID and RFID ID are required' });
    }

    // Check if RFID card is already registered to another user
    const existingQuery = await db.collection('user_tokens')
      .where('rfidCards', 'array-contains', rfidId)
      .get();

    if (!existingQuery.empty) {
      const existingUser = existingQuery.docs[0];
      if (existingUser.id !== userId) {
        return res.status(409).json({ 
          error: 'RFID card is already registered to another user' 
        });
      }
    }

    // Add RFID card to user's array
    await db.collection('user_tokens').doc(userId).update({
      rfidCards: admin.firestore.FieldValue.arrayUnion(rfidId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(200).json({ 
      success: true,
      message: 'RFID card registered successfully'
    });

  } catch (error) {
    console.error('Error registering RFID card:', error);
    res.status(500).json({ 
      error: 'Failed to register RFID card',
      details: error.message 
    });
  }
}
