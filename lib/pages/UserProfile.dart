import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'editProfile.dart'; // Import is no longer used by the pen icon, but kept for other references
import 'package:mamas_recipe/widget/custom_snackbar.dart';
import 'package:intl/intl.dart';

const Color _primaryColor = Color(0xFF4CAF50);

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isFavoritesActive = true;
  bool _isEditing = false; // State to manage edit mode
  final _formKey = GlobalKey<FormState>();

  // Controllers and state for editing
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  int? selectedHealthGoalIndex;
  int? selectedActivityLevelIndex;
  double? currentBMI;
  String? bmiCategory;
  List<String>? suggestedHealthGoals;
  bool _isSaving = false;

  // Data from start3.dart
  final List<Map<String, dynamic>> healthGoals = [
    {"icon": Icons.person_remove_outlined, "text": "Weight Loss"},
    {"icon": Icons.person_add_alt_1_outlined, "text": "Weight Gain"},
    {"icon": Icons.monitor_weight_outlined, "text": "Maintain Weight"},
    {"icon": Icons.fitness_center, "text": "Workout"},
  ];

  final List<Map<String, dynamic>> activityLevels = [
    {
      "icon": Icons.directions_walk,
      "text": "Lightly Active",
      "description":
      "Minimal exercise, desk job, light walking or household chores"
    },
    {
      "icon": Icons.directions_run,
      "text": "Moderately Active",
      "description":
      "Exercise 3-5 days/week, regular physical activities like jogging or cycling"
    },
    {
      "icon": Icons.pool,
      "text": "Very Active",
      "description":
      "Exercise 6-7 days/week, sports training, or physically demanding job"
    },
    {
      "icon": Icons.construction,
      "text": "Heavy Work",
      "description": "Construction, farming, or intense physical labor daily"
    },
  ];

  // --- Theme constants ---
  static const String _primaryFontFamily = 'PlusJakartaSans';
  static const Color _primaryColor = Color(0xFF4CAF50);
  static const Color _textColorOnPrimary = Colors.white;

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

  TextStyle _getTextStyle(
      BuildContext context, {
        double fontSize = 16,
        FontWeight fontWeight = FontWeight.normal,
        Color? color,
      }) {
    return TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? _textColorPrimary(context),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    super.dispose();
  }

  // --- Initialize edit form data from user's current data ---
  void _initEditData(Map<String, dynamic> data) {
    _weightController.text = data['currentWeight']?.toString() ?? '';
    _heightController.text = data['height']?.toString() ?? '';

    final String currentGoal = data['goals'] ?? '';
    final int goalIndex =
    healthGoals.indexWhere((goal) => goal['text'] == currentGoal);
    selectedHealthGoalIndex = (goalIndex != -1) ? goalIndex : null;

    final String currentActivity = data['activityLevel'] ?? '';
    final int activityIndex = activityLevels
        .indexWhere((level) => level['text'] == currentActivity);
    selectedActivityLevelIndex = (activityIndex != -1) ? activityIndex : null;

    _updateBMI();
  }

  // --- Logic from start3.dart to save data ---
  Future<void> _saveHealthData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final weightText = _weightController.text.trim();
    final heightText = _heightController.text.trim();
    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);

    if (weightText.isEmpty) {
      _showErrorSnackBar("Please enter your weight");
      _weightFocusNode.requestFocus();
      setState(() => _isSaving = false);
      return;
    }
    if (weight == null || weight <= 0) {
      _showErrorSnackBar("Please enter a valid weight");
      _weightFocusNode.requestFocus();
      setState(() => _isSaving = false);
      return;
    }

    if (heightText.isEmpty) {
      _showErrorSnackBar("Please enter your height");
      _heightFocusNode.requestFocus();
      setState(() => _isSaving = false);
      return;
    }
    if (height == null || height <= 0) {
      _showErrorSnackBar("Please enter a valid height");
      _heightFocusNode.requestFocus();
      setState(() => _isSaving = false);
      return;
    }

    final validation = _validateHeightWeight(weight, height);
    if (!validation['isValid']) {
      _showErrorSnackBar(validation['message']);
      if (validation['type'] == 'weight') {
        _weightFocusNode.requestFocus();
      } else if (validation['type'] == 'height') {
        _heightFocusNode.requestFocus();
      }
      setState(() => _isSaving = false);
      return;
    }

    if (selectedHealthGoalIndex == null) {
      _showErrorSnackBar("Please select a health goal");
      setState(() => _isSaving = false);
      return;
    }

    if (selectedActivityLevelIndex == null) {
      _showErrorSnackBar("Please select an activity level");
      setState(() => _isSaving = false);
      return;
    }

    final String healthGoal = healthGoals[selectedHealthGoalIndex!]["text"];
    final String activityLevel =
    activityLevels[selectedActivityLevelIndex!]["text"];
    final double bmi = _calculateBMI(weight, height);
    final calculatedBmiCategory = _getBMICategory(bmi)['category'];

    try {
      await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
        "currentWeight": weight,
        "height": height,
        "bmi": bmi.toStringAsFixed(2),
        "bmiCategory": calculatedBmiCategory,
        "goals": healthGoal,
        "activityLevel": activityLevel,
        "bmiUpdatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Profile updated successfully!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Error saving data: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    CustomSnackBar.show(
      context,
      message,
      backgroundColor: Colors.redAccent,
      icon: Icons.error_outline,
    );
  }

  // --- LOGIC COPIED FROM start3.dart ---

  Map<String, dynamic> _validateHeightWeight(double weight, double height) {
    if (height < 50) {
      return {
        'isValid': false,
        'message': 'Height is too low (minimum: 50 cm)',
        'type': 'height'
      };
    }
    if (height > 250) {
      return {
        'isValid': false,
        'message': 'Height is too high (maximum: 250 cm)',
        'type': 'height'
      };
    }
    if (weight < 30) {
      return {
        'isValid': false,
        'message': 'Weight is too low (minimum: 30 kg)',
        'type': 'weight'
      };
    }
    if (weight > 500) {
      return {
        'isValid': false,
        'message': 'Weight is too high (maximum: 500 kg)',
        'type': 'weight'
      };
    }
    double bmi = _calculateBMI(weight, height);
    if (bmi < 10) {
      return {
        'isValid': false,
        'message':
        'Weight seems too low for this height (BMI: ${bmi.toStringAsFixed(1)})',
        'type': 'combination'
      };
    }
    if (bmi > 60) {
      return {
        'isValid': false,
        'message':
        'Weight seems too high for this height (BMI: ${bmi.toStringAsFixed(1)})',
        'type': 'combination'
      };
    }
    return {'isValid': true, 'message': 'Valid', 'type': 'valid'};
  }

  double _calculateBMI(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  Map<String, dynamic> _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return {
        'category': 'Underweight',
        'color': Colors.blue,
        'goals': ['Weight Gain']
      };
    } else if (bmi < 25) {
      return {
        'category': 'Normal Weight',
        'color': Colors.green,
        'goals': ['Maintain Weight', 'Workout']
      };
    } else if (bmi < 30) {
      return {
        'category': 'Overweight',
        'color': Colors.orange,
        'goals': ['Weight Loss', 'Workout']
      };
    } else {
      return {
        'category': 'Obese',
        'color': Colors.red,
        'goals': ['Weight Loss']
      };
    }
  }

  void _updateBMI() {
    final weightText = _weightController.text.trim();
    final heightText = _heightController.text.trim();

    if (weightText.isEmpty || heightText.isEmpty) {
      setState(() {
        currentBMI = null;
        bmiCategory = null;
        suggestedHealthGoals = null;
      });
      return;
    }

    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      setState(() {
        currentBMI = null;
        bmiCategory = null;
        suggestedHealthGoals = null;
      });
      return;
    }

    final validation = _validateHeightWeight(weight, height);
    if (!validation['isValid']) {
      setState(() {
        currentBMI = null;
        bmiCategory = null;
        suggestedHealthGoals = null;
      });
      return;
    }

    final bmi = _calculateBMI(weight, height);
    final categoryData = _getBMICategory(bmi);

    setState(() {
      currentBMI = bmi;
      bmiCategory = categoryData['category'];
      suggestedHealthGoals = List<String>.from(categoryData['goals']);
    });
  }

  // --- END OF LOGIC COPIED FROM start3.dart ---

  Widget _buildProfileBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shapeColor =
    isDark ? _primaryColor.withOpacity(0.08) : _primaryColor.withOpacity(0.05);

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 80,
            right: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: shapeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: shapeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final Map<String, Map<String, dynamic>> _mealDetails = {
    'Breakfast': {
      'icon': Icons.wb_sunny_outlined,
      'color': Colors.orange,
    },
    'AM Snack': {
      'icon': Icons.coffee_outlined,
      'color': Colors.brown,
    },
    'Lunch': {
      'icon': Icons.restaurant_outlined,
      'color': Colors.green,
    },
    'PM Snack': {
      'icon': Icons.local_cafe_outlined,
      'color': Colors.purple,
    },
    'Dinner': {
      'icon': Icons.nightlight_outlined,
      'color': Colors.indigo,
    },
    'Midnight Snack': {
      'icon': Icons.bedtime_outlined,
      'color': Colors.blueGrey,
    },
  };

  Widget _buildBMIStatusCard(Map<String, dynamic> data, BuildContext context) {
    final double weight =
        double.tryParse(data["currentWeight"].toString()) ?? 0.0;
    final double height = double.tryParse(data["height"].toString()) ?? 0.0;
    final double bmi = _calculateBMI(weight, height);
    final String? bmiCategory = data['bmiCategory'];
    final categoryData = _getBMICategory(bmi);
    final Color categoryColor = categoryData['color'];

    if (bmiCategory == null || bmi <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: categoryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "BMI Status",
                  style: _getTextStyle(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textColorSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bmiCategory,
                  style: _getTextStyle(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getBMIStatusIcon(bmiCategory),
            color: categoryColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Color _getBMICategoryColor(String? category) {
    if (category == null) return _primaryColor;

    switch (category.toLowerCase()) {
      case 'underweight':
        return Colors.blue;
      case 'normal weight':
        return Colors.green;
      case 'overweight':
        return Colors.orange;
      case 'obese':
        return Colors.red;
      default:
        return _primaryColor;
    }
  }

  IconData _getBMIStatusIcon(String? category) {
    if (category == null) return Icons.help_outline;

    switch (category.toLowerCase()) {
      case 'underweight':
        return Icons.trending_down;
      case 'normal weight':
        return Icons.check_circle_outline;
      case 'overweight':
        return Icons.trending_up;
      case 'obese':
        return Icons.warning_amber;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildBMIHistoryCard(Map<String, dynamic> data, BuildContext context) {
    final String? bmiValue = data['bmi'];
    final Timestamp? updatedAt = data['bmiUpdatedAt'] as Timestamp?;

    if (bmiValue == null) {
      return const SizedBox.shrink();
    }

    String formattedDate = 'Unknown';
    if (updatedAt != null) {
      final date = updatedAt.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        formattedDate = 'Today';
      } else if (difference.inDays == 1) {
        formattedDate = 'Yesterday';
      } else if (difference.inDays < 7) {
        formattedDate = '${difference.inDays} days ago';
      } else {
        formattedDate = DateFormat('MMM d, yyyy').format(date);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: _cardBgColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Last BMI Update",
                    style: _getTextStyle(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textColorSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: _getTextStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BMI: $bmiValue',
                  style: _getTextStyle(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .get();
    return snapshot.data();
  }

  Future<List<Map<String, dynamic>>> _getFavoriteMealPlans(String userId) async {
    try {
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
        final mealPlanDoc =
        await firestore.collection('mealPlans').doc(id).get();
        if (mealPlanDoc.exists) {
          final planData = mealPlanDoc.data()!;
          planData['planId'] = id;

          String ownerId = planData['owner'] ?? '';
          String ownerName = 'Unknown Chef';

          if (ownerId.isNotEmpty) {
            final userDoc =
            await firestore.collection('Users').doc(ownerId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              ownerName =
                  "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"
                      .trim();
              if (ownerName.isEmpty) ownerName = 'Unknown Chef';
            }
          }

          planData['ownerName'] = ownerName;
          mealPlans.add(planData);
        }
      }

      return mealPlans;
    } catch (e) {
      print('Error fetching favorite meal plans: $e');
      return [];
    }
  }

  Future<bool> _checkSubscriptionToDietitian(
      String userId, String dietitianId) async {
    if (dietitianId.isEmpty) return false;

    try {
      final firestore = FirebaseFirestore.instance;

      final subscriptionDoc = await firestore
          .collection('Users')
          .doc(userId)
          .collection('subscribeTo')
          .doc(dietitianId)
          .get();

      if (subscriptionDoc.exists) {
        final subData = subscriptionDoc.data() as Map<String, dynamic>;
        return subData['status'] == 'approved';
      }

      return false;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  Widget _buildMealItem(
      BuildContext context, {
        required String mealName,
        required String mealContent,
        required String mealTime,
        required IconData icon,
        required Color iconColor,
        bool isLocked = false,
      }) {
    if (mealContent.isEmpty && !isLocked) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mealName,
                style: _getTextStyle(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textColorSecondary(context),
                ),
              ),
              if (mealTime.isNotEmpty && !isLocked) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 11,
                      color: iconColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mealTime,
                      style: _getTextStyle(
                        context,
                        fontSize: 11,
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              if (isLocked)
                Row(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: _textColorSecondary(context)),
                    const SizedBox(width: 4),
                    Text(
                      "Subscribe to view",
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textColorSecondary(context),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  mealContent,
                  style: _getTextStyle(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritePlanCard(
      BuildContext context,
      Map<String, dynamic> plan,
      bool isSubscribed,
      ) {
    final String planType = plan['planType'] ?? 'N/A';
    final String ownerName = plan['ownerName'] ?? 'Unknown';
    final int likeCount = plan['likeCounts'] as int? ?? 0;

    final meals = {
      'Breakfast': {
        'content': plan['breakfast'],
        'time': plan['breakfastTime'],
        'isLocked': false,
      },
      'AM Snack': {
        'content': plan['amSnack'],
        'time': plan['amSnackTime'],
        'isLocked': !isSubscribed,
      },
      'Lunch': {
        'content': plan['lunch'],
        'time': plan['lunchTime'],
        'isLocked': !isSubscribed,
      },
      'PM Snack': {
        'content': plan['pmSnack'],
        'time': plan['pmSnackTime'],
        'isLocked': !isSubscribed,
      },
      'Dinner': {
        'content': plan['dinner'],
        'time': plan['dinnerTime'],
        'isLocked': !isSubscribed,
      },
      'Midnight Snack': {
        'content': plan['midnightSnack'],
        'time': plan['midnightSnackTime'],
        'isLocked': !isSubscribed,
      },
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: _cardBgColor(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
              color: _scaffoldBgColor(context).withOpacity(0.8), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'By: $ownerName',
                    style: _getTextStyle(
                      context,
                      fontSize: 12,
                      color: _textColorSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                        likeCount > 0
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color: Colors.red,
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      likeCount.toString(),
                      style: _getTextStyle(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              planType,
              style: _getTextStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (planType != 'N/A') ...[
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  planType,
                  style: _getTextStyle(
                    context,
                    fontSize: 11,
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Column(
              children: meals.entries.map((entry) {
                final mealName = entry.key;
                final mealData = entry.value;
                final details = _mealDetails[mealName];

                if (details == null) return const SizedBox.shrink();

                final String content = mealData['content']?.toString() ?? '';
                final String time = mealData['time']?.toString() ?? '';

                if (mealData['isLocked'] == true && content.isEmpty) {
                  return const SizedBox.shrink();
                }
                if (mealData['isLocked'] == false && content.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildMealItem(
                    context,
                    mealName: mealName,
                    mealContent: content,
                    mealTime: time,
                    icon: details['icon'],
                    iconColor: details['color'],
                    isLocked: mealData['isLocked'] as bool,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS COPIED FROM start3.dart FOR THE EDIT FORM ---

  Widget _buildValidationIndicator() {
    final weightText = _weightController.text.trim();
    final heightText = _heightController.text.trim();

    if (weightText.isEmpty || heightText.isEmpty) {
      return const SizedBox.shrink();
    }

    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Please enter valid numbers',
                style: _getTextStyle(
                  context,
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final validation = _validateHeightWeight(weight, height);

    if (!validation['isValid']) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                validation['message'] ?? 'Invalid input',
                style: _getTextStyle(
                  context,
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBMIDisplay() {
    if (currentBMI == null) {
      return _buildValidationIndicator();
    }

    final categoryData = _getBMICategory(currentBMI!);
    final categoryColor = categoryData['color'] as Color;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: categoryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your BMI",
                        style: _getTextStyle(
                          context,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textColorSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentBMI!.toStringAsFixed(1),
                        style: _getTextStyle(
                          context,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.health_and_safety_rounded,
                            color: categoryColor, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          bmiCategory ?? "Unknown",
                          style: _getTextStyle(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (suggestedHealthGoals != null &&
                  suggestedHealthGoals!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: categoryColor.withOpacity(0.2), height: 12),
                    const SizedBox(height: 8),
                    Text(
                      "Recommended Goals for Your BMI:",
                      style: _getTextStyle(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textColorSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestedHealthGoals!.map((goal) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            goal,
                            style: _getTextStyle(
                              context,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
        _buildValidationIndicator(),
      ],
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
    String? subtitle,
    Key? key,
  }) {
    return Card(
      key: key,
      elevation: 0, // Give sections a slight elevation in edit mode
      color: _cardBgColor(context),
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: _getTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: _getTextStyle(
                  context,
                  fontSize: 13,
                  color: _textColorSecondary(context),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionList({
    required List<Map<String, dynamic>> items,
    required int? selectedIndex,
    required ValueChanged<int?> onSelected,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isItemSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () => onSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: isItemSelected
                  ? _primaryColor.withOpacity(0.1)
                  : _scaffoldBgColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isItemSelected ? _primaryColor : Colors.grey.shade300,
                width: isItemSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item["icon"],
                      color:
                      isItemSelected ? _primaryColor : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item["text"],
                        style: _getTextStyle(
                          context,
                          fontSize: 15,
                          fontWeight:
                          isItemSelected ? FontWeight.bold : FontWeight.w500,
                          color: isItemSelected
                              ? _primaryColor
                              : _textColorPrimary(context),
                        ),
                      ),
                    ),
                    if (isItemSelected)
                      const Icon(Icons.check_circle,
                          color: _primaryColor, size: 20),
                  ],
                ),
                if (item["description"] != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      item["description"],
                      style: _getTextStyle(
                        context,
                        fontSize: 12,
                        color: _textColorSecondary(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- END OF WIDGETS COPIED FROM start3.dart ---

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        body: const Center(child: Text("No user logged in")),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _scaffoldBgColor(context),
            body: const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: _scaffoldBgColor(context),
            body: const Center(child: Text("No user data found")),
          );
        }

        final data = snapshot.data!;
        final double weight =
            double.tryParse(data["currentWeight"].toString()) ?? 0.0;
        final double height =
            double.tryParse(data["height"].toString()) ?? 0.0;
        final String displayName =
        "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim().isEmpty
            ? (user.displayName ?? "Unknown User")
            : "${data['firstName']} ${data['lastName']}";
        final String? profileUrl = data['profile'];

        return Scaffold(
          backgroundColor: _scaffoldBgColor(context),
          appBar: AppBar(
            title: Text(
              _isEditing ? "Edit Profile" : "My Profile",
              style: _getTextStyle(
                context,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColorOnPrimary,
              ),
            ),
            backgroundColor: _primaryColor,
            elevation: 1,
            iconTheme: const IconThemeData(color: _textColorOnPrimary),
          ),
          body: Stack(
            children: [
              _buildProfileBackground(context),
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                  Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      spreadRadius: 1,
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  backgroundImage: (profileUrl != null &&
                                      profileUrl.isNotEmpty)
                                      ? NetworkImage(profileUrl)
                                      : null,
                                  child:
                                  (profileUrl == null || profileUrl.isEmpty)
                                      ? const Icon(
                                    Icons.person_outline,
                                    size: 42,
                                    color: _primaryColor,
                                  )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 0,
                                  child: InkWell(
                                    // --- THIS IS THE MODIFIED ONTAP ---
                                    onTap: () {
                                      setState(() {
                                        _isEditing = !_isEditing;
                                        if (_isEditing) {
                                          _initEditData(data);
                                        }
                                      });
                                    },
                                    customBorder: const CircleBorder(),
                                    // --- MODIFIED ICON ---
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        _isEditing
                                            ? Icons.close
                                            : Icons.edit_outlined,
                                        size: 18,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            displayName,
                            style: _getTextStyle(
                              context,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textColorOnPrimary,
                            ),
                          ),
                          if (user.email != null && user.email!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.email!,
                              style: _getTextStyle(
                                context,
                                fontSize: 14,
                                color: _textColorOnPrimary.withOpacity(0.8),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),

                    // --- Content below header ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _isEditing
                      // --- IF EDITING: Show the form ---
                          ? _buildEditHealthForm(context)
                      // --- IF VIEWING: Show normal content ---
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Health Overview",
                            style: _getTextStyle(
                              context,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildViewHealthData(data, weight, height),
                        ],
                      ),
                    ),

                    // --- These widgets only show when NOT editing ---
                    if (!_isEditing) ...[
                      _buildBMIHistoryCard(data, context),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Meal Plans",
                              style: _getTextStyle(
                                context,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              elevation: 0,
                              color: _cardBgColor(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _isFavoritesActive
                                                  ? _primaryColor
                                                  : _cardBgColor(context),
                                              foregroundColor: _isFavoritesActive
                                                  ? _textColorOnPrimary
                                                  : _textColorPrimary(context),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(12),
                                                side: _isFavoritesActive
                                                    ? BorderSide.none
                                                    : BorderSide(
                                                    color: _primaryColor
                                                        .withOpacity(0.3)),
                                              ),
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 12),
                                              elevation:
                                              _isFavoritesActive ? 2 : 0,
                                            ),
                                            onPressed: () {
                                              if (!_isFavoritesActive) {
                                                setState(() {
                                                  _isFavoritesActive = true;
                                                });
                                              }
                                            },
                                            child: Text(
                                              "Favorites",
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _isFavoritesActive
                                                    ? _textColorOnPrimary
                                                    : _primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: !_isFavoritesActive
                                                  ? _primaryColor
                                                  : _cardBgColor(context),
                                              foregroundColor: !_isFavoritesActive
                                                  ? _textColorOnPrimary
                                                  : _textColorPrimary(context),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(12),
                                                side: !_isFavoritesActive
                                                    ? BorderSide.none
                                                    : BorderSide(
                                                    color: _primaryColor
                                                        .withOpacity(0.3)),
                                              ),
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 12),
                                              elevation:
                                              !_isFavoritesActive ? 2 : 0,
                                            ),
                                            onPressed: () {
                                              if (_isFavoritesActive) {
                                                setState(() {
                                                  _isFavoritesActive = false;
                                                });
                                              }
                                            },
                                            child: Text(
                                              "My Plans",
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: !_isFavoritesActive
                                                    ? _textColorOnPrimary
                                                    : _primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_isFavoritesActive)
                                      FutureBuilder<
                                          List<Map<String, dynamic>>>(
                                        future:
                                        _getFavoriteMealPlans(user.uid),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child:
                                                CircularProgressIndicator(
                                                    color: _primaryColor),
                                              ),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return Container(
                                              height: 120,
                                              alignment: Alignment.center,
                                              child: Text(
                                                "No favorite meal plans yet",
                                                style: _getTextStyle(
                                                  context,
                                                  fontSize: 14,
                                                  color: _textColorSecondary(
                                                      context),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          }

                                          final mealPlans = snapshot.data!;

                                          return Column(
                                            children: mealPlans.map((plan) {
                                              final dietitianId =
                                                  plan['owner'] ?? '';

                                              return FutureBuilder<bool>(
                                                future:
                                                _checkSubscriptionToDietitian(
                                                    user.uid, dietitianId),
                                                builder:
                                                    (context, subSnapshot) {
                                                  if (subSnapshot
                                                      .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return Container(
                                                      height: 150,
                                                      margin:
                                                      const EdgeInsets.only(
                                                          bottom: 16),
                                                      decoration:
                                                      BoxDecoration(
                                                        color: _cardBgColor(
                                                            context)
                                                            .withOpacity(0.5),
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(14),
                                                      ),
                                                    );
                                                  }

                                                  bool isSubscribed =
                                                      subSnapshot.data ?? false;

                                                  return _buildFavoritePlanCard(
                                                    context,
                                                    plan,
                                                    isSubscribed,
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          );
                                        },
                                      )
                                    else
                                      Container(
                                        height: 120,
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Your created meal plans will appear here",
                                          style: _getTextStyle(
                                            context,
                                            fontSize: 14,
                                            color: _textColorSecondary(context),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: BottomNavigationBar(
                backgroundColor: _primaryColor,
                selectedItemColor: Colors.white.withOpacity(0.6),
                unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                onTap: (index) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => home(initialIndex: index),
                    ),
                  );
                },
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
      },
    );
  }

  Widget _buildViewHealthData(
      Map<String, dynamic> data, double weight, double height) {
    return Card(
      elevation: 0,
      color: _cardBgColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoCard(
                  icon: Icons.monitor_weight_outlined,
                  label: "Weight",
                  value: "${weight.toStringAsFixed(1)} kg",
                  context: context,
                ),
                _InfoCard(
                  icon: Icons.height_outlined,
                  label: "Height",
                  value: "${height.toStringAsFixed(1)} cm",
                  context: context,
                ),
                _InfoCard(
                  icon: Icons.flag_outlined,
                  label: "Goal",
                  value: data['goals'] ?? 'N/A',
                  context: context,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBMIStatusCard(data, context),
          ],
        ),
      ),
    );
  }

  Widget _buildEditHealthForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildSectionContainer(
            title: 'Personal Information',
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weight (kg)",
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColorSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _weightController,
                          focusNode: _weightFocusNode,
                          keyboardType: TextInputType.number,
                          style: _getTextStyle(context, fontSize: 16),
                          onChanged: (_) => _updateBMI(),
                          decoration: InputDecoration(
                            hintText: 'e.g., 70',
                            hintStyle: _getTextStyle(
                              context,
                              fontSize: 14,
                              color: _textColorSecondary(context),
                            ),
                            filled: true,
                            fillColor: _scaffoldBgColor(context),
                            prefixIcon: const Icon(
                              Icons.monitor_weight_outlined,
                              color: _primaryColor,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: _primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Height (cm)",
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColorSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _heightController,
                          focusNode: _heightFocusNode,
                          keyboardType: TextInputType.number,
                          style: _getTextStyle(context, fontSize: 16),
                          onChanged: (_) => _updateBMI(),
                          decoration: InputDecoration(
                            hintText: 'e.g., 175',
                            hintStyle: _getTextStyle(
                              context,
                              fontSize: 14,
                              color: _textColorSecondary(context),
                            ),
                            filled: true,
                            fillColor: _scaffoldBgColor(context),
                            prefixIcon: const Icon(
                              Icons.height_outlined,
                              color: _primaryColor,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: _primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBMIDisplay(),
            ],
          ),
          _buildSectionContainer(
            title: 'Health Goals',
            subtitle: 'What would you like to achieve?',
            children: [
              _buildSelectionList(
                items: healthGoals,
                selectedIndex: selectedHealthGoalIndex,
                onSelected: (index) {
                  setState(() => selectedHealthGoalIndex = index);
                },
              ),
            ],
          ),
          _buildSectionContainer(
            title: 'Activity & Lifestyle',
            subtitle: 'How would you describe your activity level?',
            children: [
              _buildSelectionList(
                items: activityLevels,
                selectedIndex: selectedActivityLevelIndex,
                onSelected: (index) {
                  setState(() => selectedActivityLevelIndex = index);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => setState(() => _isEditing = false),
                  child: Text(
                    'CANCEL',
                    style: _getTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColorSecondary(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: _textColorOnPrimary,
                    elevation: 4,
                    shadowColor: _primaryColor.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveHealthData,
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    'SAVE',
                    style: _getTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColorOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BuildContext context;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.context,
  });

  Color _textColorPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : Colors.black87;

  Color _textColorSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white54
          : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textColorSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textColorPrimary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}