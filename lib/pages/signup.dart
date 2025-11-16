import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mamas_recipe/widget/custom_snackbar.dart';

// Import your separated modules
import '../theme/signupTheme.dart';
import '../functions/signupFunctions.dart';
import '../widget/signupWidgets.dart';
import '../UIWidgets/signupUIWidgets.dart';
import 'login.dart';

class signUpPage extends StatefulWidget {
  const signUpPage({super.key});

  @override
  State<signUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<signUpPage> with TickerProviderStateMixin {
  // ==================== FORM & CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ==================== STATE VARIABLES ====================
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // ==================== ANIMATION CONTROLLERS ====================
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

  // ==================== NAVIGATE TO LOGIN ====================
  void _goLogIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPageMobile()),
    );
  }

  // ==================== SHOW ERROR SNACKBAR ====================
  void _showErrorSnackBar(String message) {
    CustomSnackBar.show(
      context,
      message,
      backgroundColor: Colors.redAccent,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 4),
    );
  }

  // ==================== SHOW SUCCESS SNACKBAR ====================
  void _showSuccessSnackBar(String message) {
    CustomSnackBar.show(
      context,
      message,
      backgroundColor: primaryColor,
      icon: Icons.check_circle_outline,
      duration: const Duration(seconds: 3),
    );
  }

  // ==================== HANDLE REGISTER USER ====================
  Future<void> _handleRegisterUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final fName = _firstNameController.text.trim();
    final lName = _lastNameController.text.trim();
    final mail = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      User? user = await SignupFunctions.registerUser(mail, password, fName, lName);

      if (user != null) {
        if (!user.emailVerified) {
          if (mounted) {
            setState(() => _isLoading = false);
            await SignupUIWidgets.showVerificationDialog(
              context,
              user: user,
              onVerified: () async {
                await SignupFunctions.markUserAsVerified(user, fName, lName);
                SignupUIWidgets.showSuccessDialog(
                  context,
                  onOk: _goLogIn,
                );
              },
              onError: _showErrorSnackBar,
            );
          }
        } else {
          await SignupFunctions.markUserAsVerified(user, fName, lName);
          if (mounted) {
            setState(() => _isLoading = false);
            SignupUIWidgets.showSuccessDialog(
              context,
              onOk: _goLogIn,
            );
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

  // ==================== HANDLE GOOGLE SIGN IN ====================
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      User? user = await SignupFunctions.signInWithGoogle();

      if (user != null && mounted) {
        setState(() => _isLoading = false);
        SignupUIWidgets.showSuccessDialog(
          context,
          onOk: _goLogIn,
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: scaffoldBgColor(context),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background shapes
          SignupUIWidgets.buildBackgroundShapes(context),

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

                                  // Header section
                                  SignupUIWidgets.buildHeaderSection(context),
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
                                            // First name field
                                            SignupWidgets.buildTextField(
                                              context: context,
                                              controller: _firstNameController,
                                              label: 'First Name',
                                              icon: Icons.person_outline,
                                              validator: (v) =>
                                              (v == null || v.isEmpty) ? 'Enter your first name' : null,
                                            ),
                                            const SizedBox(height: 12),

                                            // Last name field
                                            SignupWidgets.buildTextField(
                                              context: context,
                                              controller: _lastNameController,
                                              label: 'Last Name',
                                              icon: Icons.person_outline,
                                              validator: (v) =>
                                              (v == null || v.isEmpty) ? 'Enter your last name' : null,
                                            ),
                                            const SizedBox(height: 12),

                                            // Email field
                                            SignupWidgets.buildTextField(
                                              context: context,
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

                                            // Password field
                                            SignupWidgets.buildTextField(
                                              context: context,
                                              controller: _passwordController,
                                              label: 'Password',
                                              icon: Icons.lock_outline,
                                              obscureText: !_isPasswordVisible,
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isPasswordVisible
                                                      ? Icons.visibility_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: textColorSecondary(context),
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
                                                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                                  return 'Password must contain at least 1 uppercase letter';
                                                }
                                                if (!RegExp(r'[a-z]').hasMatch(value)) {
                                                  return 'Password must contain at least 1 lowercase letter';
                                                }
                                                if (!RegExp(r'[0-9]').hasMatch(value)) {
                                                  return 'Password must contain at least 1 number';
                                                }
                                                if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                                                  return 'Password must contain at least 1 special character';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 12),

                                            // Confirm password field
                                            SignupWidgets.buildTextField(
                                              context: context,
                                              controller: _confirmPasswordController,
                                              label: 'Confirm Password',
                                              icon: Icons.lock_outline,
                                              obscureText: !_isConfirmPasswordVisible,
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isConfirmPasswordVisible
                                                      ? Icons.visibility_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: textColorSecondary(context),
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

                                            // Sign up button
                                            SignupWidgets.buildSignUpButton(
                                              context,
                                              isLoading: _isLoading,
                                              onPressed: _handleRegisterUser,
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Login link
                                  SignupWidgets.buildLoginLink(
                                    context,
                                    onPressed: _goLogIn,
                                  ),
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
}