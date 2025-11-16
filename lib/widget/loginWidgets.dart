// Create: lib/dialogs/auth_dialogs.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/loginTheme.dart';

class AuthDialogs {
  // ==================== WELCOME DIALOG ====================
  static Widget buildWelcomeDialog(BuildContext context, AnimationController welcomeScaleController, Animation<double> welcomeScaleAnimation, Animation<double> welcomeOpacityAnimation) {
    return AnimatedBuilder(
      animation: welcomeScaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: welcomeScaleAnimation.value,
          child: Opacity(
            opacity: welcomeOpacityAnimation.value,
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
                        color: cardBgColor(context),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -50,
                              left: -80,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.06),
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
                                  color: primaryColor.withOpacity(0.06),
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
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              color: textColorOnPrimary,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome!',
                            style: getTextStyle(
                              context,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColorPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to continue your health journey',
                            textAlign: TextAlign.center,
                            style: getTextStyle(
                              context,
                              fontSize: 16,
                              color: textColorSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: textColorOnPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'Get Started',
                                style: getTextStyle(
                                  context,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColorOnPrimary,
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

  // ==================== USER ROLE DIALOG ====================
  static Future<String?> showUserRoleDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBgColor(dialogContext),
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
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_search_outlined,
                    color: primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Account Type',
                  style: getTextStyle(
                    dialogContext,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColorPrimary(dialogContext),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please choose your role to continue.',
                  textAlign: TextAlign.center,
                  style: getTextStyle(
                    dialogContext,
                    fontSize: 16,
                    color: textColorSecondary(dialogContext),
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
                      side: BorderSide(color: primaryColor, width: 1.5),
                      foregroundColor: primaryColor,
                    ),
                    icon: const Icon(Icons.person_outline, size: 20),
                    label: Text(
                      'I am a User',
                      style: getTextStyle(
                        dialogContext,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
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
                      backgroundColor: primaryColor,
                      foregroundColor: textColorOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.health_and_safety_outlined, size: 20),
                    label: Text(
                      'I am a Dietitian',
                      style: getTextStyle(
                        dialogContext,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColorOnPrimary,
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
  static Future<void> showForgotPasswordDialog(
      BuildContext context, {
        required Function(String) onSend,
        required Function(String) onError,
        required Function(String) onSuccess,
      }) async {
    TextEditingController resetEmailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardBgColor(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset_outlined,
                  color: primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Reset Password",
                style: getTextStyle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColorPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter your registered email to reset your password.",
                textAlign: TextAlign.center,
                style: getTextStyle(
                  context,
                  fontSize: 14,
                  color: textColorSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: getTextStyle(context),
                decoration: InputDecoration(
                  labelText: "Email Address",
                  labelStyle: getTextStyle(
                    context,
                    color: textColorSecondary(context),
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
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
                        style: getTextStyle(
                          context,
                          color: textColorSecondary(context),
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
                          onError("Please enter an email");
                          return;
                        }
                        try {
                          await onSend(resetEmail);
                          Navigator.pop(context);
                          onSuccess("Password reset email has been sent");
                        } on FirebaseAuthException catch (e) {
                          onError("Error: ${e.message}");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: textColorOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Send",
                        style: getTextStyle(
                          context,
                          fontWeight: FontWeight.bold,
                          color: textColorOnPrimary,
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
    resetEmailController.dispose();
  }

  // ==================== UNVERIFIED ACCOUNT DIALOG ====================
  static Future<void> showUnverifiedAccountDialog(
      BuildContext context,
      User user, {
        required Function(String) onError,
        required Function(String) onSuccess,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardBgColor(context),
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
                style: getTextStyle(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColorPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please verify your email address (${user.email}) before logging in. Check your inbox for the verification link.',
                textAlign: TextAlign.center,
                style: getTextStyle(
                  context,
                  fontSize: 14,
                  color: textColorSecondary(context),
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
                      onSuccess("Verification email sent! Check your inbox.");
                    } catch (e) {
                      if (e.toString().contains('too-many-requests')) {
                        onError("Too many requests. Please wait before trying again.");
                      } else {
                        onError("Failed to send email. Please try again later.");
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: textColorOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Resend Verification Email',
                    style: getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: textColorOnPrimary,
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
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Login',
                    style: getTextStyle(
                      context,
                      color: textColorSecondary(context),
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
    await FirebaseAuth.instance.signOut();
  }

  // ==================== DEACTIVATED ACCOUNT DIALOG ====================
  static Future<void> showDeactivatedAccountDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardBgColor(context),
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
                style: getTextStyle(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColorPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account has been deactivated by the administrator. Please contact support for more information.',
                textAlign: TextAlign.center,
                style: getTextStyle(
                  context,
                  fontSize: 14,
                  color: textColorSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: textColorOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: textColorOnPrimary,
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
}