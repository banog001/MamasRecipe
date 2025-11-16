// Create: lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ==================== FIRESTORE QUERIES ====================

  Future<bool> checkTermsAgreementStatus(String email) async {
    if (email.isEmpty) return false;

    try {
      // Check Users collection
      final usersQuery = await _firestore
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final userData = usersQuery.docs.first.data();
        return userData['checkedAgreeConditions'] ?? false;
      }

      // Check dietitianApproval collection
      final dietitianQuery = await _firestore
          .collection('dietitianApproval')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (dietitianQuery.docs.isNotEmpty) {
        final dietitianData = dietitianQuery.docs.first.data();
        return dietitianData['checkedAgreeConditions'] ?? false;
      }

      return false;
    } catch (e) {
      print('❌ Error checking terms agreement status: $e');
      return false;
    }
  }

  Future<bool> checkIfAccountDeactivated(String uid) async {
    try {
      final userDoc = await _firestore.collection('Users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        return userData?['deactivated'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking deactivation status: $e');
      return false;
    }
  }

  // ==================== USER DATA OPERATIONS ====================

  Future<void> saveUserToFirestore(User user) async {
    String displayName = user.displayName ?? "";
    List<String> nameParts = displayName.split(" ");
    String firstName = nameParts.isNotEmpty ? nameParts.first : "";
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

    final docRef = _firestore.collection("Users").doc(user.uid);
    final docSnap = await docRef.get();

    Map<String, dynamic> dataToUpdate = {
      "email": user.email,
      "firstName": firstName,
      "lastName": lastName,
      "status": "online",
      "lastSeen": FieldValue.serverTimestamp(),
    };

    if (!docSnap.exists) {
      dataToUpdate.addAll({
        "age": null,
        "goals": null,
        "hasCompletedTutorial": false,
        "tutorialStep": 0,
        "role": "user",
        "qrapproved": false,
        "creationDate": FieldValue.serverTimestamp(),
      });
    } else {
      dataToUpdate["qrapproved"] = docSnap.data()?["qrapproved"] ?? false;
      dataToUpdate["role"] = docSnap.data()?["role"] ?? "user";
    }

    await docRef.set(dataToUpdate, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final userDoc = await _firestore.collection('Users').doc(uid).get();
    return userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
  }

  Future<Map<String, dynamic>?> getDietitianData(String uid) async {
    final dietitianDoc =
    await _firestore.collection('dietitianApproval').doc(uid).get();
    return dietitianDoc.exists ? dietitianDoc.data() as Map<String, dynamic>? : null;
  }

  Future<Map<String, dynamic>?> getVerifiedUserData(String uid) async {
    final verifiedDoc =
    await _firestore.collection('verifiedUsers').doc(uid).get();
    return verifiedDoc.exists ? verifiedDoc.data() as Map<String, dynamic>? : null;
  }

  // ==================== USER CREATION ====================

  Future<void> createRegularUserDocument(User user, String firstName, String lastName) async {
    await _firestore.collection("Users").doc(user.uid).set({
      "email": user.email,
      "firstName": firstName,
      "lastName": lastName,
      "status": "online",
      "lastSeen": FieldValue.serverTimestamp(),
      "age": null,
      "goals": null,
      "hasCompletedTutorial": false,
      "tutorialStep": 0,
      "role": "user",
      "qrapproved": false,
      "checkedAgreeConditions": true,
      "agreedToTermsAt": FieldValue.serverTimestamp(),
      "creationDate": FieldValue.serverTimestamp(),
    });
  }

  Future<void> createDietitianDocument(User user, String firstName, String lastName) async {
    String profileUrl = '';
    User? currentUser = _auth.currentUser;
    if (currentUser != null &&
        currentUser.photoURL != null &&
        currentUser.photoURL!.isNotEmpty) {
      profileUrl = currentUser.photoURL!;
    }

    await _firestore.collection("dietitianApproval").doc(user.uid).set({
      "email": user.email ?? "",
      "firstName": firstName,
      "lastName": lastName,
      "profile": profileUrl,
      "licenseNum": null,
      "prcImageUrl": null,
      "status": "pending",
      "qrstatus": "pending",
      "qrapproved": false,
      "role": "dietitian",
      "hasCompletedTutorial": false,
      "tutorialStep": 0,
      "checkedAgreeConditions": true,
      "agreedToTermsAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // ==================== TERMS AGREEMENT ====================

  Future<void> saveTermsAgreement(String uid, bool isUser) async {
    final collection = isUser ? "Users" : "dietitianApproval";
    await _firestore.collection(collection).doc(uid).update({
      'checkedAgreeConditions': true,
      'agreedToTermsAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== GOOGLE SIGN IN ====================

  Future<bool> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      List<String> signInMethods =
      await _auth.fetchSignInMethodsForEmail(googleUser.email);

      if (signInMethods.contains('password')) {
        return false; // Email already registered with password
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await _auth.signInWithCredential(credential);
      return _auth.currentUser != null;
    } catch (e) {
      print("Google Sign-In error: $e");
      return false;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // ==================== EMAIL/PASSWORD AUTH ====================

  Future<UserCredential?> signInWithEmailPassword(
      String email, String password)
  async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ==================== EMAIL VERIFICATION ====================

  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    }
    return false;
  }

  Future<void> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== SIGN OUT ====================

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==================== GETTERS ====================

  User? get currentUser => _auth.currentUser;

  bool get isUserLoggedIn => _auth.currentUser != null;
}