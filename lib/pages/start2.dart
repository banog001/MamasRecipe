import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'start3.dart';

class MealPlanningScreen2 extends StatelessWidget {
  final String userId; // 👈 Receive UID

  const MealPlanningScreen2({super.key, required this.userId});

  // Save tutorial step to Firestore
  Future<void> _updateTutorialStep(int step) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'tutorialStep': step,
      });
    } catch (e) {
      print("Error updating tutorial step: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          width: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Text(
                  'Before we proceed, we need to gather a few details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'This helps us understand your needs better so we can suggest meals that truly fit your lifestyle and health goals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Show UID just for testing
                Text(
                  "User ID: $userId",
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      // ✅ Update Firestore tutorial step before navigating
                      await _updateTutorialStep(2); // step 2 → next screen

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealPlanningScreen3(
                            userId: userId, // pass UID to Screen 3
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
