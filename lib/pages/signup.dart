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
                'We sent a verification link to your email. Click it, then come back here.',
                textAlign: TextAlign.center,
                style: _getTextStyle(
                  context,
                  fontSize: 14,
                  color: _textColorSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    await user.sendEmailVerification();
                    if (mounted) {
                      _showErrorSnackBar("Verification email resent.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: _textColorOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Resend Email',
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _textColorOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
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
    );
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
          await FirebaseFirestore.instance
              .collection("notVerifiedUsers")
              .doc(user.uid)
              .set({
            "email": mail,
            "firstName": fName,
            "lastName": lName,
          });

          await showVerificationDialog(user);
        } else {
          await _migrateNotVerifiedToUsers(user);
          _showSuccessDialog(context, onOk: goLogIn);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showErrorSnackBar("This email is already registered. Please log in.");
      } else {
        _showErrorSnackBar("Error: ${e.message}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // <CHANGE> Reduced top padding from 60 to 16
                      const SizedBox(height: 16),

                      _buildHeaderSection(),
                      // <CHANGE> Reduced spacing from 50 to 16
                      const SizedBox(height: 16),

                      Card(
                        elevation: 8,
                        shadowColor: _primaryColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: _cardBgColor(context),
                        child: Padding(
                          // <CHANGE> Reduced card padding from 28 to 16
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _firstNameController,
                                label: 'First Name',
                                icon: Icons.person_outline,
                                validator: (v) =>
                                (v == null || v.isEmpty) ? 'Enter your first name' : null,
                              ),
                              // <CHANGE> Reduced spacing from 20 to 12
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
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
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
                              // <CHANGE> Reduced spacing from 35 to 16
                              const SizedBox(height: 16),

                              _buildSignUpButton(),
                              // <CHANGE> Reduced spacing from 20 to 12
                              const SizedBox(height: 12),

                              _buildDivider(),
                              const SizedBox(height: 12),

                              _buildGoogleSignUpButton(),
                            ],
                          ),
                        ),
                      ),
                      // <CHANGE> Reduced spacing from 30 to 16
                      const SizedBox(height: 16),

                      _buildLoginLink(),
                      // <CHANGE> Reduced bottom padding from 40 to 16
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          // <CHANGE> Reduced icon size from 80x80 to 56x56
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
            // <CHANGE> Reduced icon size from 40 to 32
            size: 32,
          ),
        ),
        // <CHANGE> Reduced spacing from 24 to 12
        const SizedBox(height: 12),
        Text(
          'Create Account',
          style: _getTextStyle(
            context,
            // <CHANGE> Reduced font size from 32 to 24
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _textColorPrimary(context),
          ),
        ),
        // <CHANGE> Reduced spacing from 8 to 4
        const SizedBox(height: 4),
        Text(
          'Join us to start your health journey',
          style: _getTextStyle(
            context,
            // <CHANGE> Reduced font size from 16 to 13
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
        // <CHANGE> Reduced icon size from 22 to 20
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
        // <CHANGE> Reduced vertical padding from 18 to 14
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      // <CHANGE> Reduced button height from 56 to 48
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
      // <CHANGE> Reduced button height from 56 to 48
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
                  'Account Ready',
                  style: _getTextStyle(
                    context,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You can now log in to your account.',
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
                      'Continue',
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
}