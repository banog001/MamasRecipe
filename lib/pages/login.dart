import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'home.dart';
import 'start.dart';
import '../Dietitians/homePageDietitian.dart';

import 'termsAndConditions.dart';

import 'package:flutter/gestures.dart';// Your terms file





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

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});
  @override
  State<LoginPageMobile> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageMobile> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;



  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _welcomeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _welcomeScaleAnimation;
  late Animation<double> _welcomeOpacityAnimation;

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

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _welcomeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.elasticOut),
    );

    _welcomeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeInOut),
    );

    emailController.addListener(_onEmailChanged);

    _showWelcomePopup();
  }

  void _showWelcomePopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeController.forward();
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (context) => _buildWelcomeDialog(),
      ).then((_) {
        _fadeController.forward();
        _slideController.forward();
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }
  void _onEmailChanged() {
    final email = emailController.text.trim();
    // Only check if email looks valid (has @)
    if (email.isNotEmpty && email.contains('@')) {
      _checkTermsAgreementStatus(email);
    }
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            activeColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _showTermsDialog,
            child: RichText(
              text: TextSpan(
                style: _getTextStyle(
                  context,
                  fontSize: 14,
                  color: _textColorSecondary(context),
                ),
                children: [
                  const TextSpan(text: 'I agree with '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: _getTextStyle(
                      context,
                      fontSize: 14,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeDialog() {
    return AnimatedBuilder(
      animation: _welcomeController,
      builder: (context, child) {
        return Transform.scale(
          scale: _welcomeScaleAnimation.value,
          child: Opacity(
            opacity: _welcomeOpacityAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: _cardBgColor(context),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -50,
                              left: -80,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -60,
                              right: -90,
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              color: _textColorOnPrimary,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome!',
                            style: _getTextStyle(
                              context,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _textColorPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to continue your health journey',
                            textAlign: TextAlign.center,
                            style: _getTextStyle(
                              context,
                              fontSize: 16,
                              color: _textColorSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: _textColorOnPrimary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'Get Started',
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkTermsAgreementStatus(String email) async {
    if (email.isEmpty) return;

    try {
      // Query Users collection
      final usersQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final userData = usersQuery.docs.first.data();
        bool hasAgreed = userData['checkedAgreeConditions'] ?? false;

        if (mounted) {
          setState(() {
            _agreedToTerms = hasAgreed;
          });
        }
        print('✅ Loaded terms status from Users: $hasAgreed');
        return;
      }

      // Query dietitianApproval collection
      final dietitianQuery = await FirebaseFirestore.instance
          .collection('dietitianApproval')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (dietitianQuery.docs.isNotEmpty) {
        final dietitianData = dietitianQuery.docs.first.data();
        bool hasAgreed = dietitianData['checkedAgreeConditions'] ?? false;

        if (mounted) {
          setState(() {
            _agreedToTerms = hasAgreed;
          });
        }
        print('✅ Loaded terms status from dietitianApproval: $hasAgreed');
        return;
      }

      // If no user found, keep checkbox unchecked (new user)
      if (mounted) {
        setState(() {
          _agreedToTerms = false;
        });
      }
      print('ℹ️ No user found with this email');
    } catch (e) {
      print('❌ Error checking terms agreement status: $e');
      // On error, keep checkbox unchecked for safety
      if (mounted) {
        setState(() {
          _agreedToTerms = false;
        });
      }
    }
  }

  Future<String?> _askUserRoleDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardBgColor(dialogContext),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_search_outlined,
                    color: _primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Select Account Type',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(dialogContext),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Please choose your role to continue.',
                  textAlign: TextAlign.center,
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 16,
                    color: _textColorSecondary(dialogContext),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, "user"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: _primaryColor, width: 1.5),
                      foregroundColor: _primaryColor,
                    ),
                    icon: const Icon(Icons.person_outline, size: 20),
                    label: Text(
                      'I am a User',
                      style: _getTextStyle(
                        dialogContext,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, "dietitian"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(
                        Icons.health_and_safety_outlined, size: 20),
                    label: Text(
                      'I am a Dietitian',
                      style: _getTextStyle(
                        dialogContext,
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

  // ==================== FORGOT PASSWORD DIALOG ====================
  Future<void> _showForgotPasswordDialog() async {
    TextEditingController resetEmailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(
                20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _cardBgColor(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_outlined,
                      color: _primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Reset Password",
                    style: _getTextStyle(
                      context,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColorPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter your registered email to reset your password.",
                    textAlign: TextAlign.center,
                    style: _getTextStyle(
                      context,
                      fontSize: 14,
                      color: _textColorSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: _getTextStyle(context),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: _getTextStyle(
                        context,
                        color: _textColorSecondary(context),
                      ),
                      prefixIcon: Icon(
                          Icons.email_outlined, color: _primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: _getTextStyle(
                              context,
                              color: _textColorSecondary(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            String resetEmail = resetEmailController.text
                                .trim();
                            if (resetEmail.isEmpty) {
                              _showErrorSnackBar("Please enter an email");
                              return;
                            }
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: resetEmail);
                              Navigator.pop(context);
                              _showSuccessSnackBar(
                                  "Password reset email has been sent");
                            } on FirebaseAuthException catch (e) {
                              _showErrorSnackBar("Error: ${e.message}");
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
                            "Send",
                            style: _getTextStyle(
                              context,
                              fontWeight: FontWeight.bold,
                              color: _textColorOnPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ==================== UI Widgets (TextFields, Buttons, etc) ====================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        isDense: true,
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _textColorOnPrimary,
          elevation: 4,
          shadowColor: _primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: _textColorOnPrimary,
            strokeWidth: 2,
          ),
        )
            : Text(
          'Sign In',
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

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Image.asset(
          'assets/google_logo.png',
          width: 18,
          height: 18,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.g_mobiledata, color: Colors.red, size: 20),
        ),
        label: Text(
          'Continue with Google',
          style: _getTextStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColorPrimary(context),
          ),
        ),
      ),
    );
  }

  // ==================== Firebase Methods ====================

  Future<void> _saveUserToFirestore(User user) async {
    String displayName = user.displayName ?? "";
    List<String> nameParts = displayName.split(" ");
    String firstName = nameParts.isNotEmpty ? nameParts.first : "";
    String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(" ")
        : "";
    final docRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
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

  Future<void> _handlePostLogin(User user) async {
    await user.reload();
    user = FirebaseAuth.instance.currentUser!;

    final usersRef = FirebaseFirestore.instance.collection("Users").doc(
        user.uid);
    final dietitianRef = FirebaseFirestore.instance.collection(
        "dietitianApproval").doc(user.uid);

    DocumentSnapshot userSnap = await usersRef.get();
    DocumentSnapshot dietitianSnap = await dietitianRef.get();

    String role = "user";
    bool hasCompletedTutorial = false;

    if (userSnap.exists) {
      final userData = userSnap.data() as Map<String, dynamic>?;

      role = userData?['role'] ?? "user";
      hasCompletedTutorial = userData?['hasCompletedTutorial'] ?? false;

      if (role == "user") {
        if (hasCompletedTutorial) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const home()),
          );
        }
      } else if (role == "dietitian") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageDietitian()),
        );
      }
      return;
    }

    if (!userSnap.exists && !dietitianSnap.exists) {
      String? selectedRole = await _askUserRoleDialog();
      if (selectedRole == null) return;
      role = selectedRole;

      String displayName = user.displayName ?? "";
      List<String> nameParts = displayName.split(" ");
      String firstName = nameParts.isNotEmpty ? nameParts.first : "";
      String lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(" ")
          : "";

      if (role == "user") {
        await usersRef.set({
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
          "creationDate": FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => MealPlanningScreen(userId: user.uid)),
        );
        return;
      } else if (role == "dietitian") {
        // Get Google profile photo if available
        String profileUrl = '';
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.photoURL != null && currentUser.photoURL!.isNotEmpty) {
          profileUrl = currentUser.photoURL!;
        }

        await dietitianRef.set({
          "email": user.email ?? "",
          "firstName": firstName,
          "lastName": lastName,
          "profile": profileUrl,  // Add Google profile URL
          "licenseNum": null,
          "prcImageUrl": null,
          "status": "pending",
          "qrstatus": "pending",  // Add QR status
          "qrapproved": false,    // Add QR approved flag
          "role": "dietitian",
          "hasCompletedTutorial": false,
          "tutorialStep": 0,
          "createdAt": FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => MealPlanningScreen(userId: user.uid)),
        );
        return;
      }
    }

    if (!userSnap.exists && dietitianSnap.exists) {
      final dietitianData = dietitianSnap.data() as Map<String, dynamic>?;

      role = "dietitian";

      if (dietitianData != null && dietitianData['status'] == 'pending') {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) =>
              AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                        Icons.info_outline, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Account Review',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your account will be reviewed by the admins. '
                          'Please go back to login and wait for approval. Thank you!',
                      style: TextStyle(
                          fontSize: 14, color: Colors.black87, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (
                                _) => const LoginPageMobile()),
                          );
                        },
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        );
        return;
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageDietitian()),
        );
        return;
      }
    }
  }

  Future<void> _showTermsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Terms and Conditions',
                        style: _getTextStyle(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textColorOnPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _textColorOnPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Terms Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: TermsAndConditionsScreen(), // Your terms widget
                ),
              ),
              // Close Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: _getTextStyle(
                        context,
                        fontWeight: FontWeight.bold,
                        color: _textColorOnPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    String email = emailController.text.trim();
    String pass = passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showErrorSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      User? user = userCredential.user;

      if (user != null) {
        print('🔵 User logged in: ${user.uid}');

        // Reload user to get the latest email verification status
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        // Check if email is verified
        if (!user!.emailVerified) {
          print('⚠️ User email not verified: ${user.email}');

          // Check if user data exists in notVerifiedUsers
          final notVerifiedRef = FirebaseFirestore.instance
              .collection('notVerifiedUsers')
              .doc(user.uid);
          final notVerifiedSnap = await notVerifiedRef.get();

          if (notVerifiedSnap.exists) {
            if (mounted) {
              setState(() => _isLoading = false);
              await _showUnverifiedAccountDialog(user);
            }
            return;
          } else {
            if (mounted) {
              setState(() => _isLoading = false);
              await _showUnverifiedAccountDialog(user);
            }
            return;
          }
        }

        // Email is verified - check where user data exists
        print('✅ User email verified: ${user.email}');

        final usersRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
        final dietitianRef = FirebaseFirestore.instance.collection("dietitianApproval").doc(user.uid);
        final verifiedRef = FirebaseFirestore.instance.collection("verifiedUsers").doc(user.uid);

        DocumentSnapshot userSnap = await usersRef.get();
        DocumentSnapshot dietitianSnap = await dietitianRef.get();
        DocumentSnapshot verifiedSnap = await verifiedRef.get();

        // ✅ CHECK TERMS AGREEMENT STATUS
        bool needsToAgree = false;
        DocumentReference? userDocRef;

        if (userSnap.exists) {
          userDocRef = usersRef;
          final userData = userSnap.data() as Map<String, dynamic>?;
          bool hasAgreed = userData?['checkedAgreeConditions'] ?? false;
          needsToAgree = !hasAgreed;
        } else if (dietitianSnap.exists) {
          userDocRef = dietitianRef;
          final dietitianData = dietitianSnap.data() as Map<String, dynamic>?;
          bool hasAgreed = dietitianData?['checkedAgreeConditions'] ?? false;
          needsToAgree = !hasAgreed;
        } else if (verifiedSnap.exists) {
          needsToAgree = true; // New users need to agree
        }

        // If user needs to agree to terms, check the checkbox
        if (needsToAgree && !_agreedToTerms) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showErrorSnackBar("Please agree to the Terms and Conditions");
          }
          return;
        }

        // If user just agreed, save it to Firestore
        if (needsToAgree && _agreedToTerms && userDocRef != null) {
          await userDocRef.update({
            'checkedAgreeConditions': true,
            'agreedToTermsAt': FieldValue.serverTimestamp(),
          });
        }

        // Case 1: User exists in Users collection (returning regular user)
        if (userSnap.exists) {
          print('✅ Found in Users collection');
          final userData = userSnap.data() as Map<String, dynamic>?;
          String role = userData?['role'] ?? "user";
          bool hasCompletedTutorial = userData?['hasCompletedTutorial'] ?? false;
          bool isDeactivated = userData?['deactivated'] ?? false;

          if (isDeactivated) {
            print('⚠️ Account is deactivated');
            if (mounted) {
              setState(() => _isLoading = false);
              await _showDeactivatedAccountDialog();
            }
            return;
          }

          if (role == "user") {
            if (hasCompletedTutorial) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const home()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => MealPlanningScreen(userId: user!.uid)),
              );
            }
          }
          return;
        }

        // Case 2: User exists in dietitianApproval collection (returning dietitian)
        if (dietitianSnap.exists) {
          print('✅ Found in dietitianApproval collection');
          final dietitianData = dietitianSnap.data() as Map<String, dynamic>?;
          String status = dietitianData?['status'] ?? 'pending';
          bool isDeactivated = dietitianData?['deactivated'] ?? false;

          if (isDeactivated) {
            print('⚠️ Dietitian account is deactivated');
            if (mounted) {
              setState(() => _isLoading = false);
              await _showDeactivatedAccountDialog();
            }
            return;
          }

          if (status == 'pending') {
            if (mounted) {
              setState(() => _isLoading = false);
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) =>
                    AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 64,
                              color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'Account Review',
                            style: TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your account is being reviewed by the admins. '
                                'Please wait for approval. Thank you!',
                            style: TextStyle(fontSize: 14,
                                color: Colors.black87,
                                height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                FirebaseAuth.instance.signOut();
                              },
                              child: const Text(
                                'OK',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              );
            }
            return;
          } else if (status == 'approved') {
            bool hasCompletedTutorial = dietitianData?['hasCompletedTutorial'] ??
                false;

            if (hasCompletedTutorial) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePageDietitian()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => MealPlanningScreen(userId: user!.uid)),
              );
            }
          } else if (status == 'rejected') {
            if (mounted) {
              setState(() => _isLoading = false);
              _showErrorSnackBar(
                  "Your dietitian application was not approved. Please contact support.");
              await FirebaseAuth.instance.signOut();
            }
          }
          return;
        }

        // Case 3: User exists in verifiedUsers collection (first login after verification)
        if (verifiedSnap.exists) {
          print(
              '✅ Found in verifiedUsers collection - first login, asking for role');

          final verifiedData = verifiedSnap.data() as Map<String, dynamic>?;
          String firstName = verifiedData?['firstName'] ?? '';
          String lastName = verifiedData?['lastName'] ?? '';

          String? selectedRole = await _askUserRoleDialog();

          if (selectedRole == null) {
            await FirebaseAuth.instance.signOut();
            setState(() => _isLoading = false);
            return;
          }

          if (selectedRole == "user") {
            await usersRef.set({
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
              "checkedAgreeConditions": true,  // ✅ Save terms agreement
              "agreedToTermsAt": FieldValue.serverTimestamp(),
              "creationDate": FieldValue.serverTimestamp(),
            });

            try {
              await verifiedRef.delete();
            } catch (_) {}

            print('✅ Migrated to Users collection');

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => MealPlanningScreen(userId: user!.uid)),
            );
          } else if (selectedRole == "dietitian") {
            String profileUrl = '';
            User? currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null && currentUser.photoURL != null && currentUser.photoURL!.isNotEmpty) {
              profileUrl = currentUser.photoURL!;
            }

            await dietitianRef.set({
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
              "checkedAgreeConditions": true,  // ✅ Save terms agreement
              "agreedToTermsAt": FieldValue.serverTimestamp(),
              "createdAt": FieldValue.serverTimestamp(),
            });

            try {
              await verifiedRef.delete();
            } catch (_) {}

            print('✅ Migrated to dietitianApproval collection with pending status');

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MealPlanningScreen(userId: user!.uid),
                ),
              );
            }
          }

          return;
        }

        // Case 4: No document found anywhere
        print(
            '⚠️ No user document found - this should not happen for verified email/password users');

        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar("Account data not found. Please sign up again.");
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed";
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled";
          break;
        case 'invalid-credential':
          errorMessage = "Invalid email or password";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
      }
      _showErrorSnackBar(errorMessage);
    } catch (err) {
      print('❌ Login error: $err');
      _showErrorSnackBar("Login failed: ${err.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Add this method to show unverified account dialog
  Future<void> _showUnverifiedAccountDialog(User user) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(
                20)),
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
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Email Not Verified',
                    style: _getTextStyle(
                      context,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textColorPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please verify your email address (${user
                        .email}) before logging in. Check your inbox for the verification link.',
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
                        try {
                          await user.sendEmailVerification();
                          if (mounted) {
                            _showSuccessSnackBar(
                                "Verification email sent! Check your inbox.");
                          }
                        } catch (e) {
                          if (mounted) {
                            if (e.toString().contains('too-many-requests')) {
                              _showErrorSnackBar(
                                  "Too many requests. Please wait before trying again.");
                            } else {
                              _showErrorSnackBar(
                                  "Failed to send email. Please try again later.");
                            }
                          }
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
                        'Resend Verification Email',
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
                        // Sign out the user
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back to Login',
                        style: _getTextStyle(
                          context,
                          color: _textColorSecondary(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    // Sign out user after dialog closes
    await FirebaseAuth.instance.signOut();
  }

  // Add this method after _showUnverifiedAccountDialog
  Future<bool> _checkIfAccountDeactivated(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

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

// Add this method to show deactivated account dialog
  Future<void> _showDeactivatedAccountDialog() async {
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
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Account Deactivated',
                style: _getTextStyle(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textColorPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account has been deactivated by the administrator. Please contact support for more information.',
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
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: _textColorOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _textColorOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await FirebaseAuth.instance.signOut();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      bool isLogged = await loginWithGoogle();
      if (isLogged && FirebaseAuth.instance.currentUser != null) {
        User? user = FirebaseAuth.instance.currentUser;

        // ✅ CHECK TERMS AGREEMENT
        final usersRef = FirebaseFirestore.instance.collection("Users").doc(user!.uid);
        final dietitianRef = FirebaseFirestore.instance.collection("dietitianApproval").doc(user.uid);

        DocumentSnapshot userSnap = await usersRef.get();
        DocumentSnapshot dietitianSnap = await dietitianRef.get();

        bool needsToAgree = false;
        DocumentReference? userDocRef;

        if (userSnap.exists) {
          userDocRef = usersRef;
          final userData = userSnap.data() as Map<String, dynamic>?;
          bool hasAgreed = userData?['checkedAgreeConditions'] ?? false;
          needsToAgree = !hasAgreed;
        } else if (dietitianSnap.exists) {
          userDocRef = dietitianRef;
          final dietitianData = dietitianSnap.data() as Map<String, dynamic>?;
          bool hasAgreed = dietitianData?['checkedAgreeConditions'] ?? false;
          needsToAgree = !hasAgreed;
        }

        if (needsToAgree && !_agreedToTerms) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showErrorSnackBar("Please agree to the Terms and Conditions");
          }
          return;
        }

        // Save agreement if needed
        if (needsToAgree && _agreedToTerms && userDocRef != null) {
          await userDocRef.update({
            'checkedAgreeConditions': true,
            'agreedToTermsAt': FieldValue.serverTimestamp(),
          });
        }

        await _handlePostLogin(user);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();

      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;

      List<String> signInMethods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(googleUser.email);

      if (signInMethods.contains('password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "This email is already registered using Email & Password."),
          ),
        );
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // ✅ FIRST: Check dietitianApproval collection (existing logic - don't change)
        final dietitianDoc = await FirebaseFirestore.instance
            .collection('dietitianApproval')
            .doc(user.uid)
            .get();

        // ✅ SECOND: If NOT in dietitianApproval, check Users collection for deactivation
        if (!dietitianDoc.exists) {
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            bool isDeactivated = userData?['deactivated'] ?? false;

            if (isDeactivated) {
              print('⚠️ Account is deactivated (Google Sign-In - Users collection)');
              // Sign out immediately
              await FirebaseAuth.instance.signOut();
              await googleSignIn.signOut();

              // Show deactivation dialog
              if (mounted) {
                await _showDeactivatedAccountDialog();
              }
              return false;
            }
          }
        }
      }

      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      print("Google Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to sign in with Google.")),
      );
      return false;
    }
  }

  // ==================== SnackBars ====================

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final keyboardHeight = MediaQuery
        .of(context)
        .viewInsets
        .bottom;

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
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                            maxWidth: 500,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Welcome!',
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to continue',
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 16,
                                      color: _textColorSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        _buildTextField(
                                          controller: emailController,
                                          label: 'Email',
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                          TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: passController,
                                          label: 'Password',
                                          icon: Icons.lock_outline,
                                          obscureText: _obscurePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () =>
                                                setState(() {
                                                  _obscurePassword =
                                                  !_obscurePassword;
                                                }),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: _showForgotPasswordDialog,
                                            child: Text(
                                              "Forgot Password?",
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 14,
                                                color: _primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _buildLoginButton(),
                                        const SizedBox(height: 16),
                                        _buildGoogleSignInButton(),
                                        const SizedBox(height: 16),  // ← Add this
                                        _buildTermsCheckbox(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: _getTextStyle(
                                          context,
                                          color: _textColorSecondary(context),
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                const signUpPage()),
                                          );
                                        },
                                        child: Text(
                                          "Sign Up",
                                          style: _getTextStyle(
                                            context,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
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
          ),
        ],
      ),
    );
  }
}