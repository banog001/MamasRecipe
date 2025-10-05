import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start3.dart'; // Assuming MealPlanningScreen3 is correctly imported

class MealPlanningScreen2 extends StatelessWidget {
  final String userId;

  const MealPlanningScreen2({super.key, required this.userId});

  Future<void> _updateTutorialStep(int step) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'tutorialStep': step,
      });
      print("Tutorial step updated to $step for user $userId");
    } catch (e) {
      print("Error updating tutorial step for user $userId: $e");
    }
  }

  // --- Define Text Styles (Assuming "Plus Jakarta Sans") ---
  static const String _primaryFontFamily = 'PlusJakartaSans';

  static const TextStyle _screenTitleStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 28, // Prominent title
      fontWeight: FontWeight.bold,
      color: Color(0xFF4CAF50), // Theme green
      height: 1.3,
      letterSpacing: 0.3);

  static const TextStyle _stepTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.grey,
      letterSpacing: 0.5);

  static const TextStyle _subHeadlineStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 16, // Clear and readable
      fontWeight: FontWeight.normal,
      color: Colors.black54, // Good contrast on white
      height: 1.5,
      letterSpacing: 0.2);

  static const TextStyle _buttonTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5, // More spacing for button text
      fontSize: 18, // Larger button text
      color: Colors.white);

  static const TextStyle _smallDebugTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.grey);
  // --- End Text Styles ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60), // Adjusted top spacing

                      // Step Indicator
                      const Text(
                        'Step 2 of 4: A Little About You',
                        style: _stepTextStyle,
                      ),
                      const SizedBox(height: 30),

                      // Visual Element
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            color: Colors.green.shade50, // Very light accent background
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ]
                        ),
                        child: Icon(
                          Icons.feed_outlined, // Icon representing gathering info/details
                          size: 70,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Main Headline
                      const Text(
                        'Before we proceed...', // Simplified
                        textAlign: TextAlign.center,
                        style: _screenTitleStyle,
                      ),
                      const SizedBox(height: 16), // Adjusted spacing

                      // Sub-headline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'We need a few details to understand your needs better. This helps us suggest meals that truly fit your lifestyle and health goals.', // Slightly rephrased
                          textAlign: TextAlign.center,
                          style: _subHeadlineStyle,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // if (userId.isNotEmpty)
                      //   Text(
                      //     "UID: $userId", // For debugging
                      //     style: _smallDebugTextStyle,
                      //   ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // NEXT Button
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, top: 20.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85, // Consistent wider button
                  height: 60, // Consistent taller button
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Consistent rounded corners
                      ),
                      elevation: 4, // Slightly more pronounced shadow
                    ),
                    onPressed: () async {
                      await _updateTutorialStep(2);
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MealPlanningScreen3(
                              userId: userId,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'NEXT',
                      style: _buttonTextStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
