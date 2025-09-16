import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mealEntry.dart';
import 'homePageDietitian.dart'; // Make sure this path is correct

class MealPlanPreviewPage extends StatelessWidget {
  final String planType;
  final List<MealEntry> meals;

  const MealPlanPreviewPage({
    super.key,
    required this.planType,
    required this.meals,
  });

  // ✅ Helper to safely get items as a single string
  String _getMealString(String key) {
    try {
      final meal = meals.firstWhere((m) => m.name == key);
      return meal.items.join(", ");
    } catch (_) {
      return "";
    }
  }

  Future<void> _postMealPlan(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to post a meal plan.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("mealPlans").add({
        "planType": planType, // ✅ Added meal plan type
        "breakfast": _getMealString("Breakfast"),
        "amSnack": _getMealString("AM Snack"),
        "lunch": _getMealString("Lunch"),
        "pmSnack": _getMealString("PM Snack"),
        "dinner": _getMealString("Dinner"),
        "midnightSnack": _getMealString("Midnight Snack"),
        "owner": user.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // ✅ Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meal Plan Posted Successfully!")),
      );

      // ✅ Navigate to HomePageDietitian and remove previous pages
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePageDietitian()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error posting meal plan: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text(planType, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  final formattedTime = meal.time.format(context);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.restaurant_menu,
                            color: Colors.green, size: 30),
                        const SizedBox(width: 10),

                        // ✅ Meal name + items
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meal.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              if (meal.items.isEmpty)
                                const Text("No items entered")
                              else
                                ...meal.items.map((item) => Text(item)),
                            ],
                          ),
                        ),

                        // ✅ Time display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(formattedTime),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ✅ Cancel & Post
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _postMealPlan(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Post",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
