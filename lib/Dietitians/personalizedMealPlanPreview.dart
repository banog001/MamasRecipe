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
      FontStyle? fontStyle,
      required double height,
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

Color _getScaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100;

Color _getCardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white;

Color _getTextColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;

Color _getTextColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54;

// --- End Style Definitions ---

class PersonalizedMealPlanPreview extends StatelessWidget {
  final String planType;
  final List<MealEntry> meals;
  final String description;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> requestData;

  const PersonalizedMealPlanPreview({
    super.key,
    required this.planType,
    required this.meals,
    required this.description,
    required this.userData,
    required this.requestData,
  });

  String _getMealString(String key) {
    try {
      final meal = meals.firstWhere((m) => m.name.toLowerCase() == key.toLowerCase());
      return meal.items.join(", ");
    } catch (_) {
      return "";
    }
  }

  String _getMealTimeString(BuildContext context, String key) {
    try {
      final meal = meals.firstWhere((m) => m.name.toLowerCase() == key.toLowerCase());
      return meal.time.format(context);
    } catch (_) {
      return "";
    }
  }

  Future<void> _postPersonalizedMealPlan(BuildContext context) async {
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

    final clientId = requestData['clientId'];
    // ✅ Get requestId from requestData (it's the document ID)
    final requestId = requestData['requestId'] ?? requestData['requestDocId'];

    if (clientId == null || clientId.isEmpty) {
      if (!context.mounted) return;
      CustomSnackBar.show(
        context,
        'Invalid client ID.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }

    if (requestId == null || requestId.isEmpty) {
      if (!context.mounted) return;
      CustomSnackBar.show(
        context,
        'Invalid request ID. Cannot update status.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }

    try {
      // Get dietitian's name
      final dietitianDoc = await FirebaseFirestore.instance.collection("Users").doc(user.uid).get();
      final dietitianName =
      '${dietitianDoc.data()?['firstName'] ?? ''} ${dietitianDoc.data()?['lastName'] ?? ''}'.trim().isEmpty
          ? 'Your Dietitian'
          : '${dietitianDoc.data()?['firstName']} ${dietitianDoc.data()?['lastName']}';

      final clientName =
      '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim().isEmpty
          ? 'Client'
          : '${userData['firstName']} ${userData['lastName']}';

      // --- Add personalized meal plan to client's subcollection ---
      await FirebaseFirestore.instance.collection("Users").doc(clientId).collection("personalizedMealPlans").add({
        "planType": planType,
        "description": description,
        "breakfast": _getMealString("Breakfast"),
        "amSnack": _getMealString("AM Snack"),
        "lunch": _getMealString("Lunch"),
        "pmSnack": _getMealString("PM Snack"),
        "dinner": _getMealString("Dinner"),
        "midnightSnack": _getMealString("Midnight Snack"),
        "breakfastTime": _getMealTimeString(context, "Breakfast"),
        "amSnackTime": _getMealTimeString(context, "AM Snack"),
        "lunchTime": _getMealTimeString(context, "Lunch"),
        "pmSnackTime": _getMealTimeString(context, "PM Snack"),
        "dinnerTime": _getMealTimeString(context, "Dinner"),
        "midnightSnackTime": _getMealTimeString(context, "Midnight Snack"),
        "dietitianId": user.uid,
        "dietitianName": dietitianName,
        "clientId": clientId,
        "clientName": clientName,
        "requestId": requestId,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // --- ✅ Update mealPlanRequest status to 'done' ---
      await FirebaseFirestore.instance
          .collection("mealPlanRequests")
          .doc(requestId)
          .update({
        "status": "done",
        "completedAt": FieldValue.serverTimestamp(),
      });

      // --- Send notification to the client ---
      await _sendNotificationToClient(
        clientId: clientId,
        clientName: clientName,
        receiverProfile: userData['profile'] ?? '',
      );

      if (!context.mounted) return;

      CustomSnackBar.show(
        context,
        'Personalized Meal Plan Created Successfully!',
        backgroundColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePageDietitian()),
            (route) => false,
      );
    } catch (e) {
      print("Error posting personalized meal plan: $e");
      if (!context.mounted) return;
      CustomSnackBar.show(
        context,
        'Error creating meal plan: $e',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _sendNotificationToClient({
    required String clientId,
    required String clientName,
    required String receiverProfile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get dietitian's information
      final dietitianDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .get();

      if (!dietitianDoc.exists) return;

      final dietitianData = dietitianDoc.data()!;
      final dietitianName = '${dietitianData['firstName'] ?? ''} ${dietitianData['lastName'] ?? ''}'.trim();
      final dietitianProfile = dietitianData['profile'] ?? '';

      await FirebaseFirestore.instance
          .collection("Users")
          .doc(clientId)
          .collection("notifications")
          .add({
        "isRead": false,
        "title": "New Personalized Meal Plan",
        "message": "$dietitianName has created your personalized $planType meal plan!",
        "receiverId": clientId,
        "receiverName": clientName,
        "receiverProfile": receiverProfile,
        "senderId": user.uid, // ✅ Dietitian's ID
        "senderName": dietitianName.isEmpty ? "Your Dietitian" : dietitianName, // ✅ Dietitian's name
        "timestamp": FieldValue.serverTimestamp(),
        "type": "meal_plan_created",
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientName = '${userData['firstName']} ${userData['lastName']}';

    return Scaffold(
      backgroundColor: _getScaffoldBgColor(context),
      appBar: AppBar(
        leading: BackButton(color: _getTextColorPrimary(context)),
        backgroundColor: _getCardBgColor(context),
        foregroundColor: _getTextColorPrimary(context),
        title: Text(
          "Preview Meal Plan",
          style: _getTextStyle(context, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
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
                  // Client Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withOpacity(0.2), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(userData['profile'] ?? ''),
                          backgroundColor: Colors.grey[300],
                          child: userData['profile'] == null || userData['profile'].toString().isEmpty
                              ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Meal Plan for:",
                                style: _getTextStyle(context, fontSize: 12, color: _getTextColorSecondary(context), height: 1.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                clientName,
                                style: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Plan Type Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined, color: _primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Plan Type",
                                style: _getTextStyle(context, fontSize: 12, color: _getTextColorSecondary(context), height: 1.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                planType,
                                style: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Description
                  if (description.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outlined, color: _primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "About This Plan",
                                style: _getTextStyle(context, fontSize: 14, fontWeight: FontWeight.bold, color: _primaryColor, height: 1.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            style: _getTextStyle(context, fontSize: 13, color: _getTextColorPrimary(context), height: 1.5),
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
                      if (meal.items.isEmpty) return const SizedBox.shrink();

                      final formattedTime = meal.time.format(context);

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: _getCardBgColor(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_getIconForMeal(meal.name), color: _primaryColor, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meal.name,
                                        style: _getTextStyle(context, fontSize: 17, fontWeight: FontWeight.bold, height: 1.5)),
                                    const SizedBox(height: 8),
                                    Text(
                                      "• ${meal.items.join("\n• ")}",
                                      style: _getTextStyle(context, fontSize: 14, color: _getTextColorSecondary(context), height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: _primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  formattedTime,
                                  style: _getTextStyle(context, fontSize: 13, fontWeight: FontWeight.bold, color: _primaryColor, height: 1.5),
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
                        textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _textColorOnPrimary, height: 1.5),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      label: const Text("Edit"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _postPersonalizedMealPlan(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _textColorOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _textColorOnPrimary, height: 1.5),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: const Text("Create Plan"),
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
