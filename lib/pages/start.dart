import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start2.dart'; // Assuming MealPlanningScreen2 is correctly imported

class MealPlanningScreen extends StatelessWidget {
  final String userId;

  const MealPlanningScreen({super.key, required this.userId});

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
      fontSize: 28, // More impactful title
      fontWeight: FontWeight.w800, // ExtraBold for title
      color: Color(0xFF333333), // Dark primary text color
      height: 1.2, // Tighter line height for multi-line title
      letterSpacing: 0.3);

  static const TextStyle _stepTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.grey, // Subtle step indicator
      letterSpacing: 0.5);

  static const TextStyle _subHeadlineStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 16, // Clear and readable
      fontWeight: FontWeight.normal,
      color: Colors.black54, // Good contrast
      height: 1.5,
      letterSpacing: 0.2);

  static const TextStyle _buttonTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5, // More spacing
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
                      const SizedBox(height: 40), // Initial spacing

                      // Step Indicator
                      const Text(
                        'Step 1 of 4: Welcome!',
                        style: _stepTextStyle,
                      ),
                      const SizedBox(height: 30),

                      // Enhanced Image Presentation
                      Container(
                        width: 230, // Slightly larger
                        height: 230,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, // Ensure it's on a solid background if shadow is used
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3), // Softer shadow
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 4), // changes position of shadow
                              ),
                            ],
                            border: Border.all( // Optional: subtle border
                              color: Colors.green.shade100,
                              width: 3,
                            )
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'lib/assets/image/plate.jpg', // Ensure this path is correct
                            fit: BoxFit.cover,
                            // Error builder for image if it fails to load
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Headline
                      const Text(
                        'Smart Meal Planning\nAt Your Fingertips!', // Added exclamation for energy
                        textAlign: TextAlign.center,
                        style: _screenTitleStyle,
                      ),
                      const SizedBox(height: 18),

                      // Sub-headline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Consistent padding
                        child: Text(
                          'No more guessing what to eat. Get personalized meal suggestions tailored to your unique goals and preferences.', // Slightly rephrased
                          textAlign: TextAlign.center,
                          style: _subHeadlineStyle,
                        ),
                      ),
                      const SizedBox(height: 40),

                      if (userId.isNotEmpty)
                        Text(
                          "UID: $userId", // For debugging
                          style: _smallDebugTextStyle,
                        ),
                      const SizedBox(height: 20), // Space before button area conceptually
                    ],
                  ),
                ),
              ),

              // GET STARTED Button
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, top: 20.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85, // Wider button
                  height: 60, // Taller button
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50), // Your theme green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // More modern radius
                      ),
                      elevation: 4, // More prominent shadow
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
                    child: const Text(
                      'GET STARTED',
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

