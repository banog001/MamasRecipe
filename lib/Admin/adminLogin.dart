import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adminHome.dart'; // Make sure this import is correct for your project

// --- THEME CONSTANTS ---
const String _primaryFontFamily = 'PlusJakartaSans';

// --- DARK THEME COLOR PALETTE ---
const Color _backgroundColor = Color(0xFF121212); // Deep charcoal background
const Color _surfaceColor = Color(0xFF1E1E1E); // Slightly lighter for input fields
const Color _primaryAccentColor = Color(0xFF0D63F5); // A professional, vibrant blue
const Color _textColor = Colors.white;
const Color _hintColor = Color(0xFFAAAAAA); // A subtle grey for hints and labels
const Color _errorColor = Color(0xFFCF6679); // Material Design standard error color for dark themes

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  String _error = '';
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user?.uid;

      if (uid != null) {
        final doc = await _firestore.collection('Users').doc(uid).get();

        if (doc.exists && doc['role'] == 'admin') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHome()),
            );
          }
        } else {
          setState(() {
            _error = 'Access denied. You are not an administrator.';
          });
          await _auth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please try again.';
          break;
        default:
          errorMessage = 'An unexpected error occurred. Please try again.';
      }
      setState(() {
        _error = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER SECTION ---
                const Icon(
                  Icons.shield_outlined,
                  size: 60,
                  color: _primaryAccentColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  "PAPA'S SECURITY",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: _primaryFontFamily,
                    color: _textColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Administrator Access',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: _primaryFontFamily,
                    color: _hintColor,
                  ),
                ),
                const SizedBox(height: 40),

                // --- EMAIL INPUT ---
                TextField(
                  controller: _emailController,
                  style: const TextStyle(fontFamily: _primaryFontFamily, color: _textColor),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 20),

                // --- PASSWORD INPUT ---
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontFamily: _primaryFontFamily, color: _textColor),
                  decoration: _buildInputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: _hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- ERROR MESSAGE DISPLAY ---
                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _errorColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: _errorColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error,
                            style: const TextStyle(
                              color: _errorColor,
                              fontFamily: _primaryFontFamily,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_error.isNotEmpty) const SizedBox(height: 24),

                // --- SIGN IN BUTTON ---
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryAccentColor,
                      foregroundColor: _textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: _primaryAccentColor.withOpacity(0.5),
                    ),
                    child: _loading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: _primaryFontFamily,
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
  }

  // --- HELPER METHOD FOR INPUT DECORATION ---
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(fontFamily: _primaryFontFamily, color: _hintColor),
      prefixIcon: Icon(prefixIcon, color: _hintColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryAccentColor, width: 2),
      ),
    );
  }
}
