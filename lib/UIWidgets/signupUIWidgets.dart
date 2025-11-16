import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/signupTheme.dart';
import '../functions/signupFunctions.dart';
import 'dart:async';

class SignupUIWidgets {
  // ==================== BUILD BACKGROUND SHAPES ====================
  static Widget buildBackgroundShapes(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: scaffoldBgColor(context),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
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
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD HEADER SECTION ====================
  static Widget buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_outlined,
            color: textColorOnPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Create Account',
          style: getTextStyle(
            context,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColorPrimary(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Join us to start your health journey',
          style: getTextStyle(
            context,
            fontSize: 13,
            color: textColorSecondary(context),
          ),
        ),
      ],
    );
  }

  // ==================== SHOW VERIFICATION DIALOG ====================
  static Future<void> showVerificationDialog(
      BuildContext context, {
        required User user,
        required Function() onVerified,
        required Function(String) onError,
      }) async {
    Timer? verificationTimer;

    verificationTimer = SignupFunctions.startAutoVerificationCheck(
      user,
          (verified) {
        if (context.mounted) {
          Navigator.of(context).pop();
          onVerified();
        }
      },
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async {
          verificationTimer?.cancel();
          return true;
        },
        child: Dialog(
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
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: textColorOnPrimary, size: 44),
                ),
                const SizedBox(height: 18),
                Text(
                  'Verify your email',
                  style: getTextStyle(context,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColorPrimary(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification link to ${user.email}. Click the link in your email to verify your account.',
                  textAlign: TextAlign.center,
                  style: getTextStyle(context,
                      fontSize: 14, color: textColorSecondary(context)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for verification...',
                      style: getTextStyle(context,
                          fontSize: 13,
                          color: textColorSecondary(context),
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () async {
                      bool isVerified = await SignupFunctions.tryVerifyManually(user);
                      if (isVerified) {
                        if (context.mounted) Navigator.of(context).pop();
                        onVerified();
                      } else {
                        onError("Email not verified yet. Please check your inbox.");
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
                      'I\'ve Verified My Email',
                      style: getTextStyle(context,
                          fontWeight: FontWeight.bold, color: textColorOnPrimary),
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Verification email resent!")),
                          );
                        }
                      } catch (e) {
                        onError("Failed to resend email. Please try again.");
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Resend Email',
                      style: getTextStyle(context, color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    verificationTimer?.cancel();
  }

  // ==================== SHOW SUCCESS DIALOG ====================
  static void showSuccessDialog(
      BuildContext context, {
        required VoidCallback onOk,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
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
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: textColorOnPrimary, size: 50),
                ),
                const SizedBox(height: 20),
                Text(
                  'Email Verified!',
                  style: getTextStyle(
                    context,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColorPrimary(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your email has been verified! You can now log in to your account.',
                  textAlign: TextAlign.center,
                  style: getTextStyle(
                    context,
                    fontSize: 16,
                    color: textColorSecondary(context),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOk();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: textColorOnPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue to Login',
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
        );
      },
    );
  }
}