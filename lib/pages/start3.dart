import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start4.dart';

class MealPlanningScreen3 extends StatefulWidget {
  final String userId; // 👈 Receive UID

  const MealPlanningScreen3({super.key, required this.userId});

  @override
  State<MealPlanningScreen3> createState() => _MealPlanningScreen3State();
}

class _MealPlanningScreen3State extends State<MealPlanningScreen3> {
  int? selectedIndex;
  final TextEditingController _ageController = TextEditingController();

  final List<Map<String, dynamic>> healthGoals = [
    {"icon": Icons.person, "text": "Weight Loss"},
    {"icon": Icons.accessibility_new, "text": "Weight Gain"},
    {"icon": Icons.verified, "text": "Health Recovery"},
    {"icon": Icons.favorite, "text": "Maintain Weight"},
    {"icon": Icons.fitness_center, "text": "Workout"},
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// ✅ Function to save age, goal, and tutorial step to Firestore
  Future<void> _saveUserData() async {
    if (_ageController.text.isEmpty || selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter age and select a goal")),
      );
      return;
    }

    final String age = _ageController.text.trim();
    final String goal = healthGoals[selectedIndex!]["text"];

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userId)
          .update({
        "age": int.parse(age),
        "goals": goal,
        "tutorialStep": 3, // ✅ Save current step
      });

      // Navigate to next screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MealPlanningScreen4(), // 👈 pass UID
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          width: 1000,
          height: 1000,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'SET UP ACCOUNT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 35,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),

                /// Age Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Age',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                /// Age TextField
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Enter your age',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      letterSpacing: 0.5,
                      fontFamily: 'Inter',
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(130),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(130),
                      borderSide: const BorderSide(
                        color: Color(0xFF4CAF50),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Health Goals Title
                const Text(
                  'Health Goals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 20),

                /// Scrollable list inside a fixed-height box
                SizedBox(
                  height: 345,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(10),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: healthGoals.length,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, index) {
                        final goal = healthGoals[index];
                        final isSelected = selectedIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green[600]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.green[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    goal["icon"],
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  goal["text"],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// NEXT Button with Firestore save
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
                    onPressed: _saveUserData,
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

                const SizedBox(height: 20),

                // Debug: Show UID
                Text(
                  "User ID: ${widget.userId}",
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
