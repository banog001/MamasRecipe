import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start3.dart';
import 'start3_dietitian.dart'; // Import the new dietitian screen

class MealPlanningScreen2 extends StatelessWidget {
  final String userId;

  const MealPlanningScreen2({super.key, required this.userId});

  Future<void> _updateTutorialStep(int step) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'tutorialStep': step,
      });
    } catch (e) {
      print("Error updating tutorial step for user $userId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const String _primaryFontFamily = 'PlusJakartaSans';

    const TextStyle _screenTitleStyle = TextStyle(
        fontFamily: _primaryFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4CAF50),
        height: 1.3,
        letterSpacing: 0.3);

    const TextStyle _buttonTextStyle = TextStyle(
        fontFamily: _primaryFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Your existing UI for start2.dart
              Image.asset(
                'assets/start2.png',
                height: MediaQuery.of(context).size.height * 0.4,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: Text(
                  'Personalized Meal Plans',
                  textAlign: TextAlign.center,
                  style: _screenTitleStyle,
                ),
              ),

              // The "NEXT" button
              Padding(
                padding:
                const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0, top: 20.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      // Update tutorial progress if needed
                      await _updateTutorialStep(2);

                      final firestore = FirebaseFirestore.instance;

                      // Check if user is in dietitianApproval
                      final dietitianDoc = await firestore
                          .collection('dietitianApproval')
                          .doc(userId)
                          .get();

                      if (dietitianDoc.exists) {
                        // ✅ Dietitian found
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealPlanningScreen3Dietitian(userId: userId),
                            ),
                          );
                        }
                        return;
                      }

                      // Otherwise, check if user is in Users
                      final userDoc = await firestore.collection('Users').doc(userId).get();

                      if (userDoc.exists) {
                        // ✅ Regular user found
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealPlanningScreen3(userId: userId),
                            ),
                          );
                        }
                        return;
                      }

                      // ❌ No record found (optional)
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User not found in any collection.")),
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