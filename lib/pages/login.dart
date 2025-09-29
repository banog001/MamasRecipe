import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'signup.dart';
import 'home.dart';
import 'start.dart';
import '../Dietitians/homePageDietitian.dart';

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
    emailController.dispose();
    passController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _goSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const signUpPage()),
    );
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
                      const SizedBox(height: 80),

                      _buildHeaderSection(),
                      const SizedBox(height: 50),

                      Card(
                        elevation: 8,
                        shadowColor: _primaryColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: _cardBgColor(context),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: passController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _textColorSecondary(context),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: Text(
                                    "Forgot Password?",
                                    style: _getTextStyle(
                                      context,
                                      color: _primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildLoginButton(),
                              const SizedBox(height: 20),

                              _buildDivider(),
                              const SizedBox(height: 20),

                              _buildGoogleSignInButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSignUpLink(),
                      const SizedBox(height: 40),
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
          width: 80,
          height: 80,
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
            Icons.health_and_safety_outlined,
            color: _textColorOnPrimary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: _getTextStyle(
            context,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _textColorPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your health journey',
          style: _getTextStyle(
            context,
            fontSize: 16,
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
        prefixIcon: Icon(icon, color: _primaryColor, size: 22),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Image.asset(
          'assets/google_logo.png', // You'll need to add this asset
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

  Widget _buildSignUpLink() {
    return Center(
      child: TextButton(
        onPressed: _goSignUp,
        child: RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: _getTextStyle(
              context,
              fontSize: 14,
              color: _textColorSecondary(context),
            ),
            children: [
              TextSpan(
                text: 'Sign Up',
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
      await _handlePostLogin(userCredential.user!);
    } catch (err) {
      _showErrorSnackBar("Login failed: ${err.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      bool isLogged = await loginWithGoogle();
      if (isLogged && FirebaseAuth.instance.currentUser != null) {
        await _handlePostLogin(FirebaseAuth.instance.currentUser!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    TextEditingController resetEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  prefixIcon: Icon(Icons.email_outlined, color: _primaryColor),
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
                        String resetEmail = resetEmailController.text.trim();
                        if (resetEmail.isEmpty) {
                          _showErrorSnackBar("Please enter an email");
                          return;
                        }
                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: resetEmail);
                          Navigator.pop(context);
                          _showSuccessSnackBar("Password reset email has been sent");
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

  Future<void> _updateUserStatus(String uid, bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection("Users").doc(uid).update({
        "status": isOnline ? "online" : "offline",
        "lastSeen": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;

      List<String> signInMethods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(googleUser.email);

      if (signInMethods.contains('password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This email is already registered using Email & Password."),
          ),
        );
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      print("Google Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to sign in with Google.")),
      );
      return false;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    String displayName = user.displayName ?? "";
    List<String> nameParts = displayName.split(" ");
    String firstName = nameParts.isNotEmpty ? nameParts.first : "";
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

    final docRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        "email": user.email,
        "firstName": firstName,
        "lastName": lastName,
        "age": null,
        "goals": null,
        "status": "online",
        "lastSeen": FieldValue.serverTimestamp(),
        "hasCompletedTutorial": false,
        "tutorialStep": 0,
        "role": "user", // 👈 Add default role
      });
    } else {
      await _updateUserStatus(user.uid, true);
    }
  }

  Future<void> _handlePostLogin(User user) async {
    await user.reload();
    user = FirebaseAuth.instance.currentUser!;

    final docRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      // Save new user with default role = "user"
      await _saveUserToFirestore(user);
    } else {
      await _updateUserStatus(user.uid, true);
    }

    // ✅ Get role and tutorial status
    String role = docSnap.data()?['role'] ?? "user";
    bool hasCompletedTutorial = docSnap.data()?['hasCompletedTutorial'] ?? false;

    if (hasCompletedTutorial) {
      if (role == "dietitian") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageDietitian()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const home()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MealPlanningScreen(userId: user.uid)),
      );
    }
  }
}
