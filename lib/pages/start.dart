import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start2.dart'; // Assuming MealPlanningScreen2 is correctly imported

// --- Theme Helpers ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);

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

const Color _textColorOnPrimary = Colors.white;

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

class MealPlanningScreen extends StatelessWidget {
  final String userId;

  const MealPlanningScreen({super.key, required this.userId});

  // --- Functions (Only _updateTutorialStep remains) ---
  Future<void> _updateTutorialStep(int step) async {
    // Determine user's collection (Users or dietitianApproval)
    final firestore = FirebaseFirestore.instance;
    String collectionPath = 'Users'; // Default to Users

    final dietitianDoc =
    await firestore.collection('dietitianApproval').doc(userId).get();
    if (dietitianDoc.exists) {
      collectionPath = 'dietitianApproval';
    }

    try {
      await firestore.collection(collectionPath).doc(userId).update({
        'tutorialStep': step,
      });
      print("Tutorial step updated to $step for user $userId in $collectionPath");
    } catch (e) {
      print("Error updating tutorial step for user $userId in $collectionPath: $e");
      // Optionally, try the other collection as a fallback if needed,
      // but ideally the role is known by now.
    }
  }
  // --- End Functions ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context), // Use theme color
      body: Stack( // Wrap body with Stack for background
        children: [
          _buildBackgroundShapes(context), // Add background
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: <Widget>[
                  // --- Skip Button Removed ---
                  // Added SizedBox to maintain similar top spacing
                  const SizedBox(height: 56), // Adjust height as needed (was roughly TextButton height + padding)

                  const Spacer(flex: 1), // Pushes content down slightly

                  // --- Main Content ---
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ]
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'lib/assets/image/plate.jpg', // Ensure path is correct
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: _primaryColor.withOpacity(0.1),
                                child: Icon(Icons.restaurant_menu_outlined, size: 80, color: _primaryColor.withOpacity(0.5)),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Headline
                      Text(
                        'Smart Meal Planning\nAt Your Fingertips!',
                        textAlign: TextAlign.center,
                        style: _getTextStyle(
                          context,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor, // Use primary color for title
                          height: 1.3,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub-headline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'No more guessing what to eat. Get personalized meal suggestions tailored to your unique goals and preferences.',
                          textAlign: TextAlign.center,
                          style: _getTextStyle(
                            context,
                            fontSize: 16,
                            color: _textColorSecondary(context),
                            height: 1.5, // Use height for line spacing
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2), // Pushes button to bottom

                  // --- "GET STARTED" Button ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0), // Consistent bottom padding
                    child: SizedBox(
                      width: double.infinity, // Full width button
                      height: 56, // Standard button height
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), // Match login/signup
                          ),
                          elevation: 4, // Consistent elevation
                          shadowColor: _primaryColor.withOpacity(0.3),
                        ),
                        onPressed: () async {
                          await _updateTutorialStep(1);
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MealPlanningScreen2(userId: userId),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'GET STARTED',
                          style: _getTextStyle(
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
