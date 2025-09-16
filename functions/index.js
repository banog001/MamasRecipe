const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const recipientId = message.to; // recipient's user ID

    const userDoc = await admin.firestore().collection('Users').doc(recipientId).get();
    const token = userDoc.data() && userDoc.data().fcmToken; // use this instead of ?. for compatibility
    if (!token) return;

    const payload = {
      notification: {
        title: `New message from ${message.fromName}`,
        body: message.text,
        sound: 'default',
      },
      data: {
        chatId: message.chatId || '',
      },
    };

    return admin.messaging().sendToDevice(token, payload);
  });
