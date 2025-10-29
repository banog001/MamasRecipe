const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Existing function: Send message notification
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

// New function: Create user (for admin panel)
exports.createUser = functions.https.onCall(async (data, context) => {
  // Check if request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be logged in to create users'
    );
  }

  // Verify caller is admin
  try {
    const callerDoc = await admin.firestore()
      .collection('Users')
      .doc(context.auth.uid)
      .get();

    if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can create users'
      );
    }
  } catch (error) {
    console.error('Error checking admin status:', error);
    throw new functions.https.HttpsError(
      'permission-denied',
      'Unable to verify admin permissions'
    );
  }

  // Validate input data
  if (!data.email || !data.password || !data.firstName || !data.lastName || !data.role) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: email, password, firstName, lastName, role'
    );
  }

  try {
    // Create user in Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: data.email,
      password: data.password,
      displayName: `${data.firstName} ${data.lastName}`,
      emailVerified: false,
    });

    console.log('Successfully created new user:', userRecord.uid);

    return {
      success: true,
      uid: userRecord.uid,
      message: 'User created successfully in Firebase Authentication'
    };
  } catch (error) {
    console.error('Error creating user:', error);

    // Return user-friendly error messages
    let errorMessage = error.message;
    if (error.code === 'auth/email-already-exists') {
      errorMessage = 'The email address is already in use';
    } else if (error.code === 'auth/invalid-email') {
      errorMessage = 'The email address is invalid';
    } else if (error.code === 'auth/weak-password') {
      errorMessage = 'The password is too weak';
    }

    throw new functions.https.HttpsError('internal', errorMessage);
  }
});