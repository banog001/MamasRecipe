
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'home.dart';
import 'start.dart';
import '../Dietitians/homePageDietitian.dart';
import 'termsAndConditions.dart';
import 'package:flutter/gestures.dart';
import 'package:mamas_recipe/widget/custom_snackbar.dart';

// Import your new modules
import '../theme/loginTheme.dart';
import '../functions/loginFunctions.dart';
import '../widget/loginWidgets.dart';
import '../UIWidgets/loginUIWidgets.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});
  @override
  State<LoginPageMobile> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageMobile>
    with TickerProviderStateMixin {
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

  // Initialize Firebase service
  final _authService = FirebaseAuthService();


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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _welcomeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.elasticOut),
    );

    _welcomeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeInOut),
    );

    emailController.addListener(_onEmailChanged);
    _showWelcomePopup();
  }

  // Show welcome popup on page load
  void _showWelcomePopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeController.forward();
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (context) => AuthDialogs.buildWelcomeDialog(
          context,
          _welcomeController,
          _welcomeScaleAnimation,
          _welcomeOpacityAnimation,
        ),
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

  // ==================== ASK USER ROLE ====================
  Future<String?> _askUserRoleDialog() async {
    return AuthDialogs.showUserRoleDialog(context);
  }

  // Check terms agreement when email changes
  void _onEmailChanged() {
    final email = emailController.text.trim();
    if (email.isNotEmpty && email.contains('@')) {
      _checkTermsAgreementStatus(email);
    }
  }

  // Check if user already agreed to terms
  Future<void> _checkTermsAgreementStatus(String email) async {
    bool hasAgreed = await _authService.checkTermsAgreementStatus(email);
    if (mounted) {
      setState(() {
        _agreedToTerms = hasAgreed;
      });
    }
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() async {
    await AuthDialogs.showForgotPasswordDialog(
      context,
      onSend: _authService.sendPasswordResetEmail,
      onError: _showErrorSnackBar,
      onSuccess: _showSuccessSnackBar,
    );
  }

  // Handle email/password login
  Future<void> _handleLogin() async {
    String email = emailController.text.trim();
    String pass = passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showErrorSnackBar("Please fill in all fields");
      return;
    }

    if (!_agreedToTerms) {
      _showErrorSnackBar("Please agree to the Terms and Conditions");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential = await _authService.signInWithEmailPassword(email, pass);

      if (userCredential?.user != null) {
        User user = userCredential!.user!;
        print('🔵 User logged in: ${user.uid}');

        // Check if email is verified
        await user.reload();
        user = FirebaseAuth.instance.currentUser!;

        if (!user.emailVerified) {
          print('⚠️ User email not verified: ${user.email}');
          if (mounted) {
            setState(() => _isLoading = false);
            await _showUnverifiedAccountDialog(user);
          }
          return;
        }

        print('✅ User email verified: ${user.email}');

        // Email verified - proceed with post-login logic
        await _handlePostLogin(user);
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

  // Handle postLogin
  Future<void> _handlePostLogin(User user) async {
    await user.reload();
    user = FirebaseAuth.instance.currentUser!;

    final usersRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
    final dietitianRef = FirebaseFirestore.instance.collection("dietitianApproval").doc(user.uid);

    DocumentSnapshot userSnap = await usersRef.get();
    DocumentSnapshot dietitianSnap = await dietitianRef.get();

    String role = "user";
    bool hasCompletedTutorial = false;

    // Case 1: User exists in Users collection
    if (userSnap.exists) {
      final userData = userSnap.data() as Map<String, dynamic>?;
      role = userData?['role'] ?? "user";
      hasCompletedTutorial = userData?['hasCompletedTutorial'] ?? false;
      bool isDeactivated = userData?['deactivated'] ?? false;

      if (isDeactivated) {
        if (mounted) {
          setState(() => _isLoading = false);
          await AuthDialogs.showDeactivatedAccountDialog(context);
        }
        return;
      }

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

    // Case 2: User exists in dietitianApproval collection
    if (dietitianSnap.exists) {
      final dietitianData = dietitianSnap.data() as Map<String, dynamic>?;
      String status = dietitianData?['status'] ?? 'pending';
      bool isDeactivated = dietitianData?['deactivated'] ?? false;

      if (isDeactivated) {
        if (mounted) {
          setState(() => _isLoading = false);
          await AuthDialogs.showDeactivatedAccountDialog(context);
        }
        return;
      }

      if (status == 'pending') {
        if (mounted) {
          setState(() => _isLoading = false);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Account Review',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your account is being reviewed by the admins. Please wait for approval. Thank you!',
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        FirebaseAuth.instance.signOut();
                      },
                      child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return;
      } else if (status == 'approved') {
        bool hasCompletedTutorial = dietitianData?['hasCompletedTutorial'] ?? false;
        if (hasCompletedTutorial) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePageDietitian()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MealPlanningScreen(userId: user.uid)),
          );
        }
      } else if (status == 'rejected') {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar("Your dietitian application was not approved. Please contact support.");
          await FirebaseAuth.instance.signOut();
        }
      }
      return;
    }

    // Case 3: New user - ask for role
    String? selectedRole = await _askUserRoleDialog();
    if (selectedRole == null) {
      await FirebaseAuth.instance.signOut();
      setState(() => _isLoading = false);
      return;
    }

    String displayName = user.displayName ?? "";
    List<String> nameParts = displayName.split(" ");
    String firstName = nameParts.isNotEmpty ? nameParts.first : "";
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

    if (selectedRole == "user") {
      await _authService.createRegularUserDocument(user, firstName, lastName);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MealPlanningScreen(userId: user.uid)),
      );
    } else if (selectedRole == "dietitian") {
      await _authService.createDietitianDocument(user, firstName, lastName);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MealPlanningScreen(userId: user.uid)),
      );
    }
  }

  // Show unverified account dialog
  Future<void> _showUnverifiedAccountDialog(User user) async {
    await AuthDialogs.showUnverifiedAccountDialog(
      context,
      user,
      onError: _showErrorSnackBar,
      onSuccess: _showSuccessSnackBar,
    );
    await FirebaseAuth.instance.signOut();
  }

  // Show deactivated account dialog
  Future<void> _showDeactivatedAccountDialog() async {
    await AuthDialogs.showDeactivatedAccountDialog(context);
    await FirebaseAuth.instance.signOut();
  }

  // Handle Google sign in
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      bool isLogged = await _authService.loginWithGoogle();
      if (isLogged && _authService.currentUser != null) {
        User? user = _authService.currentUser;
        print('✅ Google Sign-In successful');

        if (!_agreedToTerms) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showErrorSnackBar("Please agree to the Terms and Conditions");
          }
          return;
        }

        await _handlePostLogin(user!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    CustomSnackBar.show(
      context,
      message,
      backgroundColor: Colors.redAccent,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 4),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    CustomSnackBar.show(
      context,
      message,
      backgroundColor: const Color(0xFF4CAF50),
      icon: Icons.check_circle_outline,
      duration: const Duration(seconds: 3),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor(context),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background decorative shapes
          AuthUIWidgets.buildBackgroundShapes(context),

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Title
                                  Text(
                                    'Welcome!',
                                    style: getTextStyle(
                                      context,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Subtitle
                                  Text(
                                    'Sign in to continue',
                                    style: getTextStyle(
                                      context,
                                      fontSize: 16,
                                      color: textColorSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Form with email and password fields
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        // Email field
                                        AuthUIWidgets.buildTextField(
                                          context,
                                          controller: emailController,
                                          label: 'Email',
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 16),
                                        // Password field
                                        AuthUIWidgets.buildTextField(
                                          context,
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
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            }),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Forgot password link
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: _showForgotPasswordDialog,
                                            child: Text(
                                              "Forgot Password?",
                                              style: getTextStyle(
                                                context,
                                                fontSize: 14,
                                                color: primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // Login button
                                        AuthUIWidgets.buildLoginButton(
                                          context,
                                          isLoading: _isLoading,
                                          onPressed: _handleLogin,
                                        ),
                                        const SizedBox(height: 16),
                                        // Google sign in button
                                        AuthUIWidgets.buildGoogleSignInButton(
                                          context,
                                          isLoading: _isLoading,
                                          onPressed: _handleGoogleSignIn,
                                        ),
                                        const SizedBox(height: 16),
                                        // Terms checkbox
                                        AuthUIWidgets.buildTermsCheckbox(
                                          context,
                                          agreedToTerms: _agreedToTerms,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreedToTerms = value;
                                            });
                                          },
                                          onTapTerms: () =>
                                              showTermsAndConditions(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Sign up link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: getTextStyle(
                                          context,
                                          color: textColorSecondary(context),
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const signUpPage(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Sign Up",
                                          style: getTextStyle(
                                            context,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: primaryColor,
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

