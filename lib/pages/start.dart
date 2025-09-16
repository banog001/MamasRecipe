import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'start2.dart';

class MealPlanningScreen extends StatelessWidget {
  final String userId; // 👈 Receive UID

  const MealPlanningScreen({super.key, required this.userId});

  // Save the tutorial step to Firestore
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
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                SizedBox(
                  height: 200,
                  width: 200,
                  child: ClipOval(
                    child: Image.asset(
                      'lib/assets/image/plate.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Smart meal planning\nat your fingertips',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No more guessing what to eat. Get personalized meal suggestions tailored to your goals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Show UID just for testing
                Text(
                  "Your User ID: $userId",
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: SizedBox(
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
                        // Update tutorial step before navigating
                        await _updateTutorialStep(1); // step 1 → next screen

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MealPlanningScreen2(userId: userId),
                          ),
                        );
                      },
                      child: const Text(
                        'START',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 20,
                          color: Colors.white,
                        ),
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
}
