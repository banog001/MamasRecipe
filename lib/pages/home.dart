import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'messages.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'UserProfile.dart';
import 'package:shimmer/shimmer.dart';
import 'subscription_model.dart';
import 'subscription_service.dart';
import 'subscription_widget.dart';
import '../Dietitians/dietitianPublicProfile.dart';

import 'package:mamas_recipe/about/about_page.dart';

import 'package:mamas_recipe/widget/custom_snackbar.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

// Add aliases to fix naming conflicts
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:timezone/timezone.dart' as tz;

import 'termsAndConditions.dart';
import 'package:flutter/material.dart';

// Add this class after all your imports and before the home class
class MealPlanNotificationService {
  static final fln.FlutterLocalNotificationsPlugin _notifications =
  fln.FlutterLocalNotificationsPlugin();

  // Schedule notification for 1 day before at 8:00 AM
  static Future<void> scheduleReminderNotification({
    required int notificationId,
    required DateTime mealPlanDate,
    required String planType,
    required String dayName,
  }) async {
    final reminderDate = DateTime(
      mealPlanDate.year,
      mealPlanDate.month,
      mealPlanDate.day - 1,
      8, // 8:00 AM
      0,
    );

    if (reminderDate.isAfter(DateTime.now())) {
      final scheduledTZ = tz.TZDateTime.from(reminderDate, tz.local);

      const androidDetails = fln.AndroidNotificationDetails(
        'meal_plan_reminders',
        'Meal Plan Reminders',
        channelDescription: 'Reminders for scheduled meal plans',
        importance: fln.Importance.high,
        priority: fln.Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = fln.DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = fln.NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        '🍽️ Meal Plan Reminder',
        'Don\'t forget! Your "$planType" meal plan is scheduled for tomorrow ($dayName)',
        scheduledTZ,
        details,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('✅ Notification scheduled for: $reminderDate');
    } else {
      print('⚠️ Reminder date is in the past, skipping notification');
    }
  }

  // Send email reminder
  static Future<void> sendEmailReminder({
    required String userEmail,
    required String userName,
    required DateTime mealPlanDate,
    required String dayName,
    required String planType,
    required Map<String, dynamic> mealDetails,
    required String userId,
    required String ownerId,
  }) async {
    try {
      // Check subscription status
      final isSubscribed = await _checkSubscriptionStatus(userId, ownerId);

      // Configure SMTP
      final smtpServer = gmail('mamas.recipe0@gmail.com', 'gbsk ioml dham zgme');

      final message = Message()
        ..from = Address('mamas.recipe0@gmail.com', "Mama's Recipe")
        ..recipients.add(userEmail)
        ..subject = '🍽️ Reminder: Your Meal Plan for Tomorrow ($dayName)'
        ..html = _buildEmailTemplate(
          userName: userName,
          mealPlanDate: mealPlanDate,
          dayName: dayName,
          planType: planType,
          mealDetails: mealDetails,
          isSubscribed: isSubscribed,
        );

      await send(message, smtpServer);
      print('📧 Email reminder sent successfully to $userEmail');
    } catch (e) {
      print('❌ Error sending email: $e');
    }
  }

  // Send push notification to Firestore
  static Future<void> sendPushNotification({
    required String userId,
    required String userName,
    required String ownerId,
    required String ownerName,
    required DateTime mealPlanDate,
    required String dayName,
    required String planType,
  }) async {
    try {
      final formattedDate = _formatDate(mealPlanDate);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('notifications')
          .add({
        'isRead': false,
        'message': 'You scheduled a "$planType" meal plan for $dayName ($formattedDate). Reminder will be sent 1 day before at 8:00 AM.',
        'receiverId': userId,
        'receiverName': userName,
        'senderId': ownerId,
        'senderName': ownerName,
        'timestamp': FieldValue.serverTimestamp(),
        'title': 'Meal Plan Scheduled',
        'type': 'meal_plan_scheduled',
        'mealPlanDate': mealPlanDate.toIso8601String(),
        'dayName': dayName,
        'planType': planType,
      });

      print('📲 Push notification sent to user $userId');
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }

  // Check if user is subscribed to the meal plan owner
  static Future<bool> _checkSubscriptionStatus(String userId, String ownerId) async {
    try {
      if (userId == ownerId) return true;

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('subscribeTo')
          .doc(ownerId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['status'] == 'approved';
      }
      return false;
    } catch (e) {
      print('❌ Error checking subscription: $e');
      return false;
    }
  }

  static String _buildEmailTemplate({
    required String userName,
    required DateTime mealPlanDate,
    required String dayName,
    required String planType,
    required Map<String, dynamic> mealDetails,
    required bool isSubscribed,
  }) {
    final breakfast = mealDetails['breakfast'] ?? 'N/A';
    final breakfastTime = mealDetails['breakfastTime'] ?? '';
    final amSnack = mealDetails['amSnack'] ?? 'N/A';
    final amSnackTime = mealDetails['amSnackTime'] ?? '';
    final lunch = mealDetails['lunch'] ?? 'N/A';
    final lunchTime = mealDetails['lunchTime'] ?? '';
    final pmSnack = mealDetails['pmSnack'] ?? 'N/A';
    final pmSnackTime = mealDetails['pmSnackTime'] ?? '';
    final dinner = mealDetails['dinner'] ?? 'N/A';
    final dinnerTime = mealDetails['dinnerTime'] ?? '';
    final midnightSnack = mealDetails['midnightSnack'] ?? 'N/A';
    final midnightSnackTime = mealDetails['midnightSnackTime'] ?? '';
    final description = mealDetails['description'] ?? '';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 30px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
            .header { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 40px 30px; text-align: center; }
            .header h1 { margin: 0; font-size: 32px; font-weight: bold; }
            .content { padding: 40px 30px; }
            .greeting { font-size: 18px; color: #333; margin-bottom: 20px; }
            .date-card { background: linear-gradient(135deg, #E8F5E9 0%, #C8E6C9 100%); border-left: 5px solid #4CAF50; padding: 20px; margin: 25px 0; border-radius: 10px; }
            .date-card h2 { margin: 0 0 10px 0; color: #4CAF50; font-size: 24px; }
            .description-box { background-color: #f0f7ff; border-left: 4px solid #2196F3; padding: 15px; margin: 20px 0; border-radius: 8px; }
            .description-box p { margin: 0; color: #555; font-size: 14px; line-height: 1.6; }
            .meal-item { background-color: #f9f9f9; padding: 15px; margin: 12px 0; border-radius: 10px; border-left: 4px solid #4CAF50; }
            .meal-label { font-weight: bold; color: #4CAF50; font-size: 14px; text-transform: uppercase; margin-bottom: 5px; }
            .meal-time { color: #888; font-size: 13px; margin-bottom: 8px; }
            .meal-description { color: #333; font-size: 15px; line-height: 1.5; }
            .footer { background-color: #f8f8f8; padding: 25px; text-align: center; color: #888; font-size: 13px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🍽️ Meal Plan Reminder</h1>
            </div>
            <div class="content">
                <p class="greeting">Hi <strong>$userName</strong>,</p>
                <p>Your meal plan is ready for tomorrow! Stay on track with your nutrition goals. 💪</p>
                
                <div class="date-card">
                    <h2>📅 $dayName</h2>
                    <p><strong>Plan Type:</strong> $planType</p>
                    <p><strong>Date:</strong> ${_formatDate(mealPlanDate)}</p>
                </div>
                
                ${description.isNotEmpty ? '''
                <div class="description-box">
                    <p><strong>📝 Plan Description:</strong></p>
                    <p style="margin-top: 8px;">$description</p>
                </div>
                ''' : ''}
                
                <div class="meal-section">
                    <h3 style="color: #333; margin-bottom: 15px;">🍴 Your Meals for Tomorrow</h3>
                    
                    ${_buildMealItem('Breakfast', breakfast, breakfastTime, false)}
                    ${_buildMealItem('AM Snack', amSnack, amSnackTime, !isSubscribed)}
                    ${_buildMealItem('Lunch', lunch, lunchTime, !isSubscribed)}
                    ${_buildMealItem('PM Snack', pmSnack, pmSnackTime, !isSubscribed)}
                    ${_buildMealItem('Dinner', dinner, dinnerTime, !isSubscribed)}
                    ${_buildMealItem('Midnight Snack', midnightSnack, midnightSnackTime, !isSubscribed)}
                    
                    ${!isSubscribed ? '''
                    <div style="margin-top: 25px; padding: 20px; background: linear-gradient(135deg, #FFF3E0 0%, #FFE0B2 100%); border-radius: 12px; border-left: 4px solid #FF9800;">
                        <div style="display: flex; align-items: center; margin-bottom: 12px;">
                            <span style="font-size: 24px; margin-right: 10px;">🔒</span>
                            <h3 style="margin: 0; color: #F57C00; font-size: 18px;">Premium Content Locked</h3>
                        </div>
                        <p style="color: #666; font-size: 14px; margin: 8px 0;">Subscribe to unlock all meal details, times, and personalized nutrition guidance.</p>
                    </div>
                    ''' : ''}
                </div>
            </div>
            <div class="footer">
                <p>You're receiving this email because you scheduled a meal plan in Mama's Recipe.</p>
                <p>© 2025 Mama's Recipe. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  static String _buildMealItem(String label, String description, String time, bool isLocked) {
    if (description == 'N/A' || description.isEmpty) return '';

    return '''
    <div class="meal-item" style="${isLocked ? 'opacity: 0.6; background-color: #f5f5f5;' : ''}">
        <div class="meal-label" style="display: flex; align-items: center; gap: 8px;">
            ${isLocked ? '<span style="font-size: 16px;">🔒</span>' : ''}
            <span>$label</span>
        </div>
        ${time.isNotEmpty && !isLocked ? '<div class="meal-time">⏰ $time</div>' : ''}
        <div class="meal-description">${isLocked ? '•••••••••' : description}</div>
    </div>
    ''';
  }

  static String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
    print('🔕 Notification cancelled: $notificationId');
  }
}

const String _primaryFontFamily = 'PlusJakartaSans';

const Color _primaryColor = Color(0xFF4CAF50);
Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade100;
Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;
Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;
Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;
const Color _textColorOnPrimary = Colors.white;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle, required double height,
    }) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}

TextStyle _sectionTitleStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: _textColorPrimary(context),
);

TextStyle _cardTitleStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: _primaryColor,
);

TextStyle _cardSubtitleStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 12,
  color: _textColorSecondary(context),
);

TextStyle _cardBodyTextStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 14,
  color: _textColorPrimary(context),
);

TextStyle _tableHeaderStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontWeight: FontWeight.bold,
  color: _textColorPrimary(context),
);

TextStyle _lockedTextStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  color: _textColorSecondary(context).withOpacity(0.7),
  fontStyle: FontStyle.italic,
);

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> submitRating({
    required int rating,
    required String? description,
    required String fullName,
    required String email,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('appRatings').add({
        'userId': userId,
        'rating': rating,
        'description': description ?? '',
        'fullName': fullName,
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error submitting rating: $e');
      return false;
    }
  }
}

class _RateUsDialog extends StatefulWidget {
  final String fullName;
  final String email;
  final Function onSuccess;

  const _RateUsDialog({
    Key? key,
    required this.fullName,
    required this.email,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<_RateUsDialog> {
  int _selectedRating = 0;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      CustomSnackBar.show(
        context,
        'Please select a rating',
        backgroundColor: Colors.orange,
        icon: Icons.star,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await RatingService.submitRating(
      rating: _selectedRating,
      description: _descriptionController.text.trim(),
      fullName: widget.fullName, // <-- This line is fixed
      email: widget.email,    // <-- This line is fixed
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      widget.onSuccess();

      CustomSnackBar.show(
        context,
        'Thank you for your rating! ✨',
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 2),
      );
    } else if (mounted) {
      CustomSnackBar.show(
        context,
        'Failed to submit rating. Please try again.',
        backgroundColor: Colors.red,
        icon: Icons.error,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          ),
          child: SingleChildScrollView( // <-- ADD THIS WIDGET
          child: Container( // <-- Now the Container is inside
          decoration: BoxDecoration(
            color: _cardBgColor(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor,
                      _primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Rate Our App',
                      style: _getTextStyle(
                        context,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us improve your experience',
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Star Rating
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _selectedRating == 0
                                ? 'Select a rating'
                                : 'You rated: $_selectedRating ${_selectedRating == 1 ? 'star' : 'stars'}',
                            style: _getTextStyle(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedRating == 0
                                  ? _textColorSecondary(context)
                                  : _primaryColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final rating = index + 1;
                              final isSelected = _selectedRating >= rating;

                              return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedRating = rating);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.2 : 1.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        isSelected
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: isSelected ? Colors.amber : Colors.grey.shade300,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Description TextField
                    Text(
                      'Tell us more (Optional)',
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 300,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with us...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontFamily: _primaryFontFamily,
                        ),
                        filled: true,
                        fillColor: _primaryColor.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _primaryColor.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: _getTextStyle(
                          context,
                          fontSize: 12,
                          color: _textColorSecondary(context),
                          height: 1.5,
                        ),
                      ),
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: _primaryColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: _getTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Submit Rating',
                          style: _getTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
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


class home extends StatefulWidget {
  final int initialIndex;
  const home({super.key, this.initialIndex = 0});

  @override
  State<home> createState() => _HomeState();
}


/// Show full description in a modal dialog
void _showFullDescription(BuildContext context, String description, String planType) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: _cardBgColor(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Plan Details",
                            style: _getTextStyle(
                              context,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            planType,
                            style: _getTextStyle(
                              context,
                              fontSize: 12,
                              color: _primaryColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  description,
                  style: _getTextStyle(
                    context,
                    fontSize: 14,
                    color: _textColorPrimary(context),
                    height: 1.6,
                  ),
                ),
              ),

              // Close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Got it!',
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<Map<String, dynamic>?> getCurrentUserData() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) return null;

  final userDoc = await FirebaseFirestore.instance
      .collection("Users")
      .doc(currentUser.uid)
      .get();

  if (userDoc.exists) {
    return userDoc.data();
  } else {
    return null;
  }
}

class _HomeState extends State<home> {
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  String selectedMenu = '';
  late int selectedIndex;
  String firstName = "";
  String lastName = "";
  String profileUrl = "";
  bool _isUserNameLoading = true;

  String _searchQuery = "";
  String _searchFilter = "All";
  final TextEditingController _searchController = TextEditingController();

  void _showSubscriptionDialog(String? ownerName, String? ownerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium Content',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscribe to ${ownerName ?? "this creator"} to unlock all meal details and times.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _benefitRow('Full meal plans with times'),
                    _benefitRow('Personalized nutrition guidance'),
                    _benefitRow('Exclusive recipes'),
                    _benefitRow('Direct creator support'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription page
                // You'll need to implement this navigation
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Subscribe Now'),
            ),
          ],
        );
      },
    );
  }




  // --- PASTE THIS FUNCTION INSIDE _HomeState ---
  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: _getTextStyle(context, fontSize: 13, height: 1.5), // Ensure context is available
            ),
          ),
        ],
      ),
    );
  }
// --- END OF FUNCTION ---



  // --- PASTE THIS HELPER FUNCTION INSIDE _HomeState ---
  Widget _mealRowWithTime(String label, String? value, String? time,
      {bool isLocked = false}) {
    if ((value == null || value.trim().isEmpty || value.trim() == '-') &&
        (time == null || time.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : _primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: _getTextStyle(context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? Colors.grey.shade600
                                : _primaryColor, height: 1.5),
                      ),
                    ),
                    if (time != null && time.isNotEmpty && !isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 10, color: _primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: _getTextStyle(context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (value != null && value.isNotEmpty && value != '-')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isLocked ? '•••••••••' : value,
                      style: _getTextStyle(context,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLocked
                              ? Colors.grey.shade500
                              : _getTextStyle(context, fontSize: 13, height: 1.5).color, height: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- END OF HELPER FUNCTION ---

  Map<String, dynamic>? userData;
  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _setUserStatus("online");
    _updateGooglePhotoURL();
    loadUserName();
  }

  void loadUserName() async {
    setState(() {
      _isUserNameLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (mounted) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            setState(() {
              firstName = data['firstName'] as String? ?? '';
              lastName = data['lastName'] as String? ?? '';
              profileUrl = data['profile'] as String? ?? '';
              _isUserNameLoading = false;
            });
          } else {
            setState(() {
              firstName = "";
              lastName = "";
              profileUrl = "";
              _isUserNameLoading = false;
            });
            debugPrint("User document does not exist for UID: ${user.uid}");
          }
        }
      } catch (e) {
        debugPrint("Error loading user name: $e");
        if (mounted) {
          setState(() {
            firstName = "";
            lastName = "";
            profileUrl = "";
            _isUserNameLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isUserNameLoading = false;
        });
      }
    }
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBgColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: _getTextStyle(context, fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: _getTextStyle(
                  context,
                  fontSize: 14,
                  color: _textColorSecondary(context), height: 1.5,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _primaryColor,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: _textColorSecondary(context),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        _buildFilterChips(),
      ],
    );
  }


  String _getSearchHint() {
    switch (_searchFilter) {
      case "Health Goals":
        return "Search by health goals (e.g., Weight Loss, Muscle Gain)...";
      case "Dietitians":
        return "Search dietitians by name or specialization...";
      case "Meal Plans":
        return "Search meal plans by name or type...";
      default:
        return "Search by health goals, dietitians, meal plans...";
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {"label": "All", "icon": Icons.apps},
      {"label": "Health Goals", "icon": Icons.favorite},
      {"label": "Dietitians", "icon": Icons.person},
      {"label": "Meal Plans", "icon": Icons.restaurant_menu},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _searchFilter == filter["label"];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter["icon"] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : _primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter["label"] as String,
                    style: _getTextStyle(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _primaryColor, height: 1.5,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _searchFilter = filter["label"] as String;
                });
              },
              backgroundColor: _cardBgColor(context),
              selectedColor: _primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) => Card(
        elevation: 2,
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
          highlightColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
          child: Container(
            width: 300,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget recommendationsWidget() {
    if (_searchFilter != "All" && _searchFilter != "Health Goals") {
      return const SizedBox.shrink();
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    const double w1 = 1.0;
    const double w2 = 1.5;
    const double alpha = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Trending Now ✨",
                style: _sectionTitleStyle(context).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Discover popular meal plans from the community",
                style: _getTextStyle(
                  context,
                  fontSize: 13,
                  color: _textColorSecondary(context), height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 380,
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("Users")
                .doc(currentUser.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting &&
                  !userSnapshot.hasData) {
                return _buildRecommendationsLoadingShimmer();
              }

              bool isSubscribed = false;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                isSubscribed = userData["isSubscribed"] ?? false;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("mealPlans")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildRecommendationsLoadingShimmer();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 48,
                              color: _primaryColor.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            "No trending plans yet",
                            style: _getTextStyle(context, fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>?;
                    if (data == null) return false;
                    if ((data["owner"] ?? "").toString().trim().isEmpty)
                      return false;

                    bool allMealsEmpty = [
                      data["breakfast"],
                      data["amSnack"],
                      data["lunch"],
                      data["pmSnack"],
                      data["dinner"],
                      data["midnightSnack"],
                    ].every((meal) =>
                    meal == null ||
                        meal.toString().trim().isEmpty ||
                        meal.toString().toLowerCase() == "null");

                    if (allMealsEmpty) return false;
                    return (data["planType"] ?? "").toString().trim().isNotEmpty;
                  }).toList();

                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String planName =
                      (data["planName"] ?? "").toString().toLowerCase();
                      String planType =
                      (data["planType"] ?? "").toString().toLowerCase();
                      String description =
                      (data["description"] ?? "").toString().toLowerCase();

                      if (_searchFilter == "Health Goals") {
                        return planType.contains(_searchQuery);
                      }
                      return planName.contains(_searchQuery) ||
                          planType.contains(_searchQuery) ||
                          description.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48,
                              color: _primaryColor.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            "No results found",
                            style: _getTextStyle(context, fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  }

                  List<Map<String, dynamic>> scoredPlans = docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    int likes = data["likeCounts"] ?? 0;
                    int calendarAdds = data["calendarAdds"] ?? 0;

                    DateTime publishedDate;
                    if (data["timestamp"] is Timestamp) {
                      publishedDate = (data["timestamp"] as Timestamp).toDate();
                    } else if (data["timestamp"] is String) {
                      publishedDate =
                          DateTime.tryParse(data["timestamp"]) ?? DateTime.now();
                    } else {
                      publishedDate = DateTime.now();
                    }

                    int daysSincePublished =
                        DateTime.now().difference(publishedDate).inDays;
                    if (daysSincePublished <= 0) daysSincePublished = 1;

                    double finalScore =
                        ((w1 * likes) + (w2 * calendarAdds)) /
                            (alpha * daysSincePublished);

                    return {"doc": doc, "data": data, "score": finalScore};
                  }).toList();

                  if (scoredPlans.isEmpty) {
                    return const Center(
                      child: Text("No trending plans available"),
                    );
                  }

                  scoredPlans.sort((a, b) =>
                      (b["score"] as double).compareTo(a["score"] as double));
                  if (scoredPlans.length > 5) {
                    scoredPlans = scoredPlans.sublist(0, 5);
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: scoredPlans.length,
                    itemBuilder: (context, index) {
                      final plan = scoredPlans[index];
                      var docSnap = plan["doc"] as DocumentSnapshot;
                      var data = plan["data"] as Map<String, dynamic>;
                      String ownerId = data["owner"] ?? "";

                      return _buildRecommendationCard(
                        context,
                        docSnap,
                        data,
                        ownerId,
                        currentUser.uid,
                        isSubscribed,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


// REPLACE _buildMealPlanListItem with this improved version
// This transforms your existing design to Option 5+4 hybrid with expandable functionality

  Widget _buildMealPlanListItem(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      ) {
    // Check subscription status dynamically
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('subscribeTo')
          .doc(ownerId)
          .snapshots(),
      builder: (context, subscribeSnapshot) {
        bool isSubscribed = false;
        if (subscribeSnapshot.hasData &&
            subscribeSnapshot.data != null &&
            subscribeSnapshot.data!.exists) {
          final subData =
          subscribeSnapshot.data!.data() as Map<String, dynamic>;
          if (subData['status'] == 'approved') {
            isSubscribed = true;
          }
        }

        return _buildExpandableMealPlanCard(
          context,
          doc,
          data,
          ownerId,
          currentUserId,
          isSubscribed,
        );
      },
    );
  }

// REPLACE the _buildExpandableMealPlanCard method in your home.dart with this updated version


  Widget _buildExpandableMealPlanCard(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isSubscribed) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isExpanded = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: _cardBgColor(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER SECTION - Always visible, clickable to expand
                  InkWell(
                    onTap: () {
                      setLocalState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Owner Info Row
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection("Users")
                                .doc(ownerId)
                                .get(),
                            builder: (context, ownerSnapshot) {
                              String ownerName = "Unknown Chef";
                              String ownerProfileUrl = "";

                              if (ownerSnapshot.hasData &&
                                  ownerSnapshot.data != null &&
                                  ownerSnapshot.data!.exists) {
                                var ownerData =
                                ownerSnapshot.data!.data() as Map<String, dynamic>;
                                ownerName =
                                    "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                                        .trim();
                                if (ownerName.isEmpty) ownerName = "Unknown Chef";
                                ownerProfileUrl = ownerData["profile"] ?? "";
                              }
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _primaryColor.withOpacity(0.2),
                                    backgroundImage: (ownerProfileUrl.isNotEmpty)
                                        ? NetworkImage(ownerProfileUrl)
                                        : null,
                                    child: (ownerProfileUrl.isEmpty)
                                        ? const Icon(Icons.person,
                                        size: 24, color: _primaryColor)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ownerName,
                                          style: _cardTitleStyle(context).copyWith(
                                            color: _primaryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (data["timestamp"] != null &&
                                            data["timestamp"] is Timestamp)
                                          Text(
                                            DateFormat('MMM dd, yyyy').format(
                                              (data["timestamp"] as Timestamp).toDate(),
                                            ),
                                            style: _cardSubtitleStyle(context)
                                                .copyWith(fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Animated expand/collapse indicator
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.expand_more,
                                      color: _primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Plan Type
                          Text(
                            data["planType"] ?? "Meal Plan",
                            style: _cardBodyTextStyle(context).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // --- DUPLICATE DESCRIPTION BLOCK REMOVED ---
                          // The first description block that was here is now gone.

                          // This is the description block you wanted to keep
                          if (data["description"] != null &&
                              data["description"].toString().trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _primaryColor.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                    color: _primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data["description"] as String,
                                          style: _getTextStyle(
                                            context,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _textColorPrimary(context),
                                            height: 1.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () => _showFullDescription(
                                            context,
                                            data["description"] as String,
                                            data["planType"] ?? "Meal Plan",
                                          ),
                                          child: Text(
                                            "View full description",
                                            style: _getTextStyle(
                                              context,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _primaryColor,
                                              fontStyle: FontStyle.italic,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          if (!isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Tap to view full meal plan",
                                style: _getTextStyle(
                                  context,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _primaryColor,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // EXPANDED CONTENT - Shows all meals and actions
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 20, thickness: 0.5),
                          if (data["description"] != null &&
                              data["description"].toString().trim().isNotEmpty)
                            _buildMealItemExpanded(
                              context,
                              "Breakfast",
                              data["breakfast"],
                              data["breakfastTime"],
                              Icons.wb_sunny_outlined,
                              Colors.orange,
                              isLocked: false,
                            ),
                          _buildMealItemExpanded(
                            context,
                            "AM Snack",
                            data["amSnack"],
                            data["amSnackTime"],
                            Icons.coffee_outlined,
                            Colors.brown,
                            isLocked: !isSubscribed,
                          ),
                          _buildMealItemExpanded(
                            context,
                            "Lunch",
                            data["lunch"],
                            data["lunchTime"],
                            Icons.restaurant_outlined,
                            Colors.green,
                            isLocked: !isSubscribed,
                          ),
                          _buildMealItemExpanded(
                            context,
                            "PM Snack",
                            data["pmSnack"],
                            data["pmSnackTime"],
                            Icons.local_cafe_outlined,
                            Colors.purple,
                            isLocked: !isSubscribed,
                          ),
                          _buildMealItemExpanded(
                            context,
                            "Dinner",
                            data["dinner"],
                            data["dinnerTime"],
                            Icons.nightlight_outlined,
                            Colors.indigo,
                            isLocked: !isSubscribed,
                          ),
                          _buildMealItemExpanded(
                            context,
                            "Midnight Snack",
                            data["midnightSnack"],
                            data["midnightSnackTime"],
                            Icons.bedtime_outlined,
                            Colors.blueGrey,
                            isLocked: !isSubscribed,
                          ),

                          // Subscription Unlock Prompt (If needed)
                          if (!isSubscribed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: InkWell(
                                onTap: () {
                                  _showSubscriptionDialog(
                                      data['ownerName'], ownerId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock_open,
                                          size: 14, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Subscribe to unlock',
                                        style: _getTextStyle(context,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                            height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // FIXED: Action buttons WITHOUT StreamBuilder wrapping
                          // This prevents the whole card from rebuilding when likes change
                          _buildActionButtonsFixed(
                            context,
                            doc,
                            data,
                            ownerId,
                            currentUserId,
                            isSubscribed,
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtonsFixed(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isSubscribed,
      ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LIKE BUTTON - Only THIS part uses StreamBuilder
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("likes")
                .doc("${currentUserId}_${doc.id}")
                .snapshots(),
            builder: (context, likeSnapshot) {
              bool isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("mealPlans")
                    .doc(doc.id)
                    .snapshots(),
                builder: (context, mealSnapshot) {
                  if (!mealSnapshot.hasData) return const SizedBox();
                  final mealData = mealSnapshot.data!.data() as Map<String, dynamic>;
                  int likeCount = mealData["likeCounts"] ?? 0;
                  return TextButton.icon(
                    onPressed: () async {
                      final likeDocRef = FirebaseFirestore.instance
                          .collection("likes")
                          .doc("${currentUserId}_${doc.id}");
                      final mealPlanDocRef = FirebaseFirestore.instance
                          .collection("mealPlans")
                          .doc(doc.id);

                      if (isLiked) {
                        await likeDocRef.delete();
                        await mealPlanDocRef.update({
                          "likeCounts": FieldValue.increment(-1),
                        });
                      } else {
                        await likeDocRef.set({
                          "mealPlanID": doc.id,
                          "userID": currentUserId,
                          "timestamp": FieldValue.serverTimestamp(),
                        });
                        await mealPlanDocRef.update({
                          "likeCounts": FieldValue.increment(1),
                        });
                      }
                    },
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent, size: 18),
                    label: Text("$likeCount",
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3)),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
          // DOWNLOAD BUTTON - Stateless, no StreamBuilder
          TextButton.icon(
            onPressed: () async {
              final ownerSnapshot = await FirebaseFirestore.instance
                  .collection("Users")
                  .doc(ownerId)
                  .get();

              String ownerName = "Unknown Chef";
              if (ownerSnapshot.exists) {
                var ownerData = ownerSnapshot.data() as Map<String, dynamic>;
                ownerName =
                    "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                        .trim();
                if (ownerName.isEmpty) ownerName = "Unknown Chef";
              }
              if (isSubscribed) {
                await _downloadMealPlanAsPdf(context, data, ownerName, doc.id);
              } else {
                CustomSnackBar.show(
                  context,
                  'You must have an approved subscription to download this plan.',
                  backgroundColor: Colors.redAccent,
                  icon: Icons.lock,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            icon: const Icon(Icons.download_rounded,
                color: Colors.blueAccent, size: 18),
            label: const Text("Download",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontFamily: _primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItemExpanded(
      BuildContext context,
      String mealName,
      String? mealContent,
      String? mealTime,
      IconData icon,
      Color iconColor, {
        bool isLocked = false,
      }) {
    // Skip if meal content is empty
    if (mealContent == null || mealContent.isEmpty || mealContent == '-') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : iconColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and meal name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLocked
                            ? Colors.grey.shade600
                            : iconColor,
                        height: 1.5,
                      ),
                    ),
                    if ((mealTime ?? '').isNotEmpty && !isLocked) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: iconColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mealTime ?? '',
                            style: _getTextStyle(
                              context,
                              fontSize: 11,
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Meal content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLocked ? '••••••••••' : (mealContent ?? ''),
              style: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLocked
                    ? Colors.grey.shade500
                    : _textColorPrimary(context),
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }



// NEW HELPER METHOD: _mealRowWithTimeAndIcons with emoji icons
  Widget _mealRowWithTimeAndIcons(String label, String? value, String? time,
      {bool isLocked = false}) {
    if ((value == null || value.trim().isEmpty || value.trim() == '-') &&
        (time == null || time.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : _primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: _getTextStyle(context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? Colors.grey.shade600
                                : _primaryColor,
                            height: 1.5),
                      ),
                    ),
                    if (time != null && time.isNotEmpty && !isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 10, color: _primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: _getTextStyle(context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (value != null && value.isNotEmpty && value != '-')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isLocked ? '••••••••••' : value,
                      style: _getTextStyle(context,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLocked
                              ? Colors.grey.shade500
                              : _getTextStyle(context, fontSize: 13, height: 1.5).color,
                          height: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPreviewRow(
      BuildContext context,
      String label,
      String? value,
      String? time,
      bool isSubscribed,
      ) {
    if ((value == null || value.trim().isEmpty || value.trim() == '-')) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: _getTextStyle(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor, height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSubscribed ? (value ?? '-') : '•••••••••',
                style: _getTextStyle(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w500, height: 1.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (time != null && time.isNotEmpty && isSubscribed)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 10, color: _primaryColor),
                  const SizedBox(width: 3),
                  Text(
                    time,
                    style: _getTextStyle(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor, height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

// NEW: Helper function to build meal summary
  Widget _buildMealSummary(
      BuildContext context,
      String? summary,
      bool isSubscribed,
      ) {
    if (summary == null || summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 16,
            color: _primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSubscribed ? summary : summary.replaceAll(RegExp(r'.'), '•'),
              style: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textColorPrimary(context), height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// Helper function to count meals
  int _countMeals(Map<String, dynamic> data) {
    int count = 0;
    if (data["breakfast"] != null &&
        data["breakfast"].toString().trim().isNotEmpty &&
        data["breakfast"] != '-') count++;
    if (data["amSnack"] != null &&
        data["amSnack"].toString().trim().isNotEmpty &&
        data["amSnack"] != '-') count++;
    if (data["lunch"] != null &&
        data["lunch"].toString().trim().isNotEmpty &&
        data["lunch"] != '-') count++;
    if (data["pmSnack"] != null &&
        data["pmSnack"].toString().trim().isNotEmpty &&
        data["pmSnack"] != '-') count++;
    if (data["dinner"] != null &&
        data["dinner"].toString().trim().isNotEmpty &&
        data["dinner"] != '-') count++;
    if (data["midnightSnack"] != null &&
        data["midnightSnack"].toString().trim().isNotEmpty &&
        data["midnightSnack"] != '-') count++;
    return count;
  }

// Helper function to build action buttons (like and download)
  Widget _buildActionButtons(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isSubscribed,
      ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LIKE BUTTON - Isolated StreamBuilder
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("likes")
                .doc("${currentUserId}_${doc.id}")
                .snapshots(),
            builder: (context, likeSnapshot) {
              bool isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("mealPlans")
                    .doc(doc.id)
                    .snapshots(),
                builder: (context, mealSnapshot) {
                  if (!mealSnapshot.hasData) return const SizedBox();

                  final mealData = mealSnapshot.data!.data() as Map<String, dynamic>;
                  int likeCount = mealData["likeCounts"] ?? 0;

                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final likeDocRef = FirebaseFirestore.instance
                          .collection("likes")
                          .doc("${currentUserId}_${doc.id}");
                      final mealPlanDocRef = FirebaseFirestore.instance
                          .collection("mealPlans")
                          .doc(doc.id);

                      if (isLiked) {
                        await likeDocRef.delete();
                        await mealPlanDocRef.update({
                          "likeCounts": FieldValue.increment(-1),
                        });
                      } else {
                        await likeDocRef.set({
                          "mealPlanID": doc.id,
                          "userID": currentUserId,
                          "timestamp": FieldValue.serverTimestamp(),
                        });
                        await mealPlanDocRef.update({
                          "likeCounts": FieldValue.increment(1),
                        });
                      }
                    },
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$likeCount",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),

          // DOWNLOAD BUTTON - No StreamBuilder needed
          TextButton.icon(
            onPressed: () async {
              final ownerSnapshot = await FirebaseFirestore.instance
                  .collection("Users")
                  .doc(ownerId)
                  .get();

              String ownerName = "Unknown Chef";
              if (ownerSnapshot.exists) {
                var ownerData = ownerSnapshot.data() as Map<String, dynamic>;
                ownerName =
                    "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                        .trim();
                if (ownerName.isEmpty) ownerName = "Unknown Chef";
              }

              if (isSubscribed) {
                await _downloadMealPlanAsPdf(context, data, ownerName, doc.id);
              } else {
                CustomSnackBar.show(
                  context,
                  'You must have an approved subscription to download this plan.',
                  backgroundColor: Colors.redAccent,
                  icon: Icons.lock,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            icon: const Icon(Icons.download_rounded,
                color: Colors.blueAccent, size: 18),
            label: const Text(
              "Download",
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontFamily: _primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isUserSubscribed,
      ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("subscribeTo")
          .doc(ownerId)
          .snapshots(),
      builder: (context, subscribeSnapshot) {
        bool isSubscribed = false;
        if (subscribeSnapshot.hasData &&
            subscribeSnapshot.data != null &&
            subscribeSnapshot.data!.exists) {
          final subData =
          subscribeSnapshot.data!.data() as Map<String, dynamic>;
          if (subData["status"] == "approved") {
            isSubscribed = true;
          }
        }

        return SizedBox(
          width: 300,
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(right: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: _cardBgColor(context),
            child:

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- FIX: Owner Info Row MOVED TO TOP ---
                    FutureBuilder<DocumentSnapshot?>(
                      future: (ownerId.isNotEmpty)
                          ? FirebaseFirestore.instance
                          .collection("Users")
                          .doc(ownerId)
                          .get()
                          : Future.value(null),
                      builder: (context, ownerSnapshot) {
                        String ownerName = "Unknown Chef";
                        String ownerProfileUrl = "";

                        if (ownerId.isNotEmpty &&
                            ownerSnapshot.hasData &&
                            ownerSnapshot.data != null &&
                            ownerSnapshot.data!.exists) {
                          var ownerData = ownerSnapshot.data!.data()
                          as Map<String, dynamic>;
                          ownerName =
                              "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                                  .trim();
                          if (ownerName.isEmpty) ownerName = "Unknown Chef";
                          ownerProfileUrl = ownerData["profile"] ?? "";
                        }

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _primaryColor.withOpacity(0.2),
                              backgroundImage: (ownerProfileUrl.isNotEmpty)
                                  ? NetworkImage(ownerProfileUrl)
                                  : null,
                              child: (ownerProfileUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                  size: 24, color: _primaryColor)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ownerName,
                                    style: _cardTitleStyle(context).copyWith(
                                      color: _primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (data["timestamp"] != null &&
                                      data["timestamp"] is Timestamp)
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(
                                        (data["timestamp"] as Timestamp).toDate(),
                                      ),
                                      style: _cardSubtitleStyle(context)
                                          .copyWith(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // --- FIX: Description Box MOVED TO SECOND ---
                    if (data["description"] != null &&
                        data["description"].toString().trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data["description"] as String,
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _textColorPrimary(context),
                                      height: 1.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () =>
                                        _showFullDescription(
                                          context,
                                          data["description"]
                                          as String,
                                          data["planType"] ??
                                              "Meal Plan",
                                        ),
                                    child: Text(
                                      "View full description",
                                      style: _getTextStyle(
                                        context,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                        fontStyle: FontStyle.italic,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    Text(
                      data["planType"] ?? "Meal Plan",
                      style: _cardBodyTextStyle(context).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    _buildMealItemExpanded(
                      context,
                      "Breakfast",
                      data["breakfast"],
                      data["breakfastTime"],
                      Icons.wb_sunny_outlined,
                      Colors.orange,
                      isLocked: false,
                    ),
                    _buildMealItemExpanded(
                      context,
                      "AM Snack",
                      data["amSnack"],
                      data["amSnackTime"],
                      Icons.coffee_outlined,
                      Colors.brown,
                      isLocked: !isSubscribed,
                    ),
                    _buildMealItemExpanded(
                      context,
                      "Lunch",
                      data["lunch"],
                      data["lunchTime"],
                      Icons.restaurant_outlined,
                      Colors.green,
                      isLocked: !isSubscribed,
                    ),
                    _buildMealItemExpanded(
                      context,
                      "PM Snack",
                      data["pmSnack"],
                      data["pmSnackTime"],
                      Icons.local_cafe_outlined,
                      Colors.purple,
                      isLocked: !isSubscribed,
                    ),
                    _buildMealItemExpanded(
                      context,
                      "Dinner",
                      data["dinner"],
                      data["dinnerTime"],
                      Icons.nightlight_outlined,
                      Colors.indigo,
                      isLocked: !isSubscribed,
                    ),
                    _buildMealItemExpanded(
                      context,
                      "Midnight Snack",
                      data["midnightSnack"],
                      data["midnightSnackTime"],
                      Icons.bedtime_outlined,
                      Colors.blueGrey,
                      isLocked: !isSubscribed,
                    ),
                    if (!isSubscribed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: InkWell(
                          onTap: () {
                            _showSubscriptionDialog(data['ownerName'], ownerId);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_open,
                                    size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  'Subscribe to unlock',
                                  style: _getTextStyle(context,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _buildActionButtons(
                      context,
                      doc,
                      data,
                      ownerId,
                      currentUserId,
                      isSubscribed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget dietitiansList() {
    if (_searchFilter != "All" && _searchFilter != "Dietitians") {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.verified_user,
                        color: _primaryColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Expert Dietitians",
                        style: _sectionTitleStyle(context).copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Connect and get guidance",
                        style: _getTextStyle(
                          context,
                          fontSize: 12,
                          color: _textColorSecondary(context),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("Users")
                .where("role", isEqualTo: "dietitian")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                );
              var dietitians = snapshot.data!.docs;

              if (_searchQuery.isNotEmpty) {
                dietitians = dietitians.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name =
                  "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                      .toLowerCase();
                  String specialization =
                  (data["specialization"] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      specialization.contains(_searchQuery);
                }).toList();
              }

              if (dietitians.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off,
                          size: 40, color: _primaryColor.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? "No dietitians found"
                            : "No dietitians available",
                        style: _getTextStyle(context, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: dietitians.length,
                itemBuilder: (context, index) {
                  var dietitianData =
                  dietitians[index].data() as Map<String, dynamic>;
                  String dietitianId = dietitians[index].id;
                  String name =
                  "${dietitianData["firstName"] ?? ""} ${dietitianData["lastName"] ?? ""}"
                      .trim();
                  if (name.isEmpty) name = "Dietitian";
                  String profileUrl = dietitianData["profile"] ?? "";
                  String specialization =
                      dietitianData["specialization"] ?? "Nutrition Expert";

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DietitianPublicProfile(
                                dietitianId: dietitianId,
                                dietitianName: name,
                                dietitianProfile: profileUrl,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 160,
                          decoration: BoxDecoration(
                            color: _cardBgColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Background gradient effect
                              Positioned(
                                top: -40,
                                right: -40,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _primaryColor.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              // Main content
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Profile image with elegant shadow
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryColor.withOpacity(0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 38,
                                        backgroundColor:
                                        _primaryColor.withOpacity(0.15),
                                        backgroundImage:
                                        (profileUrl.isNotEmpty)
                                            ? NetworkImage(profileUrl)
                                            : null,
                                        child: (profileUrl.isEmpty)
                                            ? Icon(Icons.person,
                                            size: 40,
                                            color: _primaryColor)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Name
                                    Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style:
                                      _cardBodyTextStyle(context).copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Specialization badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        specialization,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        style: _getTextStyle(
                                          context,
                                          fontSize: 10,
                                          color: _primaryColor,
                                          fontWeight: FontWeight.w600,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Floating action button in top right
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryColor.withOpacity(0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Widget mealPlansTable(String userGoal) {
    if (_searchFilter == "Dietitians") {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("Users")
            .doc(firebaseUser!.uid)
            .get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String userGoal = userData["goals"] ?? "";
          bool isSubscribed = userData["isSubscribed"] ?? false;

          if (userGoal.isEmpty && _searchFilter != "Meal Plans") {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 40, color: _primaryColor),
                    const SizedBox(height: 12),
                    Text(
                      "Set Your Health Goal",
                      style: _getTextStyle(context,
                          fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Complete your profile to see personalized meal plans",
                      textAlign: TextAlign.center,
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        color: _textColorSecondary(context), height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchQuery.isNotEmpty
                          ? "Search Results"
                          : _searchFilter == "Meal Plans"
                          ? "All Meal Plans"
                          : "For: $userGoal",
                      style: _sectionTitleStyle(context).copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _searchQuery.isNotEmpty
                          ? "Results for \"$_searchQuery\""
                          : "Curated meal plans tailored for you",
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        color: _textColorSecondary(context), height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _searchFilter == "Meal Plans" || _searchQuery.isNotEmpty
                    ? FirebaseFirestore.instance
                    .collection("mealPlans")
                    .snapshots()
                    : FirebaseFirestore.instance
                    .collection("mealPlans")
                    .where("planType", isEqualTo: userGoal)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  var plans = snapshot.data!.docs;

                  plans = plans.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    final ownerId = data["ownerId"] ?? data["owner"] ?? "";
                    if (ownerId.isEmpty) return false;

                    final hasMealData = [
                      data["breakfast"],
                      data["amSnack"],
                      data["lunch"],
                      data["pmSnack"],
                      data["dinner"],
                      data["midnightSnack"],
                    ].any((meal) =>
                    meal != null &&
                        meal.toString().trim().isNotEmpty);

                    return hasMealData;
                  }).toList();

                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();

                    plans = plans.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;

                      final mealFields = [
                        data["breakfast"]?.toString().toLowerCase() ?? "",
                        data["amSnack"]?.toString().toLowerCase() ?? "",
                        data["lunch"]?.toString().toLowerCase() ?? "",
                        data["pmSnack"]?.toString().toLowerCase() ?? "",
                        data["dinner"]?.toString().toLowerCase() ?? "",
                        data["midnightSnack"]?.toString().toLowerCase() ?? "",
                        data["planName"]?.toString().toLowerCase() ?? "",
                        data["planType"]?.toString().toLowerCase() ?? "",
                        data["description"]?.toString().toLowerCase() ?? "",
                      ];

                      return mealFields.any((field) => field.contains(query));
                    }).toList();
                  }

                  if (plans.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.restaurant_menu_outlined,
                                size: 48,
                                color: _primaryColor.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? "No results found"
                                  : "No meal plans available",
                              style: _getTextStyle(context, fontSize: 16, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final docSnap = plans[index];
                      final data = docSnap.data() as Map<String, dynamic>;
                      final ownerId = data["owner"] ?? "";
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildMealPlanListItem(
                          context,
                          docSnap,
                          data,
                          ownerId,
                          firebaseUser!.uid,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _downloadMealPlanAsPdf(
      BuildContext context,
      Map<String, dynamic> mealPlanData,
      String ownerName,
      String docId,
      ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Text(
                  'Meal Plan',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                // Chef info
                pw.Text(
                  'Chef: $ownerName',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Plan Type: ${mealPlanData["planType"] ?? "Meal Plan"}',
                  style: pw.TextStyle(fontSize: 14),
                ),

                // Timestamp
                if (mealPlanData["timestamp"] != null)
                  pw.Text(
                    'Created: ${DateFormat('MMM dd, yyyy – hh:mm a').format((mealPlanData["timestamp"] as Timestamp).toDate())}',
                    style: pw.TextStyle(fontSize: 14),
                  ),

                pw.SizedBox(height: 16),

                // NEW: Description Section
                if (mealPlanData["description"] != null &&
                    mealPlanData["description"].toString().trim().isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Plan Description',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromHex('4CAF50'),
                            width: 1,
                          ),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          mealPlanData["description"].toString().trim(),
                          style: pw.TextStyle(
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                  ),

                pw.Divider(),
                pw.SizedBox(height: 10),

                // Meals Table
                pw.TableHelper.fromTextArray(
                  headers: ['Meal Type', 'Food', 'Time'],
                  data: [
                    ['Breakfast', mealPlanData["breakfast"] ?? '—', mealPlanData["breakfastTime"] ?? '—'],
                    ['AM Snack', mealPlanData["amSnack"] ?? '—', mealPlanData["amSnackTime"] ?? '—'],
                    ['Lunch', mealPlanData["lunch"] ?? '—', mealPlanData["lunchTime"] ?? '—'],
                    ['PM Snack', mealPlanData["pmSnack"] ?? '—', mealPlanData["pmSnackTime"] ?? '—'],
                    ['Dinner', mealPlanData["dinner"] ?? '—', mealPlanData["dinnerTime"] ?? '—'],
                    ['Midnight Snack', mealPlanData["midnightSnack"] ?? '—', mealPlanData["midnightSnackTime"] ?? '—'],
                  ],
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellHeight: 30,
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final now = DateTime.now();
      final filename = 'MealPlan_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.pdf';

      final params = SaveFileDialogParams(
        data: bytes,
        fileName: filename,
      );

      final savedFilePath = await FlutterFileDialog.saveFile(params: params);

      if (savedFilePath != null) {
        // Success - show custom snackbar
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Meal plan downloaded: $filename',
            backgroundColor: Colors.green,
            icon: Icons.download_done,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        // Cancelled by user
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Download canceled by user',
            backgroundColor: Colors.orange,
            icon: Icons.info,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      // Error occurred
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error generating PDF: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  TableRow _buildMealRow3(
      String label,
      dynamic value,
      dynamic time,
      bool isSubscribed,
      ) {
    final textStyle = TextStyle(
      fontSize: 14,
      fontFamily: _primaryFontFamily,
      color: Colors.black87,
    );

    final greyStyle = textStyle.copyWith(color: Colors.grey.shade600);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: greyStyle.copyWith(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            isSubscribed ? (value ?? "—") : "Locked 🔒",
            style: textStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            time ?? "—",
            style: greyStyle,
          ),
        ),
      ],
    );
  }


  Future<void> _updateGooglePhotoURL() async {
    if (firebaseUser == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection("Users")
        .doc(firebaseUser!.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists ||
        !snapshot.data()!.containsKey('profile') ||
        (snapshot.data()!['profile'] as String).isEmpty) {
      String? photoURL = firebaseUser!.photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        try {
          await userDoc.set(
            {"profile": photoURL},
            SetOptions(merge: true),
          );
          debugPrint("Firestore profile set from Google photo (first time only).");
        } catch (e) {
          debugPrint("Error updating Google Photo URL in Firestore: $e");
        }
      }
    } else {
      debugPrint("Firestore profile already set, skipping Google photo overwrite.");
    }
  }

  Future<void> _setUserStatus(String status) async {
    if (firebaseUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(firebaseUser!.uid)
            .set({"status": status}, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error setting user status: $e");
      }
    }
  }

  Future<bool> signOutFromGoogle() async {
    try {
      await _setUserStatus("offline");
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      debugPrint("Sign out error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setUserStatus("offline");
    super.dispose();
  }

  List<Widget> get _pages => [
    SingleChildScrollView(
      key: const PageStorageKey('homePageScroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          dietitiansList(),
          const SizedBox(height: 10),
          recommendationsWidget(),
          const SizedBox(height: 10),
          mealPlansTable(""),
          const SizedBox(height: 20),
        ],
      ),
    ),
    firebaseUser != null
        ? UserSchedulePage(currentUserId: firebaseUser!.uid)
        : const Center(
      child: Text(
        "Please log in to view your schedule.",
        style: TextStyle(fontFamily: _primaryFontFamily),
      ),
    ),
    firebaseUser != null
        ? UsersListPage(currentUserId: firebaseUser!.uid)
        : const Center(
      child: Text(
        "Please log in to view messages.",
        style: TextStyle(fontFamily: _primaryFontFamily),
      ),
    ),
    firebaseUser != null
        ? const UserProfile()
        : const Center(
      child: Text(
        "Please log in to view your profile.",
        style: TextStyle(fontFamily: _primaryFontFamily),
      ),
    ),
  ];

  Future<void> _showRateUsPopup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final firstName = userData['firstName'] as String? ?? '';
      final lastName = userData['lastName'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      final email = user.email ?? '';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _RateUsDialog(
            fullName: fullName,
            email: email,
            onSuccess: () {
              print('Rating submitted successfully');
            },
          ),
        );
      }
    } catch (e) {
      print('Error showing rate us dialog: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error loading rating dialog',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        body: Center(
          child: Text("No user logged in.", style: _cardBodyTextStyle(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Drawer(
          backgroundColor: _cardBgColor(context),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: _isUserNameLoading
                    ? Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.6),
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 120.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
                    : Text(
                  (firstName.isNotEmpty || lastName.isNotEmpty)
                      ? "$firstName $lastName".trim()
                      : "User Profile",
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _textColorOnPrimary,
                  ),
                ),
                accountEmail: _isUserNameLoading
                    ? Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.9),
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 150.0,
                    height: 14.0,
                    margin: const EdgeInsets.only(top: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
                    : (firebaseUser!.email != null &&
                    firebaseUser!.email!.isNotEmpty
                    ? Text(
                  firebaseUser!.email!,
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 14,
                    color: _textColorOnPrimary,
                  ),
                )
                    : null),
                currentAccountPicture: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 30, color: Colors.green),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final profileUrl = data?['profile'] ?? '';

                    if (profileUrl.isNotEmpty) {
                      return CircleAvatar(
                        backgroundImage: NetworkImage(profileUrl),
                      );
                    } else {
                      return const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 30, color: Colors.green),
                      );
                    }
                  },
                ),
                decoration: const BoxDecoration(color: _primaryColor),
                otherAccountsPictures: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: _textColorOnPrimary.withOpacity(0.8),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfile(),
                        ),
                      );
                    },
                    tooltip: "Edit Profile",
                  ),
                ],
              ),
              buildMenuTile('Subscription', Icons.subscriptions_outlined,
                  Icons.subscriptions),
              buildMenuTile('Rate Us', Icons.star_outline, Icons.star),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.black87),
                title: const Text('About', style: TextStyle(fontFamily: _primaryFontFamily)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              buildMenuTile('Logout', Icons.logout_outlined, Icons.logout),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: _textColorOnPrimary, size: 28),
        title: Text(
          selectedIndex == 0
              ? "Mama's Recipe"
              : (selectedIndex == 1
              ? "My Schedule"
              : (selectedIndex == 2 ? "Messages" : "Profile")),
          style: const TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfile()),
                );
              },
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30, color: _primaryColor),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final profileUrl = data?['profile'] ?? '';

                  return CircleAvatar(
                    backgroundImage: (profileUrl.isNotEmpty)
                        ? NetworkImage(profileUrl)
                        : null,
                    child: (profileUrl.isEmpty)
                        ? const Icon(Icons.person, size: 30, color: _primaryColor)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: _pages[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) {
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfile(),
                  ),
                );
              } else {
                setState(() => selectedIndex = index);
              }
            },
            selectedItemColor: _textColorOnPrimary,
            unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
            backgroundColor: _primaryColor,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: _getTextStyle(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textColorOnPrimary, height: 1.5,
            ),
            unselectedLabelStyle: _getTextStyle(
              context,
              fontSize: 11,
              color: _textColorOnPrimary.withOpacity(0.6), height: 1.5,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_calendar_outlined),
                activeIcon: Icon(Icons.edit_calendar),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mail_outline),
                activeIcon: Icon(Icons.mail),
                label: 'Messages',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuTile(String label, IconData icon, IconData activeIcon) {
    bool isSelected = selectedMenu == label;
    final Color itemColor =
    isSelected ? _primaryColor : _textColorPrimary(context);
    final Color itemBgColor =
    isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: itemColor,
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            color: itemColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: () async {
          Navigator.pop(context);
          if (label == 'Logout') {
            bool signedOut = await signOutFromGoogle();
            if (signedOut && mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginPageMobile(),
                ),
                    (Route<dynamic> route) => false,
              );
            }
          } else if (label == 'Rate Us') {
            _showRateUsPopup();
          } else if (label == 'Subscription') {
            showSubscriptionOptions(context, firebaseUser!.uid);
          } else {
            setState(() {
              selectedMenu = label;
            });
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
      ),
    );
  }
}


class UserSchedulePage extends StatefulWidget {
  final String currentUserId;
  const UserSchedulePage({super.key, required this.currentUserId});

  @override
  State<UserSchedulePage> createState() => _UserSchedulePageState();
}

class _UserSchedulePageState extends State<UserSchedulePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoadingEvents = true;
  String firstName = "";
  String lastName = "";
  bool _isUserNameLoading = true;

  Map<String, Map<String, dynamic>?> _weeklySchedule = {};
  bool _isLoadingSchedule = false;
  int _mealPlanTabIndex = 0; // Track which meal plan tab is active

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: _primaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: _getTextStyle(context,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColorPrimary(context),
                  height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _getTextStyle(context,
                  fontSize: 14,
                  color: _textColorSecondary(context),
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUserName();
    _loadAppointmentsForCalendar();
  }

  void _loadUserName() async {
    setState(() {
      _isUserNameLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (mounted) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            setState(() {
              firstName = data['firstName'] as String? ?? '';
              lastName = data['lastName'] as String? ?? '';
              _isUserNameLoading = false;
            });
          } else {
            setState(() {
              firstName = "";
              lastName = "";
              _isUserNameLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Error loading user name: $e");
        if (mounted) {
          setState(() {
            firstName = "";
            lastName = "";
            _isUserNameLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isUserNameLoading = false;
        });
      }
    }
  }

  Future<void> _loadAppointmentsForCalendar() async {
    if (mounted) {
      setState(() => _isLoadingEvents = true);
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('clientID', isEqualTo: widget.currentUserId)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('schedules')
            .where('clientId', isEqualTo: widget.currentUserId)
            .get();
      }

      final Map<DateTime, List<dynamic>> eventsMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final appointmentDateStr = data['appointmentDate'] as String?;
        if (appointmentDateStr != null) {
          try {
            final appointmentDateTime =
            DateFormat('yyyy-MM-dd HH:mm').parse(appointmentDateStr);
            final dateOnly = DateTime.utc(
              appointmentDateTime.year,
              appointmentDateTime.month,
              appointmentDateTime.day,
            );
            if (eventsMap[dateOnly] == null) {
              eventsMap[dateOnly] = [];
            }
            eventsMap[dateOnly]!.add(data);
          } catch (e) {
            print("Error parsing appointment date: $e");
          }
        }
      }
      if (mounted) {
        setState(() {
          _events = eventsMap;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      print("Error loading appointments for calendar: $e");
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(appointmentId)
          .update({'status': newStatus});

      _loadAppointmentsForCalendar();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Appointment status updated to $newStatus',
          backgroundColor: _primaryColor,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("Error updating appointment status: $e");
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error updating appointment: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(appointmentId)
          .update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      _loadAppointmentsForCalendar();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Appointment confirmed successfully!',
          backgroundColor: Colors.green,
          icon: Icons.verified,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("Error confirming appointment: $e");
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error confirming appointment: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _showCancelConfirmationDialog(
      String appointmentId, Map<String, dynamic> appointmentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Cancel Appointment?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No, Keep It'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCancellationReasonDialog(appointmentId, appointmentData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCancellationReasonDialog(
      String appointmentId, Map<String, dynamic> appointmentData) {
    final ValueNotifier<String?> selectedReason = ValueNotifier(null);

    final List<String> cancellationReasons = [
      'Schedule conflict',
      'Feeling unwell',
      'Emergency situation',
      'Need to reschedule',
      'Financial reasons',
      'Found another provider',
      'No longer needed',
      'Personal reasons',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cancellation Reason',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select a reason for cancelling:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String?>(
                  valueListenable: selectedReason,
                  builder: (context, selected, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: cancellationReasons.map((reason) {
                        return RadioListTile<String>(
                          title: Text(
                            reason,
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: reason,
                          groupValue: selected,
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (value) {
                            selectedReason.value = value;
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'A reason is required to cancel.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                selectedReason.dispose();
              },
              child: const Text('Back', style: TextStyle(color: Colors.grey)),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: selectedReason,
              builder: (context, selected, child) {
                return ElevatedButton(
                  onPressed: selected != null
                      ? () async {
                    final reason = selected;

                    Navigator.of(dialogContext).pop();
                    selectedReason.dispose();

                    if (!mounted) return;

                    showDialog(
                      context: this.context,
                      barrierDismissible: false,
                      builder: (progressContext) => WillPopScope(
                        onWillPop: () async => false,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 200,
                                minHeight: 100,
                              ),
                              child: Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                          color: Colors.orange),
                                      SizedBox(height: 16),
                                      Text(
                                        'Cancelling appointment...',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    await _cancelAppointment(
                        appointmentId, reason, appointmentData);

                    if (mounted &&
                        Navigator.of(this.context).canPop()) {
                      Navigator.of(this.context).pop();
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    selected != null ? Colors.red : Colors.grey.shade300,
                    foregroundColor:
                    selected != null ? Colors.white : Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Submit'),
                );
              },
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    ).then((_) {
      if (selectedReason.hasListeners) {
        selectedReason.dispose();
      }
    });
  }

  Future<String?> _checkSubscriptionStatus(String? userId, String? ownerId) async {
    if (userId == null || ownerId == null || userId == ownerId) {
      return 'active'; // Treat as active if same user
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('subscribeTo')
          .doc(ownerId)
          .get();

      if (doc.exists) {
        return doc.data()?['status'] as String?; // Returns: active, expired, cancelled, approved, etc.
      }
      return null; // Not subscribed
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return null;
    }
  }

  Future<void> _cancelAppointment(String appointmentId, String reason,
      Map<String, dynamic> appointmentData) async {
    if (reason.trim().isEmpty) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Cancellation reason is required',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
        );
      }
      return;
    }

    try {
      final appointmentRef =
      FirebaseFirestore.instance.collection('schedules').doc(appointmentId);

      final docSnapshot = await appointmentRef.get();

      if (!docSnapshot.exists) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Appointment not found',
            backgroundColor: Colors.redAccent,
            icon: Icons.error,
          );
        }
        return;
      }

      await appointmentRef.update({
        'status': 'cancelled',
        'cancellationReason': reason.trim(),
        'cancelledBy': 'client',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      await _loadAppointmentsForCalendar();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Appointment cancelled successfully',
          backgroundColor: Colors.orange,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint("Error cancelling appointment: $e");
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to cancel appointment. Please try again.',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLikedMealPlansWithOwners(
      String? userId) async {
    if (userId == null) return [];

    final firestore = FirebaseFirestore.instance;
    final likesSnapshot = await firestore
        .collection('likes')
        .where('userID', isEqualTo: userId)
        .get();

    if (likesSnapshot.docs.isEmpty) return [];

    final mealPlanIDs =
    likesSnapshot.docs.map((doc) => doc['mealPlanID'] as String).toList();
    final List<Map<String, dynamic>> mealPlans = [];

    for (String id in mealPlanIDs) {
      final mealPlanDoc = await firestore.collection('mealPlans').doc(id).get();
      if (mealPlanDoc.exists) {
        final planData = mealPlanDoc.data()!;
        planData['planId'] = id;
        String ownerId = planData['owner'] ?? '';
        String ownerName = 'Unknown';

        if (ownerId.isNotEmpty) {
          final userDoc = await firestore.collection('Users').doc(ownerId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            if (userData['role'] == 'dietitian') {
              ownerName =
                  "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
              if (ownerName.isEmpty) {
                ownerName = userData['name'] ??
                    userData['fullName'] ??
                    userData['displayName'] ??
                    ownerId;
              }
            }
          }
        }

        planData['ownerName'] = ownerName;
        mealPlans.add(planData);
      }
    }

    return mealPlans;
  }

  Future<List<Map<String, dynamic>>> _fetchPersonalizedMealPlans(
      String? userId) async {
    if (userId == null) return [];

    try {
      final firestore = FirebaseFirestore.instance;

      final snapshot = await firestore
          .collection('Users')
          .doc(userId)
          .collection('personalizedMealPlans')
          .get();

      if (snapshot.docs.isEmpty) return [];

      final List<Map<String, dynamic>> mealPlans = [];

      for (var doc in snapshot.docs) {
        final planData = doc.data();
        planData['planId'] = doc.id;

        String ownerId = planData['owner'] ?? '';
        String ownerName = planData['dietitianName'] ?? 'Your Dietitian';

        if (ownerId.isNotEmpty) {
          try {
            final userDoc =
            await firestore.collection('Users').doc(ownerId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              if (userData['role'] == 'dietitian') {
                ownerName =
                    "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
                if (ownerName.isEmpty) {
                  ownerName = userData['name'] ??
                      userData['fullName'] ??
                      userData['displayName'] ??
                      'Your Dietitian';
                }
              }
            }
          } catch (e) {
            print('Error fetching dietitian info: $e');
          }
        }

        planData['ownerName'] = ownerName;
        mealPlans.add(planData);
      }

      return mealPlans;
    } catch (e) {
      print('Error loading personalized meal plans: $e');
      return [];
    }
  }

  Future<void> _loadScheduledMealPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingSchedule = true;
    });

    try {
      final now = DateTime.now();
      final daysOfWeek = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];

      Map<String, Map<String, dynamic>?> loadedSchedule = {
        for (var day in daysOfWeek) day: null,
      };

      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayName = daysOfWeek[date.weekday - 1];

        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('scheduledMealPlans')
            .doc(dateStr)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            data['dateStr'] = dateStr;
            loadedSchedule[dayName] = data;
          }
        }
      }

      setState(() {
        _weeklySchedule = loadedSchedule;
        _isLoadingSchedule = false;
      });
    } catch (e) {
      print('Error loading scheduled meal plans: $e');
      setState(() {
        _isLoadingSchedule = false;
      });
    }
  }

  Future<void> _deleteMealPlanFromSchedule(String day, DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('scheduledMealPlans')
          .doc(dateStr)
          .get();

      final notificationId = doc.data()?['notificationId'] as int?;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('scheduledMealPlans')
          .doc(dateStr)
          .delete();

      if (notificationId != null) {
        await MealPlanNotificationService.cancelNotification(notificationId);
      }

      setState(() {
        _weeklySchedule[day] = null;
      });

      CustomSnackBar.show(
        context,
        'Meal plan removed and reminder cancelled',
        backgroundColor: Colors.orange,
        icon: Icons.delete,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error deleting meal plan: $e');
    }
  }

  Future<void> _saveMealPlanToSchedule(
      String day, DateTime date, Map<String, dynamic> plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final notificationId = date.millisecondsSinceEpoch ~/ 1000;

      // ✅ Track if this is a personalized plan or liked plan
      final bool isFromPersonalized = _mealPlanTabIndex == 1;

      // ✅ Save to Firestore FIRST (this should always succeed)
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('scheduledMealPlans')
          .doc(dateStr)
          .set({
        'day': day,
        'date': Timestamp.fromDate(date),
        'dateStr': dateStr,
        'planType': plan['planType'],
        'description': plan['description'],
        'breakfast': plan['breakfast'],
        'breakfastTime': plan['breakfastTime'],
        'amSnack': plan['amSnack'],
        'amSnackTime': plan['amSnackTime'],
        'lunch': plan['lunch'],
        'lunchTime': plan['lunchTime'],
        'pmSnack': plan['pmSnack'],
        'pmSnackTime': plan['pmSnackTime'],
        'dinner': plan['dinner'],
        'dinnerTime': plan['dinnerTime'],
        'midnightSnack': plan['midnightSnack'],
        'midnightSnackTime': plan['midnightSnackTime'],
        'owner': plan['owner'],
        'ownerName': plan['ownerName'],
        'planId': plan['planId'],
        'isPersonalized': isFromPersonalized,
        'notificationId': notificationId,
        'scheduledAt': FieldValue.serverTimestamp(),
      });

      final userDoc =
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

      final userData = userDoc.data();
      final userEmail = userData?['email'] ?? user.email ?? '';
      final userName =
      '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'
          .trim();

      // ✅ Try to schedule notifications, but don't fail the whole operation if it fails
      try {
        await MealPlanNotificationService.scheduleReminderNotification(
          notificationId: notificationId,
          mealPlanDate: date,
          planType: plan['planType'] ?? 'Meal Plan',
          dayName: day,
        );
      } catch (e) {
        debugPrint('Warning: Could not schedule reminder notification: $e');
        // Don't fail here - notification is not critical
      }

      try {
        await MealPlanNotificationService.sendPushNotification(
          userId: user.uid,
          userName: userName.isNotEmpty ? userName : 'User',
          ownerId: plan['owner'] ?? '',
          ownerName: plan['ownerName'] ?? 'Dietitian',
          mealPlanDate: date,
          dayName: day,
          planType: plan['planType'] ?? 'Meal Plan',
        );
      } catch (e) {
        debugPrint('Warning: Could not send push notification: $e');
        // Don't fail here
      }

      try {
        if (userEmail.isNotEmpty) {
          await MealPlanNotificationService.sendEmailReminder(
            userEmail: userEmail,
            userName: userName.isNotEmpty ? userName : 'User',
            mealPlanDate: date,
            dayName: day,
            planType: plan['planType'] ?? 'Meal Plan',
            mealDetails: plan,
            userId: user.uid,
            ownerId: plan['owner'] ?? '',
          );
        }
      } catch (e) {
        debugPrint('Warning: Could not send email reminder: $e');
        // Don't fail here
      }

      plan['dateStr'] = dateStr;
      plan['isPersonalized'] = isFromPersonalized;

      setState(() {
        _weeklySchedule[day] = plan;
      });

      CustomSnackBar.show(
        context,
        'Meal plan scheduled for $day! Reminder set for ${_formatReminderDate(date)}',
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error saving meal plan: $e');
      CustomSnackBar.show(
        context,
        'Error scheduling meal plan: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  String _formatReminderDate(DateTime date) {
    final reminderDate = date.subtract(const Duration(days: 1));
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[reminderDate.month - 1]} ${reminderDate.day}, 8:00 AM';
  }

  Future<bool> _isUserSubscribedToOwner(
      String? userId, String? ownerId) async {
    if (userId == null || ownerId == null || userId == ownerId) {
      return true;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc('${userId}_$ownerId')
          .get();

      return doc.exists && (doc.data()?['status'] == 'active');
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }

  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: _cardBgColor(context),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TableCalendar(
              locale: 'en_US',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                    color: _primaryColor, shape: BoxShape.circle),
                selectedTextStyle: _getTextStyle(context,
                    color: _textColorOnPrimary,
                    fontWeight: FontWeight.bold,
                    height: 1.5),
                todayDecoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle),
                todayTextStyle: _getTextStyle(context,
                    color: _textColorOnPrimary,
                    fontWeight: FontWeight.bold,
                    height: 1.5),
                weekendTextStyle: _getTextStyle(context,
                    color: _primaryColor.withOpacity(0.8), height: 1.5),
                defaultTextStyle: _getTextStyle(context,
                    color: _textColorPrimary(context), height: 1.5),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(
                            color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text('${events.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                  return null;
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: _getTextStyle(context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(context),
                    height: 1.5),
                formatButtonTextStyle: _getTextStyle(context,
                    color: _textColorOnPrimary, height: 1.5),
                formatButtonDecoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(20.0)),
                leftChevronIcon:
                Icon(Icons.chevron_left, color: _textColorPrimary(context)),
                rightChevronIcon:
                Icon(Icons.chevron_right, color: _textColorPrimary(context)),
              ),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
        ),
        if (_isLoadingEvents)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
                child: CircularProgressIndicator(color: _primaryColor)),
          )
        else if (_selectedDay != null)
          Expanded(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Appointments for ${DateFormat.yMMMMd().format(_selectedDay!)}:",
                    style: _getTextStyle(context,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColorPrimary(context),
                        height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  _buildScheduledAppointmentsList(_selectedDay!),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          )
        else if (!_isLoadingEvents)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Select a day to see your appointments.",
                    style: _getTextStyle(context,
                        color: _textColorSecondary(context), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final orderedDays = List.generate(7, (i) {
      final date = now.add(Duration(days: i));
      final weekdayName = daysOfWeek[date.weekday - 1];
      return {'label': weekdayName, 'date': date};
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: _primaryColor,
            foregroundColor: _textColorOnPrimary,
            elevation: 0,
            automaticallyImplyLeading: false,
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColorOnPrimary,
                height: 1.5,
              ),
              unselectedLabelStyle: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColorOnPrimary.withOpacity(0.7),
                height: 1.5,
              ),
              tabs: const [
                Tab(
                    icon: Icon(Icons.calendar_today, size: 20),
                    text: 'Appointments'),
                Tab(
                    icon: Icon(Icons.restaurant_menu, size: 20),
                    text: 'Meal Plans'),
              ],
            ),
          ),
        ),
        body: // Replace the TabBarView section in the build method with this:

        TabBarView(
          children: [
            _buildAppointmentsTab(),
            // --- MEAL PLANS TAB WITH MANUAL TABS ---
            Column(
              children: [
                // Manual Tab Bar for Liked vs Personalized
                Container(
                  color: _cardBgColor(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mealPlanTabIndex = 0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _mealPlanTabIndex == 0
                                      ? _primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Your Liked Plans',
                                style: _getTextStyle(
                                  context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _mealPlanTabIndex == 0
                                      ? _primaryColor
                                      : _textColorSecondary(context),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mealPlanTabIndex = 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _mealPlanTabIndex == 1
                                      ? _primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Your Personalized Plans',
                                style: _getTextStyle(
                                  context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _mealPlanTabIndex == 1
                                      ? _primaryColor
                                      : _textColorSecondary(context),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab Content
                Expanded(
                  child: IndexedStack(
                    index: _mealPlanTabIndex,
                    children: [
                      // --- LIKED MEAL PLANS TAB ---
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchLikedMealPlansWithOwners(user?.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(color: _primaryColor));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState(
                              "No Liked Plans",
                              "Like a meal plan from the Home feed to see it here.",
                              Icons.favorite_border,
                            );
                          }

                          final mealPlans = snapshot.data!;

                          if (_weeklySchedule.isEmpty && !_isLoadingSchedule) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _loadScheduledMealPlans();
                            });
                          }

                          return _buildMealPlansContent(mealPlans, user, orderedDays);
                        },
                      ),
                      // --- PERSONALIZED MEAL PLANS TAB ---
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchPersonalizedMealPlans(user?.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(color: _primaryColor));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState(
                              "No Personalized Plans",
                              "Your dietitian will create personalized meal plans for you here.",
                              Icons.assignment,
                            );
                          }

                          final mealPlans = snapshot.data!;

                          if (_weeklySchedule.isEmpty && !_isLoadingSchedule) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _loadScheduledMealPlans();
                            });
                          }

                          return _buildMealPlansContent(mealPlans, user, orderedDays);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      )
    );
  }

  Widget _planCard(Map<String, dynamic> plan, {bool isDragging = false}) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.1),
            _primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDragging)
            BoxShadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant_menu_rounded,
                color: _primaryColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            plan['planType'] ?? 'Meal Plan',
            style: _getTextStyle(context,
                fontWeight: FontWeight.bold, fontSize: 14, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: _textColorSecondary(context)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  plan['ownerName'] ?? 'Unknown Owner',
                  style: _getTextStyle(context,
                      fontSize: 12, color: _textColorSecondary(context), height: 1.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealRowWithTime(String label, String? value, String? time,
      {bool isLocked = false}) {
    if ((value == null || value.trim().isEmpty || value.trim() == '-') &&
        (time == null || time.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : _primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: _getTextStyle(context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? Colors.grey.shade600
                                : _primaryColor,
                            height: 1.5),
                      ),
                    ),
                    if (time != null && time.isNotEmpty && !isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 10, color: _primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: _getTextStyle(context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (value != null && value.isNotEmpty && value != '-')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isLocked ? '•••••••••' : value,
                      style: _getTextStyle(context,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLocked
                              ? Colors.grey.shade500
                              : _getTextStyle(context, fontSize: 13, height: 1.5)
                              .color,
                          height: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(String? ownerName, String? ownerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium Content',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscribe to ${ownerName ?? "this creator"} to unlock all meal details and times.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _benefitRow('Full meal plans with times'),
                    _benefitRow('Personalized nutrition guidance'),
                    _benefitRow('Exclusive recipes'),
                    _benefitRow('Direct creator support'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Subscribe Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: _getTextStyle(context, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbrev(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // Add this complete method to your _UserSchedulePageState class
// Place it before the _buildScheduledAppointmentsList method

  Widget _buildMealPlansContent(List<Map<String, dynamic>> mealPlans, User? user,
      List<Map<String, dynamic>> orderedDays) {
    final now = DateTime.now();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.15),
                  _primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.touch_app, color: _primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Long press and drag meal plans to schedule your week",
                    style: _getTextStyle(
                      context,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.favorite, color: _primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                "Available Meal Plans",
                style: _getTextStyle(context,
                    fontSize: 18, fontWeight: FontWeight.w700, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: mealPlans.map((plan) {
              return LongPressDraggable<Map<String, dynamic>>(
                data: plan,
                feedback: Material(
                    color: Colors.transparent,
                    child: _planCard(plan, isDragging: true)),
                childWhenDragging: Opacity(
                    opacity: 0.3, child: _planCard(plan)),
                child: _planCard(plan),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.calendar_month, color: _primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                "Weekly Schedule",
                style: _getTextStyle(context,
                    fontSize: 18, fontWeight: FontWeight.w700, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSchedule)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: _primaryColor),
              ),
            )
          else
            SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: orderedDays.length,
                itemBuilder: (context, index) {
                  final dayInfo = orderedDays[index];
                  final day = dayInfo['label'] as String;
                  final date = dayInfo['date'] as DateTime;
                  final formattedDate = "${_monthAbbrev(date.month)} ${date.day}";
                  final plan = _weeklySchedule[day];
                  final isToday = date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;

                  // ✅ Check if this is a personalized plan
                  final bool isPersonalized = plan?['isPersonalized'] ?? false;

                  return DragTarget<Map<String, dynamic>>(
                    onAccept: (receivedPlan) {
                      _saveMealPlanToSchedule(day, date, receivedPlan);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;
                      return Container(
                        width: 270,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: isHovering
                              ? _primaryColor.withOpacity(0.1)
                              : _cardBgColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isToday
                                ? _primaryColor
                                : isHovering
                                ? _primaryColor.withOpacity(0.5)
                                : Colors.transparent,
                            width: isToday ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          day,
                                          style: _getTextStyle(context,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              height: 1.5),
                                        ),
                                        if (isToday) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _primaryColor,
                                              borderRadius:
                                              BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'TODAY',
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                height: 1.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      formattedDate,
                                      style: _getTextStyle(context,
                                          color:
                                          _textColorSecondary(context),
                                          fontSize: 12,
                                          height: 1.5),
                                    ),
                                  ],
                                ),
                                if (plan != null)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.close,
                                        color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      _deleteMealPlanFromSchedule(day, date);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (plan == null)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.2),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: _primaryColor
                                              .withOpacity(0.4),
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Drop plan here",
                                          style: _getTextStyle(context,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _textColorSecondary(
                                                  context),
                                              height: 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              _buildScheduledMealPlanContent(
                              plan,
                              user,
                              isPersonalized: isPersonalized,)
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduledAppointmentsList(DateTime selectedDate) {
    final normalizedSelectedDate =
    DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEvents = _events[normalizedSelectedDate] ?? [];

    if (dayEvents.isEmpty) {
      return Card(
        color: _cardBgColor(context),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No appointments scheduled for this day yet.",
              style: _getTextStyle(context,
                  color: _textColorSecondary(context), height: 1.5),
            ),
          ),
        ),
      );
    }

    dayEvents.sort((a, b) {
      try {
        final dateA = DateFormat('yyyy-MM-dd HH:mm').parse(a['appointmentDate']);
        final dateB = DateFormat('yyyy-MM-dd HH:mm').parse(b['appointmentDate']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return Column(
      children: dayEvents.map<Widget>((data) {
        DateTime appointmentDateTime;
        try {
          appointmentDateTime =
              DateFormat('yyyy-MM-dd HH:mm').parse(data['appointmentDate']);
        } catch (e) {
          print("Error parsing appointment date: $e");
          return const SizedBox.shrink();
        }
        final formattedTime = DateFormat.jm().format(appointmentDateTime);
        final status = data['status'] ?? 'scheduled';
        final appointmentId = data['id'];

        final statusColor = _getStatusColor(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardBgColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: _primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data['dietitianName'] ?? 'Unknown Dietitian',
                        style: _getTextStyle(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedTime,
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColorPrimary(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_outline_rounded,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusDisplayText(status),
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (data['notes'] != null &&
                    data['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: _textColorSecondary(context).withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['notes'],
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            color: _textColorSecondary(context),
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'Waiting for client response.') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmAppointment(appointmentId),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showCancelConfirmationDialog(appointmentId, data),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'proposed_by_dietitian':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return 'Scheduled';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'proposed_by_dietitian':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return _primaryColor;
    }
  }

  Widget _buildScheduledMealPlanContent(Map<String, dynamic> plan, User? user,
      {bool isPersonalized = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor,
                  _primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    plan['planType'] ?? 'Meal Plan',
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<String?>(
              future: isPersonalized
                  ? Future.value('active') // ✅ Always active for personalized plans
                  : _checkSubscriptionStatus(user?.uid, plan['owner']),
              builder: (context, snapshot) {
                // While loading, show loading indicator
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final subscriptionStatus = snapshot.data;

                // ✅ Check if subscription is valid
                final bool isLocked = !isPersonalized &&
                    (subscriptionStatus == null ||
                        subscriptionStatus == 'expired' ||
                        subscriptionStatus == 'cancelled');

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Show description if available
                      if (plan['description'] != null &&
                          plan['description'].toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: _primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Plan Description",
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                plan['description'],
                                style: _getTextStyle(
                                  context,
                                  fontSize: 12,
                                  color: _textColorSecondary(context),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ✅ Always show all meals - Breakfast unlocked, rest locked if not subscribed
                      _mealRowWithTime(
                        "Breakfast",
                        plan['breakfast'],
                        plan['breakfastTime'],
                        isLocked: false,
                      ),
                      _mealRowWithTime(
                        "AM Snack",
                        plan['amSnack'],
                        plan['amSnackTime'],
                        isLocked: isLocked,
                      ),
                      _mealRowWithTime(
                        "Lunch",
                        plan['lunch'],
                        plan['lunchTime'],
                        isLocked: isLocked,
                      ),
                      _mealRowWithTime(
                        "PM Snack",
                        plan['pmSnack'],
                        plan['pmSnackTime'],
                        isLocked: isLocked,
                      ),
                      _mealRowWithTime(
                        "Dinner",
                        plan['dinner'],
                        plan['dinnerTime'],
                        isLocked: isLocked,
                      ),
                      _mealRowWithTime(
                        "Midnight Snack",
                        plan['midnightSnack'],
                        plan['midnightSnackTime'],
                        isLocked: isLocked,
                      ),

                      // ✅ Show subscription prompt if locked
                      if (isLocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: InkWell(
                            onTap: () {
                              _showSubscriptionDialog(
                                  plan['ownerName'], plan['owner']);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock_open,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subscriptionStatus == 'expired'
                                          ? 'Subscription expired. Renew to unlock'
                                          : subscriptionStatus == 'cancelled'
                                          ? 'Subscription cancelled. Resubscribe to unlock'
                                          : 'Subscribe to unlock all meals',
                                      style: _getTextStyle(context,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                          height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



class UsersListPage extends StatefulWidget {
  final String currentUserId;
  const UsersListPage({super.key, required this.currentUserId});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  // --- STATE VARIABLES ---
  List<Map<String, dynamic>> _sortedChats = [];
  bool _isLoadingChats = true;
  String _selectedNotificationFilter = 'all'; // 'all', 'appointment', 'message', 'pricing'

  @override
  void initState() {
    super.initState();
    _loadAndSortChats();
  }
  Widget _buildCompactFilterChip(String filter) {
    final isSelected = _selectedNotificationFilter == filter;
    final chipColor = _getFilterChipColor(filter);
    final chipIcon = _getFilterChipIcon(filter);
    final chipLabel = _getFilterChipLabel(filter);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? chipColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? chipColor : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedNotificationFilter = filter;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              size: 14,
              color: isSelected ? chipColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              chipLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? chipColor : Colors.grey.shade600,
                fontFamily: _primaryFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- HELPER FUNCTIONS (moved to class level) ---

  /// Show confirmation dialog with premium design
  Future<void> _showClearAllDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardBgColor(dialogContext),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Clear Notifications?',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(dialogContext), height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to clear all notifications?)',
                  textAlign: TextAlign.center,
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 14,
                    color: _textColorSecondary(dialogContext), height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: _primaryColor, width: 1.5),
                      foregroundColor: _primaryColor,
                    ),
                    child: Text(
                      'Cancel',
                      style: _getTextStyle(
                        dialogContext,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor, height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                    label: Text(
                      'Yes, Clear All',
                      style: _getTextStyle(
                        dialogContext,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      _clearAllNotifications();
    }
  }

  /// Clear all notifications function
  Future<void> _clearAllNotifications() async {
    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.currentUserId)
          .collection("notifications")
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notificationsSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'All notifications cleared from view.',
          backgroundColor: _primaryColor,
          icon: Icons.done_all,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error clearing notifications: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
        );
      }
    }
  }

  /// Get notification type for filtering
  String _getNotificationType(Map<String, dynamic> data) {
    final type = (data["type"] ?? '').toString().toLowerCase();
    if (type.contains('message')) return 'message';
    if (type.contains('appointment') || type.contains('appointment_update')) return 'appointment';
    if (type.contains('pricing') || type.contains('subscription')) return 'pricing';
    return 'other';
  }

  /// Get color for filter chip
  Color _getFilterChipColor(String filter) {
    switch (filter) {
      case 'appointment':
        return const Color(0xFFFF9800);
      case 'message':
        return const Color(0xFF2196F3);
      case 'pricing':
        return const Color(0xFF9C27B0);
      default:
        return _primaryColor;
    }
  }

  /// Get icon for filter chip
  IconData _getFilterChipIcon(String filter) {
    switch (filter) {
      case 'appointment':
        return Icons.event_available_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'pricing':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Get label for filter chip
  String _getFilterChipLabel(String filter) {
    switch (filter) {
      case 'appointment':
        return 'Appointments';
      case 'message':
        return 'Messages';
      case 'pricing':
        return 'Pricing';
      default:
        return 'All';
    }
  }

  /// Filter notifications based on selected filter
  bool _shouldShowNotification(Map<String, dynamic> data) {
    if (_selectedNotificationFilter == 'all') return true;
    final notificationType = _getNotificationType(data);
    return notificationType == _selectedNotificationFilter;
  }

  /// Build filter chip widget
  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedNotificationFilter == filter;
    final chipColor = _getFilterChipColor(filter);
    final chipIcon = _getFilterChipIcon(filter);
    final chipLabel = _getFilterChipLabel(filter);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedNotificationFilter = filter;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: chipColor.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            size: 16,
            color: isSelected ? chipColor : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            chipLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? chipColor : Colors.grey.shade600,
              fontFamily: _primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  String getChatRoomId(String userA, String userB) {
    if (userA.compareTo(userB) > 0) {
      return "$userB\_$userA";
    } else {
      return "$userA\_$userB";
    }
  }

  Future<List<String>> getFollowedDietitianIds() async {
    try {
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.currentUserId)
          .collection('following')
          .get();
      return followingSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching followed dietitians: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getLastMessage(
      BuildContext context,
      String chatRoomId,
      ) async {
    final query = await FirebaseFirestore.instance
        .collection("messages")
        .where("chatRoomID", isEqualTo: chatRoomId)
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return {"message": "", "isMe": false, "time": "", "timestampObject": null};
    }

    final data = query.docs.first.data();
    String formattedTime = "";
    final timestamp = data["timestamp"];
    DateTime? messageDate;

    if (timestamp is Timestamp) {
      messageDate = timestamp.toDate();
      DateTime nowDate = DateTime.now();
      if (messageDate.year == nowDate.year &&
          messageDate.month == nowDate.month &&
          messageDate.day == nowDate.day) {
        formattedTime = TimeOfDay.fromDateTime(messageDate).format(context);
      } else {
        formattedTime = DateFormat('MMM d').format(messageDate);
      }
    }

    return {
      "message": data["message"] ?? "",
      "isMe": data["senderId"] == FirebaseAuth.instance.currentUser!.uid,
      "time": formattedTime,
      "senderName": data["senderName"] ?? "Unknown",
      "timestampObject": messageDate,
    };
  }

  Future<void> _loadAndSortChats() async {
    if (!mounted) return;
    setState(() => _isLoadingChats = true);

    try {
      final followedDietitianIds = await getFollowedDietitianIds();
      final usersSnapshot = await FirebaseFirestore.instance.collection("Users").get();
      final users = usersSnapshot.docs;

      final filteredUsers = users.where((userDoc) {
        if (userDoc.id == widget.currentUserId) return false;
        final data = userDoc.data();
        final role = data["role"]?.toString().toLowerCase() ?? "";
        if (role == "admin") return true;
        if (role == "dietitian" && followedDietitianIds.contains(userDoc.id)) {
          return true;
        }
        return false;
      }).toList();

      if (filteredUsers.isEmpty) {
        if (mounted) setState(() => _isLoadingChats = false);
        return;
      }

      List<Future<Map<String, dynamic>>> chatFutures = [];
      for (var userDoc in filteredUsers) {
        chatFutures.add(_fetchChatDetails(userDoc));
      }

      final resolvedChats = await Future.wait(chatFutures);

      resolvedChats.sort((a, b) {
        final timeA = a['lastMessage']['timestampObject'] as DateTime?;
        final timeB = b['lastMessage']['timestampObject'] as DateTime?;

        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;

        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _sortedChats = resolvedChats;
          _isLoadingChats = false;
        });
      }
    } catch (e) {
      print("Error loading and sorting chats: $e");
      if (mounted) setState(() => _isLoadingChats = false);
    }
  }

  Future<Map<String, dynamic>> _fetchChatDetails(DocumentSnapshot userDoc) async {
    final data = userDoc.data() as Map<String, dynamic>;
    final senderName = "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
    final chatRoomId = getChatRoomId(widget.currentUserId, userDoc.id);

    final lastMessageData = await getLastMessage(context, chatRoomId);

    return {
      'userDoc': userDoc,
      'lastMessage': lastMessageData,
    };
  }

  void _showPriceChangeDialog(BuildContext context, Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String title = notificationData['title'] ?? 'Price Change Notification';
        final String message = notificationData['message'] ?? 'No details available';
        final String dietitianName = notificationData['dietitianName'] ?? 'Dietitian';
        final Timestamp? timestamp = notificationData['timestamp'] as Timestamp?;

        final monthlyOld = notificationData['monthlyOldPrice']?.toString() ?? 'N/A';
        final monthlyNew = notificationData['monthlyNewPrice']?.toString() ?? 'N/A';
        final weeklyOld = notificationData['weeklyOldPrice']?.toString() ?? 'N/A';
        final weeklyNew = notificationData['weeklyNewPrice']?.toString() ?? 'N/A';
        final yearlyOld = notificationData['yearlyOldPrice']?.toString() ?? 'N/A';
        final yearlyNew = notificationData['yearlyNewPrice']?.toString() ?? 'N/A';

        String formattedDate = '';
        if (timestamp != null) {
          formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.price_change_outlined,
                          color: Colors.orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (formattedDate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontFamily: _primaryFontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18, color: _primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              dietitianName,
                              style: const TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPriceComparison('Monthly', monthlyOld, monthlyNew),
                      const SizedBox(height: 12),
                      _buildPriceComparison('Weekly', weeklyOld, weeklyNew),
                      const SizedBox(height: 12),
                      _buildPriceComparison('Yearly', yearlyOld, yearlyNew),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMealPlanScheduledDialog(BuildContext context, Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String title = notificationData['title'] ?? 'Meal Plan Scheduled';
        final String message = notificationData['message'] ?? 'No details available';
        final String senderName = notificationData['senderName'] ?? 'Dietitian';
        final String planType = notificationData['planType'] ?? 'Meal Plan';
        final String dayName = notificationData['dayName'] ?? '';
        final Timestamp? timestamp = notificationData['timestamp'] as Timestamp?;

        String mealPlanDate = '';
        if (notificationData['mealPlanDate'] != null) {
          try {
            final date = DateTime.parse(notificationData['mealPlanDate']);
            mealPlanDate = DateFormat('MMMM dd, yyyy').format(date);
          } catch (e) {
            print('Error parsing meal plan date: $e');
          }
        }

        String formattedDate = '';
        if (timestamp != null) {
          formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: _primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (formattedDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Scheduled on: $formattedDate',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Meal Plan Type
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withOpacity(0.15),
                                _primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plan Type',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          planType,
                                          style: const TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (dayName.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Divider(color: _primaryColor.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: _primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Scheduled for: $dayName',
                                        style: const TextStyle(
                                          fontFamily: _primaryFontFamily,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (mealPlanDate.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.event, size: 16, color: _primaryColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          mealPlanDate,
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Dietitian Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: _primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Created by: $senderName',
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Reminder Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notifications_active, size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You\'ll receive a reminder 1 day before at 8:00 AM',
                                  style: TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMealPlanCreatedDialog(BuildContext context, Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String title = notificationData['title'] ?? 'Meal Plan Created';
        final String message = notificationData['message'] ?? 'Your meal plan has been successfully created.';
        final String senderName = notificationData['senderName'] ?? 'Dietitian';
        final String planType = notificationData['planType'] ?? 'Meal Plan';
        final String dayName = notificationData['dayName'] ?? '';
        final Timestamp? timestamp = notificationData['timestamp'] as Timestamp?;

        String mealPlanDate = '';
        if (notificationData['mealPlanDate'] != null) {
          try {
            final date = DateTime.parse(notificationData['mealPlanDate']);
            mealPlanDate = DateFormat('MMMM dd, yyyy').format(date);
          } catch (e) {
            print('Error parsing meal plan date: $e');
          }
        }

        String formattedDate = '';
        if (timestamp != null) {
          formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: _primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (formattedDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Created on: $formattedDate',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Meal Plan Type
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withOpacity(0.15),
                                _primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plan Type',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          planType,
                                          style: const TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (dayName.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Divider(color: _primaryColor.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: _primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Scheduled for: $dayName',
                                        style: const TextStyle(
                                          fontFamily: _primaryFontFamily,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (mealPlanDate.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.event, size: 16, color: _primaryColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          mealPlanDate,
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Dietitian Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: _primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Created by: $senderName',
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMealPlanDeclinedDialog(BuildContext context, Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String title = notificationData['title'] ?? 'Meal Plan Declined';
        final String message = notificationData['message'] ?? 'Your meal plan request has been declined.';
        final String senderName = notificationData['senderName'] ?? 'Dietitian';
        final String planType = notificationData['planType'] ?? 'Meal Plan';
        final String dayName = notificationData['dayName'] ?? '';
        final Timestamp? timestamp = notificationData['timestamp'] as Timestamp?;

        String mealPlanDate = '';
        if (notificationData['mealPlanDate'] != null) {
          try {
            final date = DateTime.parse(notificationData['mealPlanDate']);
            mealPlanDate = DateFormat('MMMM dd, yyyy').format(date);
          } catch (e) {
            print('Error parsing meal plan date: $e');
          }
        }

        String formattedDate = '';
        if (timestamp != null) {
          formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.cancel_outlined,
                            color: _primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (formattedDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Processed on: $formattedDate',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Meal Plan Type
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withOpacity(0.15),
                                _primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plan Type',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          planType,
                                          style: const TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (dayName.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Divider(color: _primaryColor.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: _primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Scheduled for: $dayName',
                                        style: const TextStyle(
                                          fontFamily: _primaryFontFamily,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (mealPlanDate.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.event, size: 16, color: _primaryColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          mealPlanDate,
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Dietitian Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: _primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Processed by: $senderName',
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.black),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMealPlanNotif(BuildContext context, Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String title = notificationData['title'] ?? 'New Meal Plan';
        final String message = notificationData['message'] ?? 'No details available';
        final String senderName = notificationData['senderName'] ?? 'Dietitian';
        final String planType = notificationData['planType'] ?? 'Meal Plan';
        final Timestamp? timestamp = notificationData['timestamp'] as Timestamp?;

        String formattedDate = '';
        if (timestamp != null) {
          formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: _primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (formattedDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Received: $formattedDate',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Meal Plan Type
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withOpacity(0.15),
                                _primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Plan Type',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontFamily: _primaryFontFamily,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      planType,
                                      style: const TextStyle(
                                        fontFamily: _primaryFontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Dietitian Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: _primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'From: $senderName',
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubscriptionDialog(BuildContext context, Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String title = notificationData['title'] ?? 'Subscription Update';
        final String message = notificationData['message'] ?? 'No details available';
        final String senderName = notificationData['senderName'] ?? 'Dietitian';
        final Timestamp? timestamp = notificationData['timestamp'] as Timestamp?;

        // Determine if approved or declined based on title or message
        final bool isApproved = title.toLowerCase().contains('approved');
        final bool isDeclined = title.toLowerCase().contains('declined');

        String formattedDate = '';
        if (timestamp != null) {
          formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
        }

        // Extract plan type from message if available
        String planType = 'Subscription';
        final messageLower = message.toLowerCase();
        if (messageLower.contains('weekly')) {
          planType = 'Weekly Plan';
        } else if (messageLower.contains('monthly')) {
          planType = 'Monthly Plan';
        } else if (messageLower.contains('yearly')) {
          planType = 'Yearly Plan';
        }

        // Determine colors and icon based on status
        Color statusColor = isApproved ? Colors.green : (isDeclined ? Colors.red : _primaryColor);
        IconData statusIcon = isApproved
            ? Icons.check_circle_rounded
            : (isDeclined ? Icons.cancel_rounded : Icons.info_rounded);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timestamp
                        if (formattedDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Subscription Plan Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withOpacity(0.15),
                                statusColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.card_membership_rounded,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subscription Plan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontFamily: _primaryFontFamily,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      planType,
                                      style: TextStyle(
                                        fontFamily: _primaryFontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Dietitian Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: statusColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Dietitian: $senderName',
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Message/Status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: statusColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Additional Info based on status
                        if (isApproved)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.celebration_rounded, size: 18, color: Colors.green.shade700),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Your subscription is now active! You can now access all features.',
                                    style: TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 12,
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (isDeclined)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.help_outline_rounded, size: 18, color: Colors.orange.shade700),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Please contact your dietitian for more information or to resubmit your request.',
                                    style: TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 12,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Close Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceComparison(String label, String oldPrice, String newPrice) {
    final bool priceChanged = oldPrice != newPrice;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontFamily: _primaryFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₱$oldPrice',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: priceChanged ? Colors.grey.shade500 : Colors.grey.shade700,
                        decoration: priceChanged ? TextDecoration.lineThrough : null,
                        fontFamily: _primaryFontFamily,
                      ),
                    ),
                    if (priceChanged) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade400),
                      ),
                      Text(
                        '₱$newPrice',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontFamily: _primaryFontFamily,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToAppointment(BuildContext context, Map<String, dynamic> notificationData) async {
    print('=== APPOINTMENT NOTIFICATION DATA ===');
    notificationData.forEach((key, value) {
      print('$key: $value');
    });
    print('======================================');

    final String message = notificationData['message'] ?? '';
    DateTime? targetDate;

    try {
      final datePattern = RegExp(r'on\s+([A-Za-z]+\s+\d+,\s+\d{4})\s+at\s+(\d+:\d+\s+[AP]M)');
      final match = datePattern.firstMatch(message);

      if (match != null) {
        final dateStr = match.group(1);
        final timeStr = match.group(2);
        final fullDateStr = '$dateStr $timeStr';

        print('Extracted date string: $fullDateStr');
        targetDate = DateFormat('MMMM d, yyyy h:mm a').parse(fullDateStr);
        print('Parsed date: $targetDate');
      }
    } catch (e) {
      print('Error parsing date from message: $e');
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => home(initialIndex: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (targetDate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Showing appointments for ${DateFormat('MMM dd, yyyy').format(targetDate)}',
              style: const TextStyle(fontFamily: _primaryFontFamily),
            ),
            backgroundColor: _primaryColor,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Navigated to your appointments schedule',
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
            backgroundColor: _primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentScaffoldBg = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final Color currentAppBarBg = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color currentTabLabel = _textColorPrimary(context);
    final Color currentIndicator = _primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: currentScaffoldBg,
        appBar: AppBar(
          backgroundColor: currentAppBarBg,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: TabBar(
            labelColor: currentTabLabel,
            unselectedLabelColor: currentTabLabel.withOpacity(0.6),
            indicatorColor: currentIndicator,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontFamily: _primaryFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: _primaryFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              const Tab(text: "CHATS"),
              Tab(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Text("NOTIFICATIONS"),
                    Positioned(
                      top: 8,
                      right: -20,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(widget.currentUserId)
                            .collection('notifications')
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final unreadCount = snapshot.data!.docs.length;
                          return Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- CHATS TAB ---
            _isLoadingChats
                ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                : _sortedChats.isEmpty
                ? Center(
              child: Text(
                "Follow dietitians to chat with them.",
                style: _getTextStyle(
                  context,
                  fontSize: 16,
                  color: _textColorPrimary(context), height: 1.5,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              itemCount: _sortedChats.length,
              itemBuilder: (context, index) {
                final chat = _sortedChats[index];
                final userDoc = chat['userDoc'] as DocumentSnapshot;
                final data = userDoc.data() as Map<String, dynamic>;
                final lastMsg = chat['lastMessage'] as Map<String, dynamic>;

                final senderName =
                "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                    .trim();

                String subtitleText = "No messages yet";
                final lastMessage = lastMsg["message"] ?? "";
                final lastSenderName = lastMsg["senderName"] ?? "";
                final timeText = lastMsg["time"] ?? "";

                if (lastMessage.isNotEmpty) {
                  if (lastMsg["isMe"] ?? false) {
                    subtitleText = "You: $lastMessage";
                  } else {
                    subtitleText = "$lastSenderName: $lastMessage";
                  }
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagesPage(
                              currentUserId: widget.currentUserId,
                              receiverId: userDoc.id,
                              receiverName: senderName,
                              receiverProfile: data["profile"] ?? "",
                            ),
                          ),
                        ).then((_) {
                          _loadAndSortChats();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _cardBgColor(context),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _primaryColor.withOpacity(0.2),
                                  backgroundImage: (data["profile"] != null &&
                                      data["profile"].toString().isNotEmpty)
                                      ? NetworkImage(data["profile"])
                                      : null,
                                  child: (data["profile"] == null ||
                                      data["profile"].toString().isEmpty)
                                      ? Icon(Icons.person_outline,
                                      color: _primaryColor, size: 24)
                                      : null,
                                ),
                                if (data['status'] == 'online')
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _cardBgColor(context),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName,
                                    style: _getTextStyle(context,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600, height: 1.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _getTextStyle(context,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: _textColorSecondary(context), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            if (timeText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  timeText,
                                  style: _getTextStyle(context,
                                      fontSize: 12,
                                      color: _textColorSecondary(context), height: 1.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // --- NOTIFICATIONS TAB ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(widget.currentUserId)
                  .collection("notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: _primaryColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text("No notifications yet",
                            style: _getTextStyle(context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textColorPrimary(context), height: 1.5)),
                      ],
                    ),
                  );
                }

                // Group notifications (latest only per group)
                final Map<String, DocumentSnapshot> groupedNotifications = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String groupingKey;

                  if (data['type'] == 'message' && data['senderId'] != null) {
                    groupingKey = data['senderId'];
                  } else {
                    groupingKey = doc.id;
                  }

                  if (!groupedNotifications.containsKey(groupingKey)) {
                    groupedNotifications[groupingKey] = doc;
                  }
                }

                final finalDocsToShow = groupedNotifications.values.toList();

                // Filter by selected filter
                final filteredDocs = finalDocsToShow
                    .where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _shouldShowNotification(data);
                })
                    .toList();

                return Column(
                  children: [
                    // --- COMPACT HEADER WITH FILTER CHIPS AND CLEAR BUTTON ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Filter chips in a horizontal scrollable row
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCompactFilterChip('all'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('appointment'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('message'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('pricing'),
                                ],
                              ),
                            ),
                          ),
                          // Clear All button as icon button
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showClearAllDialog,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.redAccent.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- NOTIFICATIONS LIST ---
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: _primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No notifications",
                              style: _getTextStyle(
                                context,
                                fontSize: 16,
                                color: _textColorSecondary(context), height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: filteredDocs.length,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final Timestamp? timestamp =
                          data["timestamp"] as Timestamp?;
                          String formattedTime = "";

                          if (timestamp != null) {
                            final date = timestamp.toDate();
                            final now = DateTime.now();
                            if (date.year == now.year &&
                                date.month == now.month &&
                                date.day == now.day) {
                              formattedTime = DateFormat.jm().format(date);
                            } else if (date.year == now.year &&
                                date.month == now.month &&
                                date.day == now.day - 1) {
                              formattedTime = "Yesterday";
                            } else {
                              formattedTime = DateFormat('MMM d').format(date);
                            }
                          }

                          bool isRead = data["isRead"] == true;
                          final notificationType = _getNotificationType(data);
                          final iconBgColor = _getFilterChipColor(notificationType);
                          final notificationIcon = _getFilterChipIcon(notificationType);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: isRead
                                  ? null
                                  : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  iconBgColor.withOpacity(0.08),
                                  iconBgColor.withOpacity(0.03),
                                ],
                              ),
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: isRead ? 0.5 : 2,
                              color: _cardBgColor(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: isRead
                                    ? BorderSide(color: Colors.grey.shade300, width: 0.5)
                                    : BorderSide(
                                  color: iconBgColor.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  if (!isRead) {
                                    await FirebaseFirestore.instance
                                        .collection("Users")
                                        .doc(widget.currentUserId)
                                        .collection("notifications")
                                        .doc(doc.id)
                                        .update({"isRead": true});
                                  }

                                  if (data["type"] == "priceChange") {
                                    _showPriceChangeDialog(context, data);
                                  }else if (data["type"] == "subscription") {
                                    _showSubscriptionDialog(context, data);
                                  } else if (data["type"] == "meal_plan_scheduled") {
                                    _showMealPlanScheduledDialog(context, data);
                                  } else if(data["type"] == "meal_plan_declined"){
                                    _showMealPlanDeclinedDialog(context, data);
                                  } else if (data["type"] == "meal_plan_created"){
                                    _showMealPlanCreatedDialog(context, data);
                                  } else if (data["type"] == "meal_plan"){
                                    _showMealPlanNotif(context, data);
                                  } else if (data["type"] == "message" &&
                                      data["senderId"] != null &&
                                      data["senderName"] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MessagesPage(
                                          receiverId: data["senderId"],
                                          receiverName: data["senderName"],
                                          currentUserId: widget.currentUserId,
                                          receiverProfile:
                                          data["receiverProfile"] ?? "",
                                        ),
                                      ),
                                    ).then((_) {
                                      _loadAndSortChats();
                                    });
                                  } else if (data["type"] == "appointment" ||
                                      data["type"] == "appointment_update") {
                                    await _navigateToAppointment(context, data);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                          iconBgColor.withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                            color: iconBgColor
                                                .withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          notificationIcon,
                                          color: iconBgColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    data["title"] ??
                                                        "Notification",
                                                    style: _getTextStyle(
                                                      context,
                                                      fontSize: 15,
                                                      fontWeight: isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                      color:
                                                      _textColorPrimary(
                                                          context), height: 1.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                    const EdgeInsets.only(
                                                        left: 8.0),
                                                    decoration: BoxDecoration(
                                                      color: iconBgColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              data["message"] ?? "",
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                _textColorSecondary(context), height: 1.5,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (formattedTime.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                formattedTime,
                                                style: _getTextStyle(
                                                  context,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isRead
                                                      ? _textColorSecondary(
                                                      context)
                                                      : iconBgColor, height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}

