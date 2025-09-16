import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:google_sign_in/google_sign_in.dart';

class signUpPage extends StatefulWidget {
  const signUpPage({super.key});

  @override
  State<signUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<signUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void goLogIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPageMobile()),
    );
  }

  // ---------- MIGRATION HELPERS ----------
  Future<void> _migrateNotVerifiedToUsers(User user) async {
    final firestore = FirebaseFirestore.instance;
    final notVerRef = firestore.collection('notVerifiedUsers').doc(user.uid);
    final usersRef = firestore.collection('Users').doc(user.uid);

    final snap = await notVerRef.get();

    // Start with any existing staged data (first/last/email), then enforce safe fields.
    final Map<String, dynamic> data = {
      if (snap.exists) ...snap.data()!,
      'email': user.email,
      'emailVerified': true,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password',
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Never store plaintext password if it somehow exists.
    data.remove('password');

    // If first/last missing, try to derive from text fields or displayName.
    if ((data['firstName'] == null || (data['firstName'] as String).isEmpty)) {
      final dn = user.displayName ?? '';
      data['firstName'] = _firstNameController.text.isNotEmpty
          ? _firstNameController.text.trim()
          : (dn.isNotEmpty ? dn.split(' ').first : '');
    }
    if ((data['lastName'] == null || (data['lastName'] as String).isEmpty)) {
      final dn = user.displayName ?? '';
      data['lastName'] = _lastNameController.text.isNotEmpty
          ? _lastNameController.text.trim()
          : (dn.contains(' ') ? dn.split(' ').sublist(1).join(' ') : '');
    }

    await usersRef.set(data, SetOptions(merge: true));

    // Best effort delete of staging doc
    try {
      await notVerRef.delete();
    } catch (_) {/* ignore */}
  }

  Future<void> _tryMigrateAfterVerification(User user) async {
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      await _migrateNotVerifiedToUsers(refreshed);
      if (mounted) {
        Navigator.of(context).pop(); // close the verify dialog
        _showSuccessDialog(context, onOk: goLogIn);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email not verified yet. Try again.")),
        );
      }
    }
  }

  Future<void> _ensureUsersDocForGoogle(User user) async {
    final usersRef =
    FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final exists = await usersRef.get();

    if (!exists.exists) {
      final dn = user.displayName ?? '';
      final first = dn.isNotEmpty ? dn.split(' ').first : '';
      final last = dn.contains(' ') ? dn.split(' ').sublist(1).join(' ') : '';

      await usersRef.set({
        'email': user.email,
        'firstName': first,
        'lastName': last,
        'provider': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'google.com',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // If they somehow had a staging doc, clean it up.
    try {
      await FirebaseFirestore.instance
          .collection('notVerifiedUsers')
          .doc(user.uid)
          .delete();
    } catch (_) {/* ignore */}
  }
  // ---------- END HELPERS ----------

  Future<void> showVerificationDialog(User user) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 18),
              const Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We sent a verification link to your email. Click it, then come back here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    await user.sendEmailVerification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Verification email resent.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Resend Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  goLogIn();
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final fName = _firstNameController.text.trim();
    final lName = _lastNameController.text.trim();
    final mail = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: mail, password: password);

      User? user = cred.user;
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          // Stage the profile in notVerifiedUsers
          await FirebaseFirestore.instance
              .collection("notVerifiedUsers")
              .doc(user.uid)
              .set({
            "email": mail,
            "firstName": fName,
            "lastName": lName,
            // ⚠ Never store plaintext passwords
          });

          await showVerificationDialog(user);
        } else {
          // Rare case (e.g., SSO), but handle just in case
          await _migrateNotVerifiedToUsers(user);
          _showSuccessDialog(context, onOk: goLogIn);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("This email is already registered. Please log in.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final result =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = result.user;
      if (user != null) {
        await _ensureUsersDocForGoogle(user);
        _showSuccessDialog(context, onOk: goLogIn);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign-in failed: $e")),
        );
      }
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          CustomPaint(painter: WavePainter(), size: Size.infinite),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'PLEASE SIGN UP TO CONTINUE',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 50),

                      _buildTextField(
                        controller: _lastNameController,
                        hintText: 'LAST NAME',
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your last name' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _firstNameController,
                        hintText: 'FIRST NAME',
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your first name' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _emailController,
                        hintText: 'EMAIL',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your email';
                          }
                          final ok = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value);
                          return ok ? null : 'Enter a valid email';
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'PASSWORD',
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'CONFIRM PASSWORD',
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() =>
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: goLogIn,
                        child: const Text(
                          'ALREADY HAVE AN ACCOUNT? SIGN IN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Ready',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You can now log in to your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOk?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
          letterSpacing: 0.5,
          fontFamily: 'Inter',
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4CAF50),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Top wave
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.25,
      size.width * 0.5, size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.35,
      size.width, size.height * 0.25,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Bottom wave
    final bottomPath = Path();
    bottomPath.moveTo(0, size.height);
    bottomPath.lineTo(0, size.height * 0.75);
    bottomPath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.8,
      size.width * 0.5, size.height * 0.75,
    );
    bottomPath.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.8,
    );
    bottomPath.lineTo(size.width, size.height);
    bottomPath.close();

    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
