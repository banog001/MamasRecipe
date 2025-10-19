import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mealEntry.dart';
import 'homePageDietitian.dart';


const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _accentColor = Color(0xFF66BB6A);
const Color _textColorOnPrimary = Colors.white;
const Color _neutralButtonColor = Colors.blueGrey;

TextStyle _getTextStyle(BuildContext context, {
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
  String fontFamily = _primaryFontFamily,
  double? letterSpacing,
  FontStyle? fontStyle,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor = color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}


class MealPlanPreviewPage extends StatelessWidget {
  final String planType;
  final List<MealEntry> meals;

  const MealPlanPreviewPage({
    super.key,
    required this.planType,
    required this.meals,
  });

  String _getMealString(String key) {
    try {
      final meal = meals.firstWhere((m) => m.name.toLowerCase() == key.toLowerCase());
      return meal.items.join(", ");
    } catch (_) {
      return "";
    }
  }

  Future<void> _postMealPlan(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You must be logged in to post a meal plan.",
            style: _getTextStyle(context, color: _textColorOnPrimary),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // helper to get the time string
    String _getMealTimeString(String key) {
      try {
        final meal = meals.firstWhere((m) => m.name.toLowerCase() == key.toLowerCase());
        return meal.time.format(context);
      } catch (_) {
        return "";
      }
    }

    try {
      await FirebaseFirestore.instance.collection("mealPlans").add({
        "planType": planType,
        // meal items
        "breakfast": _getMealString("Breakfast"),
        "amSnack": _getMealString("AM Snack"),
        "lunch": _getMealString("Lunch"),
        "pmSnack": _getMealString("PM Snack"),
        "dinner": _getMealString("Dinner"),
        "midnightSnack": _getMealString("Midnight Snack"),
        // meal times
        "breakfastTime": _getMealTimeString("Breakfast"),
        "amSnackTime": _getMealTimeString("AM Snack"),
        "lunchTime": _getMealTimeString("Lunch"),
        "pmSnackTime": _getMealTimeString("PM Snack"),
        "dinnerTime": _getMealTimeString("Dinner"),
        "midnightSnackTime": _getMealTimeString("Midnight Snack"),
        // meta info
        "owner": user.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Meal Plan Posted Successfully!",
            style: _getTextStyle(context, color: _textColorOnPrimary),
          ),
          backgroundColor: _primaryColor,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePageDietitian()),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error posting meal plan: $e",
            style: _getTextStyle(context, color: _textColorOnPrimary),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getScaffoldBgColor(context),
      appBar: AppBar(
        leading: BackButton(color: isDarkMode ? _textColorOnPrimary : _primaryColor),
        backgroundColor: isDarkMode ? _primaryColor.withGreen(100) : Colors.white,
        foregroundColor: isDarkMode ? _textColorOnPrimary : _primaryColor,
        title: Text(
          "$planType - Preview",
          style: _getTextStyle(context, fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? _textColorOnPrimary : _primaryColor),
        ),
        centerTitle: true,
        elevation: 1.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  final formattedTime = meal.time.format(context);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: _getCardBgColor(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            meal.name.toLowerCase().contains("snack") ? Icons.fastfood_outlined : Icons.restaurant_menu_outlined,
                            color: _primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name,
                                  style: _getTextStyle(context, fontSize: 17, fontWeight: FontWeight.bold, color: _getTextColorPrimary(context)),
                                ),
                                const SizedBox(height: 6),
                                if (meal.items.isEmpty)
                                  Text(
                                    "No items entered for this meal.",
                                    style: _getTextStyle(context, fontSize: 14, color: _getTextColorSecondary(context), fontStyle: FontStyle.italic),
                                  )
                                else
                                  ...meal.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3.0),
                                    child: Text(
                                      "• $item",
                                      style: _getTextStyle(context, fontSize: 14, color: _getTextColorPrimary(context)),
                                    ),
                                  )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formattedTime,
                              style: _getTextStyle(context, fontSize: 13, fontWeight: FontWeight.w500, color: _primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _neutralButtonColor,
                        foregroundColor: _textColorOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _textColorOnPrimary),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      label: const Text("Edit"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _postMealPlan(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _textColorOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _textColorOnPrimary),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: const Text("Post Plan"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getScaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100;

Color _getCardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white;

Color _getTextColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;

Color _getTextColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54;
