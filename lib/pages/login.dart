import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _welcomeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.elasticOut),
    );

    _welcomeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeInOut),
    );

    // Show welcome popup automatically
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
        // Start main screen animations after dialog closes
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
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _cardBgColor(context),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
            ),
          ),
        );
      },
    );
  }

  Future<String?> _askUserRoleDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Select Account Type"),
          content: const Text("Are you signing in as a User or a Dietitian?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, "user"),
              child: const Text("User"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () => Navigator.pop(context, "dietitian"),
              child: const Text("Dietitian"),
            ),
          ],
        );
      },
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";
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

    final usersRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
    final userSnap = await usersRef.get();

    String role = "user";
    bool hasCompletedTutorial = false;

    // If user does NOT exist in Users collection yet, ask for role
    if (!userSnap.exists) {
      String? selectedRole = await _askUserRoleDialog();
      if (selectedRole == null) return; // user closed dialog
      role = selectedRole;

      // Extract name parts
      String displayName = user.displayName ?? "";
      List<String> nameParts = displayName.split(" ");
      String firstName = nameParts.isNotEmpty ? nameParts.first : "";
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

      // ✅ Save to Users collection
      if(role == "user") {
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
          "role": role,
          "qrapproved": false,
          "creationDate": FieldValue.serverTimestamp(),
        });
      }

      // ✅ If dietitian, also create record in DietitianApplications
      if (role == "dietitian") {
        final dietitianRef = FirebaseFirestore.instance
            .collection("dietitianApproval")
            .doc(user.uid);

        await dietitianRef.set({
          "email": user.email ?? "",
          "firstName": firstName,
          "lastName": lastName,
          "licenseNum": null,
          "prcImageurl": null,
          "status": "pending",
          "role": "dietitian",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

    } else {
      // Existing user
      role = userSnap.data()?['role'] ?? "user";
      hasCompletedTutorial = userSnap.data()?['hasCompletedTutorial'] ?? false;

      // Update status
      await usersRef.set({
        "status": "online",
        "lastSeen": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 🔀 Navigate depending on role
    if (role == "dietitian") {
      final dietitianDocId = user.uid;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MealPlanningScreen(userId: dietitianDocId),
        ),
      );
    } else {
      if (hasCompletedTutorial) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const home()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MealPlanningScreen(userId: user.uid),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
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
                                'Welcome Back',
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
                                      keyboardType: TextInputType.emailAddress,
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
                                        onPressed: () => setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildLoginButton(),
                                    const SizedBox(height: 16),
                                    _buildGoogleSignInButton(),
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
                                            builder: (_) => const signUpPage()),
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
    );
  }
}
