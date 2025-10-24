import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// No need for FirebaseAuth here if we pass userId directly to completeTutorial
// import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // Assuming home.dart is correctly set up
import '../Dietitians/homePageDietitian.dart';
import 'login.dart';


// --- Theme Helpers (Copied from other files) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white; // Changed to white

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

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle,
      double? height, // Added height parameter
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
    height: height, // Use height parameter
  );
}
// --- End Theme Helpers ---

// --- Background Shapes Widget ---
Widget _buildBackgroundShapes(BuildContext context) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: _scaffoldBgColor(context), // Use theme background color
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
// --- End Background Shapes Widget ---

class MealPlanningScreen4 extends StatelessWidget {
  final String userId; // 👈 Accept userId

  const MealPlanningScreen4({super.key, required this.userId});

  // ✅ Mark tutorial as completed and update tutorialStep for the user
  // Now takes userId as a parameter
  Future<void> _completeTutorial(BuildContext context, String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final dietitianRef = FirebaseFirestore.instance
          .collection('dietitianApproval')
          .doc(currentUserId);
      final dietitianDoc = await dietitianRef.get();

      if (dietitianDoc.exists) {
        // ✅ Update tutorial step for dietitian
        await dietitianRef.update({
          'hasCompletedTutorial': true,
          'tutorialStep': 4,
        });

        print("ℹ️ Dietitian tutorial completed: $currentUserId");

        // ✅ Show modal before sending back to login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Account Review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your account will be reviewed by the admins. '
                        'Please go back to login and wait for approval. Thank you!',
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
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
                        Navigator.of(dialogContext).pop(); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPageMobile()),
                        );
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        return; // Stop further execution
      }

      // ----------------- User logic -----------------
      final userRef = FirebaseFirestore.instance.collection('Users').doc(currentUserId);
      final userSnap = await userRef.get();

      if (!userSnap.exists) {
        print("⚠️ User not found in Users collection: $currentUserId");
        return;
      }

      // ✅ Update tutorial for regular user
      await userRef.update({
        'hasCompletedTutorial': true,
        'tutorialStep': 4,
      });

      print("✅ Tutorial completed for user: $currentUserId");

      // Navigate user to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const home()),
      );

    } catch (e) {
      print("❌ Error completing tutorial for $currentUserId: $e");
    }
  }




  void _showConfirmationDialog(BuildContext context, String currentUserId) {
    // No need to define styles here, we'll use theme helpers inside the builder

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6), // Match barrier color
      builder: (BuildContext dialogContext) { // Use dialogContext for theme helpers
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Match border radius
          ),
          backgroundColor: Colors.transparent, // Transparent dialog background
          child: ClipRRect( // Clip content and background shapes
            borderRadius: BorderRadius.circular(24),
            child: Stack( // Use Stack for background and content
              children: [
                // --- Background Shapes ---
                Positioned.fill(
                  child: Container(
                    color: _cardBgColor(dialogContext), // Base color from theme
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
                // --- End Background Shapes ---

                // --- Dialog Content ---
                Padding(
                  padding: const EdgeInsets.all(32), // Consistent padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Container (Matches Welcome Dialog)
                      Container(
                        width: 100, // Match size
                        height: 100, // Match size
                        decoration: BoxDecoration(
                          color: _primaryColor, // Use theme primary color
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon( // Use check icon
                          Icons.check_circle_outline_rounded,
                          color: _textColorOnPrimary, // Use theme color
                          size: 50, // Match size
                        ),
                      ),
                      const SizedBox(height: 24), // Consistent spacing
                      // Title Text (Use theme helper)
                      Text(
                        'Great Job!',
                        style: _getTextStyle(
                          dialogContext,
                          fontSize: 28, // Match size
                          fontWeight: FontWeight.bold,
                          color: _textColorPrimary(dialogContext), // Use theme color
                        ),
                      ),
                      const SizedBox(height: 12), // Consistent spacing
                      // Message Text (Use theme helper)
                      Text(
                        'You have successfully completed the setup!',
                        textAlign: TextAlign.center,
                        style: _getTextStyle(
                          dialogContext,
                          fontSize: 16, // Match size
                          color: _textColorSecondary(dialogContext), // Use theme color
                        ),
                      ),
                      const SizedBox(height: 32), // Consistent spacing
                      // Button (Matches Welcome Dialog button)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor, // Use theme color
                            foregroundColor: _textColorOnPrimary, // Use theme color
                            padding: const EdgeInsets.symmetric(vertical: 16), // Match padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), // Match radius
                            ),
                            elevation: 4, // Match elevation
                          ),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop(); // Close dialog first
                            await _completeTutorial(context, currentUserId);
                          },
                          child: Text( // Use theme helper for text style
                            'CONTINUE',
                            style: _getTextStyle(
                              dialogContext,
                              fontSize: 16, // Match size
                              fontWeight: FontWeight.bold,
                              color: _textColorOnPrimary, // Use theme color
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- End Dialog Content ---
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    // Moved debug style here to use theme helpers
    final TextStyle smallDebugTextStyle = _getTextStyle(
      context,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: _textColorSecondary(context),
    );

    return Scaffold(
      backgroundColor: _scaffoldBgColor(context), // Use theme color
      body: Stack( // <-- 1. Wrap with Stack
        children: [
          _buildBackgroundShapes(context), // <-- 2. Add background
          SafeArea( // <-- 3. Your original SafeArea starts here
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Removed vertical padding
              child: Column(
                children: <Widget>[
                  // Removed Spacer here, using Center alignment for main content
                  Expanded(
                    child: Column( // Use Column to center content vertically
                      mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                      children: [
                        // Icon with background circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded, // Changed Icon slightly
                            size: 72,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32), // Increased spacing
                        // Headline
                        Text(
                          'ALL SET!',
                          textAlign: TextAlign.center,
                          style: _getTextStyle(
                            context,
                            fontSize: 32, // Slightly larger
                            fontWeight: FontWeight.bold, // Bold instead of w900
                            color: _primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16), // Decreased spacing
                        // Sub-headline
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "You're ready to go! We'll take it from here — get ready for meals that feel good, taste great, and fit you perfectly.",
                            textAlign: TextAlign.center,
                            style: _getTextStyle(
                              context,
                              fontSize: 16,
                              color: _textColorSecondary(context),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40), // Spacing before debug text

                        // Debug User ID (Kept as is, but using theme style)
                        if (userId.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              "",
                              textAlign: TextAlign.center,
                              style: smallDebugTextStyle,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- "FINISH SETUP" Button --- (Moved outside Expanded Column)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0, top: 20.0), // Consistent bottom padding
                    child: SizedBox(
                      width: double.infinity, // Full width
                      height: 56, // Standard height
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), // Consistent radius
                          ),
                          elevation: 4, // Consistent elevation
                          shadowColor: _primaryColor.withOpacity(0.3),
                        ),
                        onPressed: () => _showConfirmationDialog(context, userId),
                        child: Text(
                          'FINISH SETUP',
                          style: _getTextStyle( // Use theme helper
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColorOnPrimary,
                            letterSpacing: 0.5, // Consistent spacing
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
