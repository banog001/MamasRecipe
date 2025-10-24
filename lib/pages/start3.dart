import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start4.dart';
import 'package:mamas_recipe/widget/custom_snackbar.dart';
import 'package:intl/intl.dart';

// --- Theme Helpers ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white;

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
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle,
      double? height,
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
    height: height,
  );
}

Widget _buildBackgroundShapes(BuildContext context) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: _scaffoldBgColor(context),
    child: Stack(
      children: [
        Positioned(
          top: -100,
          left: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          right: -180,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

class MealPlanningScreen3 extends StatefulWidget {
  final String userId;

  const MealPlanningScreen3({super.key, required this.userId});

  @override
  State<MealPlanningScreen3> createState() => _MealPlanningScreen3State();
}

class CustomBirthdayPicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const CustomBirthdayPicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CustomBirthdayPicker> createState() => _CustomBirthdayPickerState();
}

class _CustomBirthdayPickerState extends State<CustomBirthdayPicker> {
  static const Color _primaryColor = Color(0xFF4CAF50);
  static const Color _textColorOnPrimary = Colors.white;
  static const String _primaryFontFamily = 'PlusJakartaSans';

  late DateTime _selectedDate;
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedYear = _selectedDate.year;
    _selectedMonth = _selectedDate.month;
    _selectedDay = _selectedDate.day;
  }

  void _updateDate() {
    _selectedDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
  }

  int _getDaysInMonth(int month, int year) {
    if (month == DateTime.february) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final secondaryText = isDark ? Colors.white54 : Colors.black54;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Your Birthday',
              style: TextStyle(
                fontFamily: _primaryFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
              style: TextStyle(
                fontFamily: _primaryFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            color: textColor,
                          ),
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  DateFormat('MMMM').format(DateTime(2000, index + 1)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMonth = value;
                                final maxDay = _getDaysInMonth(_selectedMonth, _selectedYear);
                                if (_selectedDay > maxDay) {
                                  _selectedDay = maxDay;
                                }
                                _updateDate();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedDay,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            color: textColor,
                          ),
                          items: List.generate(
                            _getDaysInMonth(_selectedMonth, _selectedYear),
                                (index) => DropdownMenuItem(
                              value: index + 1,
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${index + 1}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDay = value;
                                _updateDate();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            color: textColor,
                          ),
                          items: List.generate(
                            DateTime.now().year - 1900 + 1,
                                (index) {
                              final year = 1900 + index;
                              return DropdownMenuItem(
                                value: year,
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '$year',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ).toList()
                            ..sort((a, b) => (b.value as int).compareTo(a.value as int)),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedYear = value;
                                final maxDay = _getDaysInMonth(_selectedMonth, _selectedYear);
                                if (_selectedDay > maxDay) {
                                  _selectedDay = maxDay;
                                }
                                _updateDate();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      widget.onDateSelected(_selectedDate);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'SELECT',
                      style: TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontSize: 14,
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
      ),
    );
  }
}

class _MealPlanningScreen3State extends State<MealPlanningScreen3> {
  final _personalInfoKey = GlobalKey();
  final _healthGoalKey = GlobalKey();
  final _activityLevelKey = GlobalKey();

  DateTime? selectedBirthday;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();

  String? selectedGender;
  int? selectedHealthGoalIndex;
  int? selectedActivityLevelIndex;

  // --- NEW: BMI and category tracking ---
  double? currentBMI;
  String? bmiCategory;
  List<String>? suggestedHealthGoals;

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor =
        color ?? (isDarkMode ? Colors.white70 : Colors.black87);
    return TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: defaultTextColor,
    );
  }

  // --- NEW: Validate realistic height and weight ---
  Map<String, dynamic> _validateHeightWeight(double weight, double height) {
    // Height validation (50-250 cm)
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

    // Weight validation (30-500 kg - realistic human range)
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

    // BMI validation (realistic BMI range: 10-60)
    double bmi = _calculateBMI(weight, height);
    if (bmi < 10) {
      return {
        'isValid': false,
        'message': 'Weight seems too low for this height (BMI: ${bmi.toStringAsFixed(1)})',
        'type': 'combination'
      };
    }
    if (bmi > 60) {
      return {
        'isValid': false,
        'message': 'Weight seems too high for this height (BMI: ${bmi.toStringAsFixed(1)})',
        'type': 'combination'
      };
    }

    // Additional realistic validation: Check height-weight proportions
    // Using Devine formula as reference
    double idealWeightMin = _calculateIdealWeightMin(height);
    double idealWeightMax = _calculateIdealWeightMax(height);

    if (weight < (idealWeightMin * 0.5)) {
      return {
        'isValid': false,
        'message': 'Weight is unrealistically low for this height',
        'type': 'proportion'
      };
    }
    if (weight > (idealWeightMax * 2)) {
      return {
        'isValid': false,
        'message': 'Weight is unrealistically high for this height',
        'type': 'proportion'
      };
    }

    return {
      'isValid': true,
      'message': 'Valid',
      'type': 'valid'
    };
  }

  // --- Helper: Calculate ideal weight minimum using Devine formula ---
  double _calculateIdealWeightMin(double heightCm) {
    // Devine formula: 50 kg + 2.3 kg per inch over 5 feet
    // For metric: 50 + 2.3 * ((height - 152.4) / 2.54)
    if (heightCm < 150) return 40;
    return 50 + (2.3 * ((heightCm - 152.4) / 2.54)) * 0.85;
  }

  // --- Helper: Calculate ideal weight maximum ---
  double _calculateIdealWeightMax(double heightCm) {
    if (heightCm < 150) return 50;
    return 50 + (2.3 * ((heightCm - 152.4) / 2.54)) * 1.15;
  }

  // --- NEW: Calculate BMI ---
  double _calculateBMI(double weightKg, double heightCm) {
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // --- NEW: Get BMI Category and color ---
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

  // --- NEW: Auto-compute BMI on input change with validation ---
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

    // Validate realistic height and weight
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

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
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

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveUserData() async {
    final weightText = _weightController.text.trim();
    final heightText = _heightController.text.trim();
    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);

    if (selectedBirthday == null) {
      _showErrorSnackBar("Please select your birthday");
      _scrollToKey(_personalInfoKey);
      return;
    }

    if (selectedGender == null) {
      _showErrorSnackBar("Please select your gender");
      _scrollToKey(_personalInfoKey);
      return;
    }

    if (weightText.isEmpty) {
      _showErrorSnackBar("Please enter your weight");
      _scrollToKey(_personalInfoKey);
      _weightFocusNode.requestFocus();
      return;
    }
    if (weight == null || weight <= 0) {
      _showErrorSnackBar("Please enter a valid weight (must be a number)");
      _scrollToKey(_personalInfoKey);
      _weightFocusNode.requestFocus();
      return;
    }

    if (heightText.isEmpty) {
      _showErrorSnackBar("Please enter your height");
      _scrollToKey(_personalInfoKey);
      _heightFocusNode.requestFocus();
      return;
    }
    if (height == null || height <= 0) {
      _showErrorSnackBar("Please enter a valid height (must be a number)");
      _scrollToKey(_personalInfoKey);
      _heightFocusNode.requestFocus();
      return;
    }

    // Validate realistic height and weight
    final validation = _validateHeightWeight(weight, height);
    if (!validation['isValid']) {
      _showErrorSnackBar(validation['message']);
      _scrollToKey(_personalInfoKey);
      if (validation['type'] == 'weight') {
        _weightFocusNode.requestFocus();
      } else if (validation['type'] == 'height') {
        _heightFocusNode.requestFocus();
      }
      return;
    }

    if (selectedHealthGoalIndex == null) {
      _showErrorSnackBar("Please select a health goal");
      _scrollToKey(_healthGoalKey);
      return;
    }

    if (selectedActivityLevelIndex == null) {
      _showErrorSnackBar("Please select an activity level");
      _scrollToKey(_activityLevelKey);
      return;
    }

    final int age = _calculateAge(selectedBirthday!);
    final String healthGoal = healthGoals[selectedHealthGoalIndex!]["text"];
    final String activityLevel = activityLevels[selectedActivityLevelIndex!]["text"];
    final double bmi = _calculateBMI(weight, height);

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userId)
          .set({
        "age": age,
        "gender": selectedGender,
        "currentWeight": weight,
        "height": height,
        "bmi": bmi.toStringAsFixed(2),
        "bmiCategory": bmiCategory,
        "goals": healthGoal,
        "activityLevel": activityLevel,
        "tutorialStep": 3,
        "bmiUpdatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MealPlanningScreen4(userId: widget.userId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Error saving data: $e");
      }
    }
  }

  Widget _buildBirthdayPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Birthday",
          style: _getTextStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColorSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CustomBirthdayPicker(
                  initialDate: selectedBirthday ?? DateTime(2000, 1, 1),
                  onDateSelected: (DateTime date) {
                    setState(() {
                      selectedBirthday = date;
                    });
                  },
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _scaffoldBgColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedBirthday != null
                    ? _primaryColor
                    : Colors.grey.shade300,
                width: selectedBirthday != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  color: selectedBirthday != null
                      ? _primaryColor
                      : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    selectedBirthday != null
                        ? "${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year}"
                        : "Select your birthday",
                    style: _getTextStyle(
                      context,
                      fontSize: 15,
                      color: selectedBirthday != null
                          ? _textColorPrimary(context)
                          : _textColorSecondary(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: _textColorSecondary(context),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGenderSelection() {
    final genders = [
      {"value": "Male", "icon": Icons.male},
      {"value": "Female", "icon": Icons.female},
      {"value": "Other", "icon": Icons.transgender},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: _getTextStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColorSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: genders.map((gender) {
            final isSelected = selectedGender == gender["value"];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedGender = gender["value"] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor.withOpacity(0.1)
                        : _scaffoldBgColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        gender["icon"] as IconData,
                        color: isSelected ? _primaryColor : Colors.grey.shade600,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gender["value"] as String,
                        style: _getTextStyle(
                          context,
                          fontSize: 13,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? _primaryColor
                              : _textColorSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- NEW: Build validation indicator widget ---
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
            Icon(Icons.warning_rounded, color: Colors.red, size: 18),
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
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
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

  // --- NEW: Build BMI Display Widget ---
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.health_and_safety_rounded, color: categoryColor, size: 20),
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
              const SizedBox(height: 12),
              if (suggestedHealthGoals != null && suggestedHealthGoals!.isNotEmpty)
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      body: Stack(
        children: [
          _buildBackgroundShapes(context),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_pin_circle_outlined,
                      color: _textColorOnPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tell Us About Yourself',
                    textAlign: TextAlign.center,
                    style: _getTextStyle(
                      context,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textColorPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Step 3 of 4: Profile Details',
                    textAlign: TextAlign.center,
                    style: _getTextStyle(
                      context,
                      fontSize: 13,
                      color: _textColorSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionContainer(
                    key: _personalInfoKey,
                    title: 'Personal Information',
                    children: [
                      _buildBirthdayPicker(),
                      _buildGenderSelection(),
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
                                      borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: _primaryColor, width: 2),
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
                                      borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: _primaryColor, width: 2),
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
                    key: _healthGoalKey,
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
                    key: _activityLevelKey,
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

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _textColorOnPrimary,
                        elevation: 4,
                        shadowColor: _primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saveUserData,
                      child: Text(
                        'NEXT',
                        style: _getTextStyle(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColorOnPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}