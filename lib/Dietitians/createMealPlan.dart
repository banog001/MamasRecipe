import 'package:flutter/material.dart';
import 'mealEntry.dart'; // Ensure this and MealPlanPreviewPage are correctly defined and imported
import 'mealPlanPreview.dart';

// --- Style Definitions (Add these or import from a shared style file) ---
const String _primaryFontFamily = 'PlusJakartaSans'; // Or your chosen font
const Color _primaryColor = Color(0xFF4CAF50);    // Your theme green
const Color _accentColor = Color(0xFF66BB6A);     // Lighter green for accents
const Color _textColorOnPrimary = Colors.white;
const Color _destructiveColor = Colors.redAccent; // For delete buttons
const Color _neutralButtonColor = Colors.blueGrey; // For cancel or less prominent actions

// Helper for general text
TextStyle _getTextStyle(BuildContext context, {
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
  String fontFamily = _primaryFontFamily,
  double? letterSpacing,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  // Fallback to sensible defaults based on theme brightness if color isn't provided
  final Color defaultTextColor = color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
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

  Future<void> _pickTime(String mealKey) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: mealTimes[mealKey]!,
      builder: (context, child) { // Optional: Theme the picker
        return Theme(
          data: ThemeData.light().copyWith( // Or ThemeData.dark()
            colorScheme: const ColorScheme.light(primary: _primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
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
    IconData? prefixIcon, // Optional prefix icon
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDarkMode ? Colors.grey[700]!.withOpacity(0.5) : Colors.grey[200];
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey[500];
    final inputTextColor = _getTextColorPrimary(context);
    final focusedBorderColor = _accentColor;

    return TextFormField(
      controller: controller,
      style: _getTextStyle(context, color: inputTextColor, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: _getTextStyle(context, color: hintColor, fontSize: 14, letterSpacing: 0.2),
        prefixIcon: prefixIcon != null
            ? Padding(
          padding: const EdgeInsets.only(left: 14.0, right: 10.0),
          child: Icon(prefixIcon, color: _primaryColor.withOpacity(0.7), size: 20),
        )
            : null,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: focusedBorderColor, width: 2)),
      ),
    );
  }


  Widget buildMealRow(String mealName, String key) {
    final time = mealTimes[key]!;
    final formattedTime = time.format(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card( // Wrap each meal row in a Card for better visual structure
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _getCardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealName,
              style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColorPrimary(context)),
            ),
            const SizedBox(height: 12),

            // Dynamic textboxes using the new styled text field
            Column(
              children: List.generate(mealControllers[key]!.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: _buildStyledTextField( // Using the styled text field
                    controller: mealControllers[key]![index],
                    hintText: "Enter meal details for item ${index + 1}",
                    // prefixIcon: Icons.restaurant_menu_outlined, // Example icon
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Buttons row
            Wrap(
              spacing: 12, // Increased spacing
              runSpacing: 10, // Increased run spacing
              alignment: WrapAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded, color: _primaryColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Set Time:",
                      style: _getTextStyle(context, fontSize: 14, color: _getTextColorSecondary(context)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: _getTextStyle(context, fontSize: 15, fontWeight: FontWeight.bold, color: _primaryColor),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickTime(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: _textColorOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: _getTextStyle(context, fontSize: 13, fontWeight: FontWeight.w500, color: _textColorOnPrimary),
                  ),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text("Edit Time"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        mealControllers[key]!.add(TextEditingController());
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor, // Changed color
                    foregroundColor: _textColorOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: _getTextStyle(context, fontSize: 13, fontWeight: FontWeight.w500, color: _textColorOnPrimary),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text("Add Item"),
                ),
                if (mealControllers[key]!.length > 1) // Only show delete if more than one item
                  ElevatedButton.icon(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          if (mealControllers[key]!.length > 1) {
                            // Also dispose the controller being removed
                            mealControllers[key]!.removeLast().dispose();
                          }
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _destructiveColor,
                      foregroundColor: _textColorOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: _getTextStyle(context, fontSize: 13, fontWeight: FontWeight.w500, color: _textColorOnPrimary),
                    ),
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                    label: const Text("Delete Last"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getScaffoldBgColor(context), // Themed background
      appBar: AppBar(
        leading: BackButton(color: isDarkMode ? _textColorOnPrimary : _primaryColor), // Themed back button
        backgroundColor: isDarkMode ? _primaryColor.withGreen(100) : Colors.white, // Themed AppBar background
        foregroundColor: isDarkMode ? _textColorOnPrimary : _primaryColor, // For title and actions
        title: Text(
          "Create New Meal Plan",
          style: _getTextStyle(context, fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? _textColorOnPrimary : _primaryColor),
        ),
        centerTitle: true,
        elevation: 1.0, // Subtle elevation
      ),
      body: SingleChildScrollView( // Changed to SingleChildScrollView for potentially long forms
        padding: const EdgeInsets.all(16.0),
        child: Column( // Main content in a Column
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown for meal plan type
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0), // Added bottom padding
              child: DropdownButtonFormField<String>(
                value: selectedPlanType,
                items: const [
                  DropdownMenuItem(value: "Weight Loss", child: Text("Weight Loss Program")),
                  DropdownMenuItem(value: "Weight Gain", child: Text("Weight Gain Program")),
                  DropdownMenuItem(value: "Maintain Weight", child: Text("Maintain Weight")),
                  DropdownMenuItem(value: "Work Out", child: Text("Fitness & Workout Plan")),
                ],
                onChanged: (value) {
                  if (value != null && mounted) {
                    setState(() {
                      selectedPlanType = value;
                    });
                  }
                },
                style: _getTextStyle(context, fontSize: 16, color: _getTextColorPrimary(context)),
                decoration: InputDecoration(
                    labelText: "Select Meal Plan Type",
                    labelStyle: _getTextStyle(context, fontSize: 14, color: _primaryColor),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700]?.withOpacity(0.5) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accentColor, width: 2),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14.0, right:10.0),
                      child: Icon(Icons.category_outlined, color: _primaryColor, size: 20),
                    )
                ),
                dropdownColor: _getCardBgColor(context),
              ),
            ),
            // const SizedBox(height: 10), // Reduced space as Card will add margin

            buildMealRow("Breakfast", "Breakfast"),
            buildMealRow("AM Snack", "AM Snack"),
            buildMealRow("Lunch", "Lunch"),
            buildMealRow("PM Snack", "PM Snack"),
            buildMealRow("Dinner", "Dinner"),
            buildMealRow("Midnight Snack", "Midnight Snack"),

            const SizedBox(height: 30), // Increased spacing before action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _neutralButtonColor, // Themed
                      foregroundColor: _textColorOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _textColorOnPrimary),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16), // Increased spacing
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      List<MealEntry> meals = [];
                      mealControllers.forEach((key, controllers) {
                        meals.add(MealEntry(
                          name: key,
                          items: controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
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
                      backgroundColor: _primaryColor, // Themed
                      foregroundColor: _textColorOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _textColorOnPrimary),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    label: const Text("Next"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Padding at the bottom
          ],
        ),
      ),
    );
  }
}
