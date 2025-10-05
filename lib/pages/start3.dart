import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start4.dart';

class MealPlanningScreen3 extends StatefulWidget {
  final String userId;

  const MealPlanningScreen3({super.key, required this.userId});

  @override
  State<MealPlanningScreen3> createState() => _MealPlanningScreen3State();
}

class _MealPlanningScreen3State extends State<MealPlanningScreen3> {
  final _formKey = GlobalKey<FormState>();

  // <CHANGE> Replaced age controller with birthday date
  DateTime? selectedBirthday;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? selectedGender;
  int? selectedHealthGoalIndex;
  int? selectedActivityLevelIndex;

  final List<Map<String, dynamic>> healthGoals = [
    {"icon": Icons.person_remove_outlined, "text": "Weight Loss"},
    {"icon": Icons.person_add_alt_1_outlined, "text": "Weight Gain"},
    {"icon": Icons.health_and_safety_outlined, "text": "Health Recovery"},
    {"icon": Icons.monitor_weight_outlined, "text": "Maintain Weight"},
    {"icon": Icons.fitness_center, "text": "Workout"},
  ];

  // <CHANGE> Added descriptions for each activity level
  final List<Map<String, dynamic>> activityLevels = [
    {
      "icon": Icons.directions_walk,
      "text": "Lightly Active",
      "description": "Minimal exercise, desk job, light walking or household chores"
    },
    {
      "icon": Icons.directions_run,
      "text": "Moderately Active",
      "description": "Exercise 3-5 days/week, regular physical activities like jogging or cycling"
    },
    {
      "icon": Icons.pool,
      "text": "Very Active",
      "description": "Exercise 6-7 days/week, sports training, or physically demanding job"
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

  // <CHANGE> Added function to calculate age from birthday
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: _textColorOnPrimary),
              const SizedBox(width: 12),
              const Expanded(child: Text("Please correct the errors in the form")),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // <CHANGE> Validate birthday selection
    if (selectedBirthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: _textColorOnPrimary),
              const SizedBox(width: 12),
              const Expanded(child: Text("Please select your birthday")),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: _textColorOnPrimary),
              const SizedBox(width: 12),
              const Expanded(child: Text("Please select your gender")),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (selectedHealthGoalIndex == null || selectedActivityLevelIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: _textColorOnPrimary),
              const SizedBox(width: 12),
              const Expanded(child: Text("Please make all selections")),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // <CHANGE> Calculate age from birthday
    final int age = _calculateAge(selectedBirthday!);
    final String weight = _weightController.text.trim();
    final String height = _heightController.text.trim();
    final String healthGoal = healthGoals[selectedHealthGoalIndex!]["text"];
    final String activityLevel =
    activityLevels[selectedActivityLevelIndex!]["text"];

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userId)
          .set({
        "age": age,
        "gender": selectedGender,
        "currentWeight": double.tryParse(weight) ?? 0.0,
        "height": double.tryParse(height) ?? 0.0,
        "goals": healthGoal,
        "activityLevel": activityLevel,
        "tutorialStep": 3,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: _textColorOnPrimary),
                const SizedBox(width: 12),
                Expanded(child: Text("Error saving data: $e")),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // <CHANGE> New birthday picker widget
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
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedBirthday ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _primaryColor,
                      onPrimary: _textColorOnPrimary,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                selectedBirthday = picked;
              });
            }
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
                        ? "${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year} (Age: ${_calculateAge(selectedBirthday!)})"
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isNumeric = false,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: _getTextStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColorSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: _getTextStyle(context, fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _getTextStyle(
              context,
              fontSize: 14,
              color: _textColorSecondary(context),
            ),
            filled: true,
            fillColor: _scaffoldBgColor(context),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _primaryColor, size: 20)
                : null,
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
              borderSide: const BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            isDense: true,
          ),
          validator: validator ??
                  (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $labelText';
                }
                if (isNumeric && double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
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

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
    String? subtitle,
  }) {
    return Card(
      elevation: 4,
      shadowColor: _primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: _cardBgColor(context),
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
                      color: isItemSelected ? _primaryColor : Colors.grey.shade600,
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
                      const Icon(Icons.check_circle, color: _primaryColor, size: 20),
                  ],
                ),
                // <CHANGE> Added description text for activity levels
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
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                    Icons.person_outline,
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

                // Personal Information Section
                _buildSectionContainer(
                  title: 'Personal Information',
                  children: [
                    // <CHANGE> Replaced age input with birthday picker
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
                                keyboardType: TextInputType.number,
                                style: _getTextStyle(context, fontSize: 16),
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
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                    const BorderSide(color: Colors.redAccent),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.redAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  isDense: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null ||
                                      double.parse(value) <= 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
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
                                keyboardType: TextInputType.number,
                                style: _getTextStyle(context, fontSize: 16),
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
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                    const BorderSide(color: Colors.redAccent),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.redAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  isDense: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null ||
                                      double.parse(value) <= 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Health Goals Section
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

                // Activity Level Section
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

                // Next Button
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      elevation: 4,
                      shadowColor: _primaryColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}
