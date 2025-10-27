import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mealEntry.dart';
import 'homePageDietitian.dart';

import 'package:mamas_recipe/widget/custom_snackbar.dart';

// --- Theme & Style Definitions ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _accentColor = Color(0xFF66BB6A);
const Color _textColorOnPrimary = Colors.white;
const Color _neutralButtonColor = Colors.blueGrey;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle, required double height,
    }) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor =
      color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}

Color _getScaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade100;

Color _getCardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;

Color _getTextColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

Color _getTextColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;
// --- End Style Definitions ---

// ============================================
// STEP 2: Update mealPlanPreview.dart
// ============================================

class MealPlanPreviewPage extends StatelessWidget {
  final String planType;
  final List<MealEntry> meals;
  final String description; // NEW: Add description parameter

  const MealPlanPreviewPage({
    super.key,
    required this.planType,
    required this.meals,
    required this.description, // NEW: Add to constructor
  });

  String _getMealString(String key) {
    try {
      final meal =
      meals.firstWhere((m) => m.name.toLowerCase() == key.toLowerCase());
      return meal.items.join(", ");
    } catch (_) {
      return "";
    }
  }

  Future<void> _postMealPlan(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      CustomSnackBar.show(
        context,
        'You must be logged in to post a meal plan.',
        backgroundColor: Colors.redAccent,
        icon: Icons.lock_outline,
      );
      return;
    }

    String _getMealTimeString(String key) {
      try {
        final meal =
        meals.firstWhere((m) => m.name.toLowerCase() == key.toLowerCase());
        return meal.time.format(context);
      } catch (_) {
        return "";
      }
    }

    try {
      // Get dietitian's name
      final dietitianDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .get();
      final dietitianName = '${dietitianDoc.data()?['firstName'] ?? ''} ${dietitianDoc.data()?['lastName'] ?? ''}'.trim().isEmpty ? 'A Dietitian' : '${dietitianDoc.data()?['firstName']} ${dietitianDoc.data()?['lastName']}';

      // Post the meal plan
      await FirebaseFirestore.instance.collection("mealPlans").add({
        "planType": planType,
        "description": description,
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
        "likeCounts": 0,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Send notifications to followers and subscribers
      await _sendNotificationsToFollowersAndSubscribers(
        dietitianId: user.uid,
        dietitianName: dietitianName,
        planType: planType,
      );

      if (!context.mounted) return;

      CustomSnackBar.show(
        context,
        'Meal Plan Posted Successfully!',
        backgroundColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePageDietitian()),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      CustomSnackBar.show(
        context,
        'Error posting meal plan: $e',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _sendNotificationsToFollowersAndSubscribers({
    required String dietitianId,
    required String dietitianName,
    required String planType,
  }) async {
    try {
      final Set<String> notifiedUserIds = {};

      // Get followers
      final followersSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(dietitianId)
          .collection("followers")
          .get();

      for (var followerDoc in followersSnapshot.docs) {
        final userId = followerDoc.data()['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          notifiedUserIds.add(userId);
        }
      }

      // Get subscribers (only active ones)
      final subscribersSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(dietitianId)
          .collection("subscriber")
          .where("status", isEqualTo: "approved")
          .get();

      for (var subscriberDoc in subscribersSnapshot.docs) {
        final userId = subscriberDoc.data()['userId'] as String?;
        final expirationDate = subscriberDoc.data()['expirationDate'] as Timestamp?;

        // Check if subscription is still valid
        if (userId != null &&
            userId.isNotEmpty &&
            expirationDate != null &&
            expirationDate.toDate().isAfter(DateTime.now())) {
          notifiedUserIds.add(userId);
        }
      }

      // Send notifications using batch writes for better performance
      final batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;

      for (var userId in notifiedUserIds) {
        try {
          // Get receiver's name
          final userDoc = await FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .get();

          final receiverName = '${userDoc.data()?['firstName'] ?? ''} ${userDoc.data()?['lastName'] ?? ''}'.trim().isEmpty ? 'User' : '${userDoc.data()?['firstName']} ${userDoc.data()?['lastName']}';


          // Create notification reference
          final notificationRef = FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .collection("notifications")
              .doc();

          batch.set(notificationRef, {
            "title": "New Meal Plan Posted",
            "message": "$dietitianName has posted a new $planType meal plan. Check it out!",
            "senderId": dietitianId,
            "senderName": dietitianName,
            "receiverId": userId,
            "receiverName": receiverName,
            "type": "meal_plan",
            "isRead": false,
            "timestamp": FieldValue.serverTimestamp(),
          });

          batchCount++;

          // Firestore batch limit is 500 operations, commit when approaching limit
          if (batchCount >= 450) {
            await batch.commit();
            batchCount = 0;
          }
        } catch (e) {
          // Skip this user if there's an error getting their data
          print("Error getting user data for $userId: $e");
          continue;
        }
      }

      // Commit remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // Log error but don't block the meal plan posting
      print("Error sending notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getScaffoldBgColor(context),
      appBar: AppBar(
        leading: BackButton(color: _getTextColorPrimary(context)),
        backgroundColor: _getCardBgColor(context),
        foregroundColor: _getTextColorPrimary(context),
        title: Text(
          "$planType - Preview",
          style: _getTextStyle(context,
              fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
        ),
        centerTitle: true,
        elevation: 1.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // NEW: Display description
                  if (description.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outlined,
                                color: _primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "About This Plan",
                                style: _getTextStyle(
                                  context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor, height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            style: _getTextStyle(
                              context,
                              fontSize: 13,
                              color: _getTextColorPrimary(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Meals list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      if (meal.items.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final formattedTime = meal.time.format(context);

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: _getCardBgColor(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _getIconForMeal(meal.name),
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
                                      style: _getTextStyle(context,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold, height: 1.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      meal.items.join("\n• "),
                                      style: _getTextStyle(context,
                                          fontSize: 14,
                                          color: _getTextColorSecondary(context), height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  formattedTime,
                                  style: _getTextStyle(context,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 20.0, horizontal: 0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _neutralButtonColor,
                        foregroundColor: _textColorOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: _getTextStyle(context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColorOnPrimary, height: 1.5),
                      ),
                      icon:
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: _getTextStyle(context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColorOnPrimary, height: 1.5),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 20),
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

  IconData _getIconForMeal(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('breakfast')) return Icons.wb_sunny_outlined;
    if (name.contains('lunch')) return Icons.restaurant_menu_outlined;
    if (name.contains('dinner')) return Icons.nightlight_outlined;
    if (name.contains('am snack')) return Icons.coffee_outlined;
    if (name.contains('pm snack')) return Icons.local_cafe_outlined;
    if (name.contains('midnight snack')) return Icons.bedtime_outlined;
    return Icons.fastfood_outlined;
  }
}