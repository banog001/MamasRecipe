import 'package:flutter/material.dart';
import 'mealEntry.dart';
import 'personalizedMealPlanPreview.dart';

// --- Style Definitions (Now fully theme-aware) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;
const Color _destructiveColor = Colors.redAccent;
const Color _neutralButtonColor = Colors.blueGrey;

Color _getScaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.grey.shade100;

Color _getCardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white;

Color _inputFillColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200;

Color _getTextColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

Color _getTextColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey.shade700;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
    }) {
  final defaultTextColor = color ?? _getTextColorPrimary(context);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
  );
}
// --- End Style Definitions ---

class CreatePersonalizedMealPlanPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> requestData;

  const CreatePersonalizedMealPlanPage({
    super.key,
    required this.userData,
    required this.requestData,
  });

  @override
  State<CreatePersonalizedMealPlanPage> createState() =>
      _CreatePersonalizedMealPlanPageState();
}

class _CreatePersonalizedMealPlanPageState
    extends State<CreatePersonalizedMealPlanPage> {
  final TextEditingController _descriptionController = TextEditingController();
  String get requestDocId => widget.requestData['requestDocId'] ?? '';

  final Map<String, List<TextEditingController>> mealControllers = {
    "Breakfast": [TextEditingController()],
    "AM Snack": [TextEditingController()],
    "Lunch": [TextEditingController()],
    "PM Snack": [TextEditingController()],
    "Dinner": [TextEditingController()],
    "Midnight Snack": [TextEditingController()],
  };

  final Map<String, TimeOfDay> mealTimes = {
    "Breakfast": const TimeOfDay(hour: 6, minute: 0),
    "AM Snack": const TimeOfDay(hour: 9, minute: 0),
    "Lunch": const TimeOfDay(hour: 12, minute: 0),
    "PM Snack": const TimeOfDay(hour: 15, minute: 0),
    "Dinner": const TimeOfDay(hour: 18, minute: 0),
    "Midnight Snack": const TimeOfDay(hour: 21, minute: 0),
  };

  @override
  void dispose() {
    mealControllers.forEach((_, controllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    });
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ FIXED: safer goal getter — checks both requestData & userData, case-insensitive
  String get _userGoal {
    final goal = (widget.requestData['goals'] ??
        widget.userData['goals'] ??
        'Maintain Weight')
        .toString()
        .trim()
        .toLowerCase();

    if (goal.contains('loss')) return 'Weight Loss';
    if (goal.contains('gain')) return 'Weight Gain';
    if (goal.contains('work')) return 'Work Out';
    if (goal.contains('maintain')) return 'Maintain Weight';
    return 'Maintain Weight';
  }

  String get _userName =>
      widget.userData['name'] ??
          widget.userData['username'] ??
          'User';

  double? get _userWeight => widget.userData['weight']?.toDouble();
  double? get _userHeight => widget.userData['height']?.toDouble();
  int? get _userAge => widget.userData['age'];
  String? get _userGender => widget.userData['gender'];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  String get clientName =>
      widget.userData['firstName'] != null &&
          widget.userData['lastName'] != null
          ? '${widget.userData['firstName']} ${widget.userData['lastName']}'
          : _userName;

  String _getPlanTypeDisplay() {
    switch (_userGoal) {
      case "Weight Loss":
        return "Weight Loss Program";
      case "Weight Gain":
        return "Weight Gain Program";
      case "Maintain Weight":
        return "Maintain Weight Program";
      case "Work Out":
        return "Fitness & Workout Plan";
      default:
        return _userGoal;
    }
  }

  IconData _getGoalIcon() {
    switch (_userGoal) {
      case "Weight Loss":
        return Icons.trending_down;
      case "Weight Gain":
        return Icons.trending_up;
      case "Maintain Weight":
        return Icons.balance;
      case "Work Out":
        return Icons.fitness_center;
      default:
        return Icons.restaurant_menu;
    }
  }

  Future<void> _pickTime(String mealKey) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showTimePicker(
      context: context,
      initialTime: mealTimes[mealKey]!,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _primaryColor,
              onPrimary: _textColorOnPrimary,
              surface: isDark ? Colors.grey.shade800 : Colors.white,
              onSurface: _getTextColorPrimary(context),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                textStyle: const TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        mealTimes[mealKey] = picked;
      });
    }
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      style: _getTextStyle(context, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
        _getTextStyle(context, color: _getTextColorSecondary(context)),
        filled: true,
        fillColor: _inputFillColor(context),
        prefixIcon: prefixIcon != null && maxLines == null
            ? Icon(prefixIcon, color: _primaryColor.withOpacity(0.7), size: 20)
            : null,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildTimePickerButton(BuildContext context, String mealKey) {
    final time = mealTimes[mealKey]!;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: InkWell(
        onTap: () => _pickTime(mealKey),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _inputFillColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meal Time: ${time.format(context)}',
                style: _getTextStyle(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getTextColorPrimary(context),
                ),
              ),
              const Icon(Icons.edit_calendar_outlined, color: _primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getCardBgColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.userData['profile'] != null &&
                  widget.userData['profile'] != ''
                  ? CircleAvatar(
                backgroundImage: NetworkImage(widget.userData['profile']),
                radius: 20,
              )
                  : const Icon(
                Icons.person,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creating meal plan for:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clientName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          const SizedBox(height: 12),
          _buildClientInfoRow(
              'Goal', _userGoal, Icons.flag), // ✅ shows correct goal now
          _buildClientInfoRow(
              'Age', '${widget.userData['age']} years', Icons.cake),
          _buildClientInfoRow(
              'Height', '${widget.userData['height']} cm', Icons.height),
          _buildClientInfoRow('Weight',
              '${widget.userData['currentWeight']} kg', Icons.monitor_weight),
          _buildClientInfoRow('Activity',
              widget.userData['activityLevel'] ?? 'N/A', Icons.directions_run),
        ],
      ),
    );
  }

  Widget buildMealRow(String mealName, String key) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getCardBgColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealName,
            style: _getTextStyle(context,
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTimePickerButton(context, key),
          const SizedBox(height: 12),
          Column(
            children: List.generate(mealControllers[key]!.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: _buildStyledTextField(
                  controller: mealControllers[key]![index],
                  hintText: "Enter item ${index + 1}",
                  prefixIcon: Icons.restaurant_menu_outlined,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    mealControllers[key]!.add(TextEditingController());
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _textColorOnPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text("Add Item"),
              ),
              if (mealControllers[key]!.length > 1)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      mealControllers[key]!.removeLast().dispose();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _destructiveColor,
                    foregroundColor: _textColorOnPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      size: 18),
                  label: const Text("Delete Last"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBgColor(context),
      appBar: AppBar(
        backgroundColor: _getCardBgColor(context),
        foregroundColor: _getTextColorPrimary(context),
        title: Text(
          "Create Meal Plan",
          style: _getTextStyle(context,
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserInfoCard(),

            // ✅ Meal Plan Type
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _getCardBgColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: _primaryColor.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(_getGoalIcon(), color: _primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meal Plan Type',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPlanTypeDisplay(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                              isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Plan Description",
                        style: _getTextStyle(context,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _descriptionController,
                        builder: (context, value, child) {
                          return Text(
                            "${value.text.length}/300",
                            style: _getTextStyle(
                              context,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: value.text.length > 270
                                  ? Colors.orange
                                  : _getTextColorSecondary(context),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 300,
                    buildCounter: (context,
                        {required currentLength,
                          required isFocused,
                          maxLength}) =>
                    const SizedBox.shrink(),
                    style: _getTextStyle(context, fontSize: 15),
                    decoration: InputDecoration(
                      hintText:
                      "Describe your meal plan (max 300 characters)...",
                      hintStyle: _getTextStyle(context,
                          color: _getTextColorSecondary(context)),
                      filled: true,
                      fillColor: _inputFillColor(context),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Meals
            ...mealControllers.keys.map((key) {
              return buildMealRow(key, key);
            }).toList(),

            const SizedBox(height: 40),

            // ✅ Continue Button
            ElevatedButton.icon(
              onPressed: () {
                // Gather all the meals into a list of MealEntry objects
                final List<MealEntry> mealEntries = mealControllers.entries.map((entry) {
                  final mealName = entry.key;
                  final controllers = entry.value;
                  final time = mealTimes[mealName] ?? const TimeOfDay(hour: 7, minute: 0);
                  final items = controllers
                      .map((controller) => controller.text.trim())
                      .where((text) => text.isNotEmpty)
                      .toList();

                  return MealEntry(name: mealName, items: items, time: time);
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonalizedMealPlanPreview(
                      planType: _getPlanTypeDisplay(),
                      meals: mealEntries,
                      description: _descriptionController.text.trim(),
                      userData: widget.userData,
                      requestData: {
                        ...widget.requestData,
                        'requestId': requestDocId, // ✅ Ensure requestId is passed
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _textColorOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              label: const Text(
                "Preview Meal Plan",
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),


            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
