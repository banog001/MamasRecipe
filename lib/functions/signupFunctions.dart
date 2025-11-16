import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class SignupFunctions {
  // ==================== MARK USER AS VERIFIED ====================
  static Future<void> markUserAsVerified(User user, String firstName, String lastName) async {
    final firestore = FirebaseFirestore.instance;
    final notVerRef = firestore.collection('notVerifiedUsers').doc(user.uid);
    final verifiedRef = firestore.collection('verifiedUsers').doc(user.uid);

    final snap = await notVerRef.get();

    final Map<String, dynamic> data = {
      if (snap.exists) ...snap.data()!,
      'email': user.email,
      'emailVerified': true,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password',
      'verifiedAt': FieldValue.serverTimestamp(),
    };

    data.remove('password');

    if ((data['firstName'] == null || (data['firstName'] as String).isEmpty)) {
      data['firstName'] = firstName.isNotEmpty ? firstName : '';
    }
    if ((data['lastName'] == null || (data['lastName'] as String).isEmpty)) {
      data['lastName'] = lastName.isNotEmpty ? lastName : '';
    }

    await verifiedRef.set(data, SetOptions(merge: true));

    try {
      await notVerRef.delete();
    } catch (_) {}
  }

  // ==================== START AUTO VERIFICATION CHECK ====================
  static Timer startAutoVerificationCheck(User user, Function(bool) onVerified) {
    return Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;

        if (refreshed != null && refreshed.emailVerified) {
          print('✅ Email verified automatically detected!');
          timer.cancel();
          onVerified(true);
        }
      } catch (e) {
        print('⚠️ Error checking verification status: $e');
      }
    });
  }

  // ==================== TRY VERIFY MANUALLY ====================
  static Future<bool> tryVerifyManually(User user) async {
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    return refreshed != null && refreshed.emailVerified;
  }

  // ==================== ENSURE VERIFIED USERS DOC FOR GOOGLE ====================
  static Future<void> ensureVerifiedUsersDocForGoogle(User user) async {
    final verifiedRef =
    FirebaseFirestore.instance.collection('verifiedUsers').doc(user.uid);
    final exists = await verifiedRef.get();

    if (!exists.exists) {
      final dn = user.displayName ?? '';
      final first = dn.isNotEmpty ? dn.split(' ').first : '';
      final last = dn.contains(' ') ? dn.split(' ').sublist(1).join(' ') : '';

      await verifiedRef.set({
        'email': user.email,
        'firstName': first,
        'lastName': last,
        'provider': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'google.com',
        'emailVerified': user.emailVerified,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      await FirebaseFirestore.instance
          .collection('notVerifiedUsers')
          .doc(user.uid)
          .delete();
    } catch (_) {}
  }

  // ==================== REGISTER USER ====================
  static Future<User?> registerUser(
      String email,
      String password,
      String firstName,
      String lastName,
      ) async {
    print('🔵 Creating user account for: $email');

    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = cred.user;

    if (user != null) {
      print('✅ User created successfully: ${user.uid}');
      await user.updateDisplayName('$firstName $lastName');

      if (!user.emailVerified) {
        print('📤 Sending verification email...');
        await user.sendEmailVerification();
        print('✅ Verification email sent successfully to: ${user.email}');

        await FirebaseFirestore.instance
            .collection("notVerifiedUsers")
            .doc(user.uid)
            .set({
          "email": email,
          "firstName": firstName,
          "lastName": lastName,
          "createdAt": FieldValue.serverTimestamp(),
        });

        print('✅ User data saved to notVerifiedUsers collection');
      }
    }

    return user;
  }

  // ==================== SIGN IN WITH GOOGLE ====================
  static Future<User?> signInWithGoogle() async {
    print('🔵 Starting Google Sign-In...');

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      print('❌ Google Sign-In cancelled by user');
      return null;
    }

    print('✅ Google account selected: ${googleUser.email}');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    print('📤 Signing in with Google credentials...');

    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = result.user;

    if (user != null) {
      print('✅ Google Sign-In successful: ${user.uid}');
      await ensureVerifiedUsersDocForGoogle(user);
    }

    return user;
  }
}