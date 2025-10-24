import 'package:flutter/material.dart';
import 'mealEntry.dart'; // Ensure this and MealPlanPreviewPage are correctly defined and imported
import 'mealPlanPreview.dart';

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

class CreateMealPlanPage extends StatefulWidget {
  const CreateMealPlanPage({super.key});

  @override
  State<CreateMealPlanPage> createState() => _CreateMealPlanPageState();
}

class _CreateMealPlanPageState extends State<CreateMealPlanPage> {
  String selectedPlanType = "Weight Loss"; // Default value

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
    // Dispose all TextEditingControllers
    mealControllers.forEach((_, controllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    });
    super.dispose();
  }

  Future<void> _pickTime(String mealKey) async {
    // Get the current theme to check for dark mode
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showTimePicker(
      context: context,
      initialTime: mealTimes[mealKey]!,
      builder: (context, child) {
        // This theme now correctly handles both dark and light modes
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              // The main header background of the time picker
              primary: _primaryColor,
              // The text on the header (AM/PM, time)
              onPrimary: _textColorOnPrimary,
              // The background of the clock dial
              surface: isDark ? Colors.grey.shade800 : Colors.white,
              // The numbers on the clock dial
              onSurface: _getTextColorPrimary(context),
            ),
            // Style for the "OK" and "Cancel" buttons
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor, // Button text color
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

  // --- NEW: Re-styled Text Field ---
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: _getTextStyle(context, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
        _getTextStyle(context, color: _getTextColorSecondary(context)),
        filled: true,
        fillColor: _inputFillColor(context),
        prefixIcon: prefixIcon != null
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

  // --- NEW: Re-styled Time Picker Button ---
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

  // --- NEW: Refactored Meal Row Builder ---
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

          // --- This is your new styled Time Picker ---
          _buildTimePickerButton(context, key),
          const SizedBox(height: 12),

          // Dynamic textboxes
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

          // Buttons row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            children: [
              // Add Item Button
              ElevatedButton.icon(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      mealControllers[key]!.add(TextEditingController());
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _textColorOnPrimary,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: _getTextStyle(context,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textColorOnPrimary),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text("Add Item"),
              ),

              // Delete Last Button
              if (mealControllers[key]!.length > 1)
                ElevatedButton.icon(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        if (mealControllers[key]!.length > 1) {
                          mealControllers[key]!.removeLast().dispose();
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _destructiveColor,
                    foregroundColor: _textColorOnPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: _getTextStyle(context,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textColorOnPrimary),
                  ),
                  icon:
                  const Icon(Icons.remove_circle_outline_rounded, size: 18),
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
          "Create New Meal Plan",
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
            // --- NEW: Re-styled Dropdown ---
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
              child: DropdownButtonFormField<String>(
                value: selectedPlanType,
                items: const [
                  DropdownMenuItem(
                      value: "Weight Loss", child: Text("Weight Loss Program")),
                  DropdownMenuItem(
                      value: "Weight Gain", child: Text("Weight Gain Program")),
                  DropdownMenuItem(
                      value: "Maintain Weight",
                      child: Text("Maintain Weight")),
                  DropdownMenuItem(
                      value: "Work Out",
                      child: Text("Fitness & Workout Plan")),
                ],
                onChanged: (value) {
                  if (value != null && mounted) {
                    setState(() {
                      selectedPlanType = value;
                    });
                  }
                },
                style: _getTextStyle(context, fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Select Meal Plan Type",
                  labelStyle:
                  _getTextStyle(context, color: _primaryColor),
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
                    borderSide: const BorderSide(color: _primaryColor, width: 2),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14.0, right: 10.0),
                    child:
                    Icon(Icons.category_outlined, color: _primaryColor, size: 20),
                  ),
                ),
                dropdownColor: _getCardBgColor(context),
              ),
            ),

            buildMealRow("Breakfast", "Breakfast"),
            buildMealRow("AM Snack", "AM Snack"),
            buildMealRow("Lunch", "Lunch"),
            buildMealRow("PM Snack", "PM Snack"),
            buildMealRow("Dinner", "Dinner"),
            buildMealRow("Midnight Snack", "Midnight Snack"),

            const SizedBox(height: 30),
            Row(
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
                          color: _textColorOnPrimary),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      List<MealEntry> meals = [];
                      mealControllers.forEach((key, controllers) {
                        meals.add(MealEntry(
                          name: key,
                          items: controllers
                              .map((c) => c.text.trim())
                              .where((t) => t.isNotEmpty)
                              .toList(),
                          time: mealTimes[key]!,
                        ));
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealPlanPreviewPage(
                            planType: selectedPlanType,
                            meals: meals,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: _getTextStyle(context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColorOnPrimary),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    label: const Text("Next"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}