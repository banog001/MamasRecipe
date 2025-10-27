import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'login.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade100;

Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;

Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

const Color _textColorOnPrimary = Colors.white;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor =
      color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}

class signUpPage extends StatefulWidget {
  const signUpPage({super.key});

  @override
  State<signUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<signUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _verificationTimer?.cancel();
    super.dispose();
  }

  void goLogIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPageMobile()),
    );
  }

  // ---------- VERIFICATION HELPERS ----------
  // NEW: Just mark as verified in verifiedUsers collection (no role assignment yet)
  Future<void> _markUserAsVerified(User user) async {
    final firestore = FirebaseFirestore.instance;
    final notVerRef = firestore.collection('notVerifiedUsers').doc(user.uid);
    final verifiedRef = firestore.collection('verifiedUsers').doc(user.uid);

    final snap = await notVerRef.get();

    // Store user data in verifiedUsers (awaiting role selection on first login)
    final Map<String, dynamic> data = {
      if (snap.exists) ...snap.data()!,
      'email': user.email,
      'emailVerified': true,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password',
      'verifiedAt': FieldValue.serverTimestamp(),
    };

    // Never store plaintext password
    data.remove('password');

    // Ensure firstName and lastName are set
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

    await verifiedRef.set(data, SetOptions(merge: true));

    // Delete from notVerifiedUsers
    try {
      await notVerRef.delete();
    } catch (_) {/* ignore */}
  }

  // Automatic verification checker with periodic polling
  void _startAutoVerificationCheck(User user) {
    print('🔄 Starting automatic verification check...');

    // Check every 3 seconds
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;

        if (refreshed != null && refreshed.emailVerified) {
          print('✅ Email verified automatically detected!');
          timer.cancel();

          await _markUserAsVerified(refreshed);

          if (mounted) {
            Navigator.of(context).pop(); // Close verification dialog
            _showSuccessDialog(context, onOk: goLogIn);
          }
        }
      } catch (e) {
        print('⚠️ Error checking verification status: $e');
      }
    });
  }

  Future<void> _tryVerifyManually(User user) async {
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      await _markUserAsVerified(refreshed);
      if (mounted) {
        Navigator.of(context).pop(); // close the verify dialog
        _showSuccessDialog(context, onOk: goLogIn);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email not verified yet. Please check your inbox and click the verification link.")),
        );
      }
    }
  }

  Future<void> _ensureVerifiedUsersDocForGoogle(User user) async {
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

    // Clean up staging doc if exists
    try {
      await FirebaseFirestore.instance
          .collection('notVerifiedUsers')
          .doc(user.uid)
          .delete();
    } catch (_) {/* ignore */}
  }
  // ---------- END HELPERS ----------

  Future<void> showVerificationDialog(User user) async {
    // Start automatic verification checking
    _startAutoVerificationCheck(user);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async {
          _verificationTimer?.cancel();
          return true;
        },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _cardBgColor(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: _textColorOnPrimary, size: 44),
                ),
                const SizedBox(height: 18),
                Text(
                  'Verify your email',
                  style: _getTextStyle(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification link to ${user.email}. Click the link in your email to verify your account.',
                  textAlign: TextAlign.center,
                  style: _getTextStyle(
                    context,
                    fontSize: 14,
                    color: _textColorSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for verification...',
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        color: _textColorSecondary(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => _tryVerifyManually(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'I\'ve Verified My Email',
                      style: _getTextStyle(
                        context,
                        fontWeight: FontWeight.bold,
                        color: _textColorOnPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await user.sendEmailVerification();
                        if (mounted) {
                          _showSuccessSnackBar("Verification email resent! Check your inbox.");
                        }
                      } catch (e) {
                        if (mounted) {
                          _showErrorSnackBar("Failed to resend email. Please wait a moment and try again.");
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Resend Email',
                      style: _getTextStyle(
                        context,
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    _verificationTimer?.cancel();
                    Navigator.of(context).pop();
                    goLogIn();
                  },
                  child: Text(
                    'Back to Login',
                    style: _getTextStyle(
                      context,
                      color: _textColorSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Cancel timer when dialog closes
    _verificationTimer?.cancel();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final fName = _firstNameController.text.trim();
    final lName = _lastNameController.text.trim();
    final mail = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      print('🔵 Creating user account for: $mail');

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: mail, password: password);

      User? user = cred.user;

      if (user != null) {
        print('✅ User created successfully: ${user.uid}');
        print('📧 Email verified status: ${user.emailVerified}');

        // Update display name
        await user.updateDisplayName('$fName $lName');

        if (!user.emailVerified) {
          try {
            print('📤 Sending verification email...');

            await user.sendEmailVerification();

            print('✅ Verification email sent successfully to: ${user.email}');

            // Save to notVerifiedUsers collection (temporary staging)
            await FirebaseFirestore.instance
                .collection("notVerifiedUsers")
                .doc(user.uid)
                .set({
              "email": mail,
              "firstName": fName,
              "lastName": lName,
              "createdAt": FieldValue.serverTimestamp(),
            });

            print('✅ User data saved to notVerifiedUsers collection');

            if (mounted) {
              setState(() => _isLoading = false);
              await showVerificationDialog(user);
            }
          } catch (emailError) {
            print('❌ Error sending verification email: $emailError');

            if (mounted) {
              setState(() => _isLoading = false);

              if (emailError.toString().contains('too-many-requests')) {
                _showErrorSnackBar("Too many requests. Please wait a moment before trying again.");
              } else {
                _showErrorSnackBar("Could not send verification email. Please try again later.");
              }
            }
          }
        } else {
          // Email is already verified (shouldn't happen for new accounts)
          print('✅ Email already verified');
          await _markUserAsVerified(user);

          if (mounted) {
            setState(() => _isLoading = false);
            _showSuccessDialog(context, onOk: goLogIn);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');

      if (mounted) {
        setState(() => _isLoading = false);

        switch (e.code) {
          case 'email-already-in-use':
            _showErrorSnackBar("This email is already registered. Please log in.");
            break;
          case 'weak-password':
            _showErrorSnackBar("Password is too weak. Please use a stronger password.");
            break;
          case 'invalid-email':
            _showErrorSnackBar("Invalid email address. Please check and try again.");
            break;
          case 'operation-not-allowed':
            _showErrorSnackBar("Email/password sign-up is not enabled. Please contact support.");
            break;
          case 'network-request-failed':
            _showErrorSnackBar("Network error. Please check your internet connection.");
            break;
          default:
            _showErrorSnackBar("Registration failed: ${e.message}");
        }
      }
    } catch (e) {
      print('❌ Unexpected error during registration: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("An unexpected error occurred. Please try again.");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: _textColorOnPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: _textColorOnPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundShapes(context),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.0,
                              vertical: keyboardHeight > 0 ? 12.0 : 16.0,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: keyboardHeight > 0 ? 12 : 16),

                                  _buildHeaderSection(),
                                  SizedBox(height: keyboardHeight > 0 ? 12 : 16),

                                  Flexible(
                                    child: Card(
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      color: Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildTextField(
                                              controller: _firstNameController,
                                              label: 'First Name',
                                              icon: Icons.person_outline,
                                              validator: (v) =>
                                              (v == null || v.isEmpty) ? 'Enter your first name' : null,
                                            ),
                                            const SizedBox(height: 12),

                                            _buildTextField(
                                              controller: _lastNameController,
                                              label: 'Last Name',
                                              icon: Icons.person_outline,
                                              validator: (v) =>
                                              (v == null || v.isEmpty) ? 'Enter your last name' : null,
                                            ),
                                            const SizedBox(height: 12),

                                            _buildTextField(
                                              controller: _emailController,
                                              label: 'Email Address',
                                              icon: Icons.email_outlined,
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
                                            const SizedBox(height: 12),

                                            _buildTextField(
                                              controller: _passwordController,
                                              label: 'Password',
                                              icon: Icons.lock_outline,
                                              obscureText: !_isPasswordVisible,
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isPasswordVisible
                                                      ? Icons.visibility_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: _textColorSecondary(context),
                                                ),
                                                onPressed: () =>
                                                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Enter password';
                                                }
                                                if (value.length < 8) {
                                                  return 'Password must be at least 8 characters';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 12),

                                            _buildTextField(
                                              controller: _confirmPasswordController,
                                              label: 'Confirm Password',
                                              icon: Icons.lock_outline,
                                              obscureText: !_isConfirmPasswordVisible,
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isConfirmPasswordVisible
                                                      ? Icons.visibility_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: _textColorSecondary(context),
                                                ),
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
                                            const SizedBox(height: 16),

                                            _buildSignUpButton(),
                                            const SizedBox(height: 12),

                                            _buildDivider(),
                                            const SizedBox(height: 12),

                                            _buildGoogleSignUpButton(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  _buildLoginLink(),
                                  SizedBox(height: keyboardHeight > 0 ? 8 : 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_outlined,
            color: _textColorOnPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Create Account',
          style: _getTextStyle(
            context,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _textColorPrimary(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Join us to start your health journey',
          style: _getTextStyle(
            context,
            fontSize: 13,
            color: _textColorSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
      style: _getTextStyle(context, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _getTextStyle(
          context,
          color: _textColorSecondary(context),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: _primaryColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _scaffoldBgColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _textColorOnPrimary,
          elevation: 4,
          shadowColor: _primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: _textColorOnPrimary,
            strokeWidth: 2,
          ),
        )
            : Text(
          'Create Account',
          style: _getTextStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: goLogIn,
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: _getTextStyle(
              context,
              fontSize: 14,
              color: _textColorSecondary(context),
            ),
            children: [
              TextSpan(
                text: 'Sign In',
                style: _getTextStyle(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
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
              color: _cardBgColor(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: _textColorOnPrimary, size: 50),
                ),
                const SizedBox(height: 20),
                Text(
                  'Email Verified!',
                  style: _getTextStyle(
                    context,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your email has been verified! You can now log in to your account.',
                  textAlign: TextAlign.center,
                  style: _getTextStyle(
                    context,
                    fontSize: 16,
                    color: _textColorSecondary(context),
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
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue to Login',
                      style: _getTextStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColorOnPrimary,
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: _getTextStyle(
              context,
              fontSize: 12,
              color: _textColorSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGoogleSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Image.asset(
          'assets/google_logo.png',
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
        ),
        label: Text(
          'Continue with Google',
          style: _getTextStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textColorPrimary(context),
          ),
        ),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 Starting Google Sign-In...');

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print('❌ Google Sign-In cancelled by user');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      print('✅ Google account selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('📤 Signing in with Google credentials...');

      final result =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = result.user;

      if (user != null) {
        print('✅ Google Sign-In successful: ${user.uid}');
        await _ensureVerifiedUsersDocForGoogle(user);

        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog(context, onOk: goLogIn);
        }
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during Google Sign-In: ${e.code} - ${e.message}');

      if (mounted) {
        setState(() => _isLoading = false);

        switch (e.code) {
          case 'account-exists-with-different-credential':
            _showErrorSnackBar("An account already exists with this email using a different sign-in method.");
            break;
          case 'invalid-credential':
            _showErrorSnackBar("Invalid credentials. Please try again.");
            break;
          case 'operation-not-allowed':
            _showErrorSnackBar("Google sign-in is not enabled. Please contact support.");
            break;
          case 'user-disabled':
            _showErrorSnackBar("This account has been disabled.");
            break;
          case 'network-request-failed':
            _showErrorSnackBar("Network error. Please check your internet connection.");
            break;
          default:
            _showErrorSnackBar("Google sign-in failed: ${e.message}");
        }
      }
    } catch (e) {
      print('❌ Unexpected error during Google Sign-In: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("An unexpected error occurred. Please try again.");
      }
    }
  }

  Widget _buildBackgroundShapes(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _scaffoldBgColor(context),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -180,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}