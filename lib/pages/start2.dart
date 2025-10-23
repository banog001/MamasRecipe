import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start3.dart'; // For regular users
import 'start3_dietitian.dart'; // For dietitians
import 'home.dart';
import '../Dietitians/homePageDietitian.dart';

// --- Theme Helpers ---
const String _primaryFontFamily = 'PlusJakartaSans';

const Color _primaryColor = Color(0xFF4CAF50);
Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
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
      double? height,
    }) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    height: height,
  );
}
// --- End Theme Helpers ---

class MealPlanningScreen2 extends StatefulWidget {
  final String userId;
  const MealPlanningScreen2({super.key, required this.userId});

  @override
  State<MealPlanningScreen2> createState() => _MealPlanningScreen2State();
}

class _MealPlanningScreen2State extends State<MealPlanningScreen2> {
  late Future<String> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _getUserRole();
  }

  Future<String> _getUserRole() async {
    final firestore = FirebaseFirestore.instance;
    // Check dietitianApproval first
    final dietitianDoc = await firestore
        .collection('dietitianApproval')
        .doc(widget.userId)
        .get();
    if (dietitianDoc.exists) {
      return 'dietitian';
    }
    // Fallback to checking Users
    return 'user';
  }

  Future<void> _updateTutorialStep(int step) async {
    String collection = await _userRoleFuture; // 'user' or 'dietitian'
    if (collection == 'dietitian') {
      collection = 'dietitianApproval';
    } else {
      collection = 'Users';
    }

    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.userId)
          .update({
        'tutorialStep': step,
      });
    } catch (e) {
      print("Error updating tutorial step for $widget.userId: $e");
    }
  }



  Future<void> _nextScreen(BuildContext context, String role) async {
    // Update tutorial progress
    await _updateTutorialStep(2);

    if (role == 'dietitian') {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MealPlanningScreen3Dietitian(userId: widget.userId),
          ),
        );
      }
    } else {
      // Regular user
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MealPlanningScreen3(userId: widget.userId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _userRoleFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final role = snapshot.data!;
            final bool isDietitian = role == 'dietitian';

            // --- Set dynamic text based on role ---
            final String title = isDietitian
                ? 'Client Plan Management'
                : 'Personalized Meal Plans';
            final String subtitle = isDietitian
                ? 'Create, manage, and share your expert meal plans with clients seamlessly.'
                : 'Get meal plans tailored to your health goals, preferences, and dietary needs.';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: <Widget>[
                  // --- Skip Button ---
                  const Spacer(flex: 1),

                  // --- Main Content ---
                  Image.asset(
                    'lib/assets/image/start2.png',
                    height: MediaQuery.of(context).size.height * 0.35,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title, // Dynamic Title
                    textAlign: TextAlign.center,
                    style: _getTextStyle(
                      context,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                      height: 1.3,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subtitle, // Dynamic Subtitle
                    textAlign: TextAlign.center,
                    style: _getTextStyle(
                      context,
                      fontSize: 16,
                      color: _textColorSecondary(context),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 2),

                  // --- "NEXT" Button ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          shape: RoundedRectangleBorder( // <-- Typo Fixed
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: _primaryColor.withOpacity(0.3),
                        ),
                        onPressed: () => _nextScreen(context, role),
                        child: Text(
                          'NEXT',
                          style: _getTextStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColorOnPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}