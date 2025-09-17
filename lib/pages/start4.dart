import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// No need for FirebaseAuth here if we pass userId directly to completeTutorial
// import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // Assuming home.dart is correctly set up

class MealPlanningScreen4 extends StatelessWidget {
  final String userId; // 👈 Accept userId

  const MealPlanningScreen4({super.key, required this.userId});

  // ✅ Mark tutorial as completed and update tutorialStep for the user
  // Now takes userId as a parameter
  Future<void> _completeTutorial(String currentUserId) async {
    if (currentUserId.isEmpty) return; // Basic check

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId) // Use the passed userId
          .update({
        'hasCompletedTutorial': true,
        'tutorialStep': 4, // Mark tutorial step completed
      });
      print("Tutorial completed for user: $currentUserId");
    } catch (e) {
      print("Error completing tutorial for user $currentUserId: $e");
      // Optionally show a SnackBar or error message to the user
    }
  }

  void _showConfirmationDialog(BuildContext context, String currentUserId) {
    // --- Define Text Styles (Assuming "Plus Jakarta Sans") ---
    const String primaryFontFamily = 'PlusJakartaSans';

    const TextStyle dialogTitleStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 22, // Adjusted for dialog
      fontWeight: FontWeight.bold,
      color: Color(0xFF4CAF50), // Theme green
    );

    const TextStyle dialogMessageStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 15,
      color: Colors.black54, // Darker grey for readability
      height: 1.4,
    );

    const TextStyle dialogButtonTextStyle = TextStyle(
      fontFamily: primaryFontFamily,
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    );
    // --- End Text Styles ---

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // Renamed context to avoid conflict
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24), // Adjusted padding
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, // Slightly smaller
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 40), // Different icon
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
              const SizedBox(height: 30),
              SizedBox( // Ensure button takes reasonable width in dialog
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent radius
                  ),
                  onPressed: () async {
                    await _completeTutorial(currentUserId); // Pass userId here

                    // ✅ Navigate to Home
                    // Ensure the dialog's context is used for Navigator.pop if needed,
                    // then the original screen's context for pushReplacement.
                    Navigator.of(dialogContext).pop(); // Close the dialog
                    Navigator.pushReplacement( // Use the screen's context
                      context,
                      MaterialPageRoute(builder: (context) => const home()),
                    );
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
    // --- Define Text Styles (Assuming "Plus Jakarta Sans") ---
    const String primaryFontFamily = 'PlusJakartaSans';

    const TextStyle headlineStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 30,
      fontWeight: FontWeight.w900,
      color: Color(0xFF4CAF50), // Theme green
    );

    const TextStyle subHeadlineStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 15, // Adjusted
      fontWeight: FontWeight.w600, // Semi-bold for better readability
      color: Colors.black54, // Darker grey
      height: 1.5, // Line height
    );

    const TextStyle buttonTextStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      fontSize: 18, // Slightly larger button text
      color: Colors.white,
    );
    final TextStyle smallDebugTextStyle = TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.grey[500],
    );
    // --- End Text Styles ---

    return Scaffold(
      backgroundColor: Colors.white, // Full white background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView( // Allows content to scroll if it overflows
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100), // Adjust top spacing as needed
                      const Icon( // Optional: Add an icon for visual appeal
                        Icons.party_mode_outlined, // Or Icons.celebration, Icons.done_all
                        size: 80,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'ALL SET!',
                        textAlign: TextAlign.center,
                        style: headlineStyle,
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "You're ready to go! We'll take it from here — get ready for meals that feel good, taste great, and fit you perfectly.",
                          textAlign: TextAlign.center,
                          style: subHeadlineStyle,
                        ),
                      ),
                      const SizedBox(height: 60), // Space before button area conceptually

                      if (userId.isNotEmpty) // Debug: Show UID
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

              // NEXT/FINISH Button - Positioned at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, top: 15.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75, // Adjust width
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Consistent radius
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _showConfirmationDialog(context, userId), // Pass userId here
                    child: const Text(
                      'FINISH SETUP', // Changed from NEXT
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

