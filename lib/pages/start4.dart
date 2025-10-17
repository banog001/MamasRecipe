import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// No need for FirebaseAuth here if we pass userId directly to completeTutorial
// import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // Assuming home.dart is correctly set up
import '../Dietitians/homePageDietitian.dart';


class MealPlanningScreen4 extends StatelessWidget {
  final String userId; // 👈 Accept userId

  const MealPlanningScreen4({super.key, required this.userId});

  // ✅ Mark tutorial as completed and update tutorialStep for the user
  // Now takes userId as a parameter
  Future<void> _completeTutorial(BuildContext context, String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final usersRef =
      FirebaseFirestore.instance.collection('Users').doc(currentUserId);
      final dietitianDoc = await FirebaseFirestore.instance
          .collection('dietitianApproval')
          .doc(currentUserId)
          .get();

      final isDietitian = dietitianDoc.exists;



      final userSnap = await usersRef.get();

      String role;
      if (isDietitian) {
        role = 'dietitian';
      } else if (userSnap.exists) {
        role = 'user';
      } else {
        print("⚠️ User not found in either collection.");
        return;
      }


      // ✅ Update tutorial completion in Users collection (only if user)
      if (role == 'user') {
        await usersRef.update({
          'hasCompletedTutorial': true,
          'tutorialStep': 4,
        });
        print("✅ Tutorial completed for user: $currentUserId");
      }

      // ✅ Navigate based on collection/role
      if (role == 'dietitian') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const HomePageDietitian(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const home()),
        );
      }
    } catch (e) {
      print("❌ Error completing tutorial for $currentUserId: $e");
    }
  }


  void _showConfirmationDialog(BuildContext context, String currentUserId) {
    const String primaryFontFamily = 'PlusJakartaSans';

    const TextStyle dialogTitleStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF4CAF50),
    );

    const TextStyle dialogMessageStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 14,
      color: Colors.black54,
      height: 1.4,
    );

    const TextStyle dialogButtonTextStyle = TextStyle(
      fontFamily: primaryFontFamily,
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Great Job!',
                style: dialogTitleStyle,
              ),
              const SizedBox(height: 12),
              const Text(
                'You have successfully completed the setup!',
                textAlign: TextAlign.center,
                style: dialogMessageStyle,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close dialog first
                    await _completeTutorial(context, currentUserId);
                  },

                  child: const Text(
                    'CONTINUE',
                    style: dialogButtonTextStyle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const String primaryFontFamily = 'PlusJakartaSans';

    const TextStyle headlineStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: Color(0xFF4CAF50),
    );

    const TextStyle subHeadlineStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.black54,
      height: 1.5,
    );

    const TextStyle buttonTextStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.0,
      fontSize: 16,
      color: Colors.white,
    );

    final TextStyle smallDebugTextStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.grey[500],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      const Icon(
                        Icons.celebration_outlined,
                        size: 72,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'ALL SET!',
                        textAlign: TextAlign.center,
                        style: headlineStyle,
                      ),
                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "You're ready to go! We'll take it from here — get ready for meals that feel good, taste great, and fit you perfectly.",
                          textAlign: TextAlign.center,
                          style: subHeadlineStyle,
                        ),
                      ),
                      const SizedBox(height: 60),

                      if (userId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            "User ID (for debug): $userId",
                            textAlign: TextAlign.center,
                            style: smallDebugTextStyle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, top: 15.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _showConfirmationDialog(context, userId),
                    child: const Text(
                      'FINISH SETUP',
                      style: buttonTextStyle,
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
