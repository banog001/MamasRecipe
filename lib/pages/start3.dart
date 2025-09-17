import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start4.dart'; // Assuming MealPlanningScreen4 is correctly imported

class MealPlanningScreen3 extends StatefulWidget {
  final String userId;

  const MealPlanningScreen3({super.key, required this.userId});

  @override
  State<MealPlanningScreen3> createState() => _MealPlanningScreen3State();
}

class _MealPlanningScreen3State extends State<MealPlanningScreen3> {
  final _formKey = GlobalKey<FormState>(); // For Form validation

  // Controllers for new fields
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  int? selectedHealthGoalIndex;
  int? selectedActivityLevelIndex;

  // --- Re-using your existing data structures and TextStyles ---
  final List<Map<String, dynamic>> healthGoals = [
    {"icon": Icons.person_remove_outlined, "text": "Weight Loss"},
    {"icon": Icons.person_add_alt_1_outlined, "text": "Weight Gain"},
    {"icon": Icons.health_and_safety_outlined, "text": "Health Recovery"},
    {"icon": Icons.monitor_weight_outlined, "text": "Maintain Weight"},
    {"icon": Icons.fitness_center, "text": "Workout"},
  ];

  final List<Map<String, dynamic>> activityLevels = [
    {"icon": Icons.directions_walk, "text": "Lightly Active"},
    {"icon": Icons.directions_run, "text": "Moderately Active"},
    {"icon": Icons.pool, "text": "Very Active"},
    {"icon": Icons.construction, "text": "Heavy Work"},
  ];

  static const String _primaryFontFamily = 'PlusJakartaSans';

  static const TextStyle _screenTitleStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 26, // Slightly larger for emphasis
      fontWeight: FontWeight.bold,
      color: Color(0xFF333333));

  static const TextStyle _stepTextStyle = TextStyle( // For "Step X of Y"
      fontFamily: _primaryFontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.grey
  );

  static const TextStyle _sectionTitleStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 22, // Bolder section titles
      fontWeight: FontWeight.bold,
      color: Color(0xFF4CAF50));

  static const TextStyle _labelTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 15, // Slightly larger label
      color: Colors.black54);

  static const TextStyle _textFieldStyle = TextStyle(
      fontFamily: _primaryFontFamily, fontSize: 16, color: Colors.black87);

  static const TextStyle _hintTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      color: Colors.grey,
      fontSize: 14,
      letterSpacing: 0.5);

  static const TextStyle _listItemTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500);

  static const TextStyle _buttonTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      fontSize: 18, // Slightly larger button text
      color: Colors.white);

  static const TextStyle _smallDebugTextStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.grey);
  // --- End Text Styles ---

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData() async {
    // Use Form key for validation
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please correct the errors in the form")),
      );
      return;
    }
    if (selectedHealthGoalIndex == null || selectedActivityLevelIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please make all selections")),
      );
      return;
    }

    // All good, proceed to save
    _formKey.currentState!.save(); // Ensure onSaved is called if used

    final String nickname = _nicknameController.text.trim();
    final String age = _ageController.text.trim();
    final String gender = _genderController.text.trim();
    final String weight = _weightController.text.trim();
    final String height = _heightController.text.trim();
    final String healthGoal = healthGoals[selectedHealthGoalIndex!]["text"];
    final String activityLevel =
    activityLevels[selectedActivityLevelIndex!]["text"];

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userId)
          .update({
        "nickname": nickname,
        "age": int.tryParse(age) ?? 0,
        "gender": gender,
        "currentWeight": double.tryParse(weight) ?? 0.0,
        "height": double.tryParse(height) ?? 0.0,
        "goals": healthGoal,
        "activityLevel": activityLevel,
        "tutorialStep": 3,
      });

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
          SnackBar(content: Text("Error saving data: $e")),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isNumeric = false,
    String? Function(String?)? validator,
    IconData? prefixIcon, // Optional prefix icon
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: _labelTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: _textFieldStyle,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _hintTextStyle,
            filled: true,
            fillColor: Colors.grey.shade50, // Even lighter fill for a softer look
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), // More rounded
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1), // Subtle border
            ),
            enabledBorder: OutlineInputBorder( // Border when not focused
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Adjusted padding
          ),
          validator: validator ?? (value) { // Default validator
            if (value == null || value.isEmpty) {
              return 'Please enter $labelText';
            }
            if (isNumeric && double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20), // Increased spacing
      ],
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children, String? sectionSubtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Could be Colors.grey.shade50 for very subtle difference
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle),
          if (sectionSubtitle != null) ...[
            const SizedBox(height: 4),
            Text(sectionSubtitle, style: _labelTextStyle.copyWith(fontSize: 14, color: Colors.grey[700])),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }


  Widget _buildSelectionList({
    // required String title, // Title will be part of _buildSectionContainer
    required List<Map<String, dynamic>> items,
    required int? selectedIndex,
    required ValueChanged<int?> onSelected,
    // String? subtitle,
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
          child: AnimatedContainer( // Added AnimatedContainer for smoother selection
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isItemSelected ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isItemSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade300,
                width: isItemSelected ? 2.0 : 1.5,
              ),
              boxShadow: isItemSelected ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : [],
            ),
            child: Row(
              children: [
                Icon(
                  item["icon"],
                  color: isItemSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade700,
                  size: 24, // Slightly larger icon
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item["text"],
                    style: _listItemTextStyle.copyWith(
                      color: isItemSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.black87,
                      fontWeight:
                      isItemSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isItemSelected) // Added a checkmark for selected item
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22),
              ],
            ),
          ),
        );
      },
    );
    // const SizedBox(height: 24) is removed, will be handled by section container
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Slightly off-white background for overall page
      body: SafeArea(
        child: Form( // Wrap content in a Form widget
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Tell Us About Yourself',
                  textAlign: TextAlign.center,
                  style: _screenTitleStyle,
                ),
                const SizedBox(height: 8),
                const Text( // Progress indicator
                  'Step 3 of 4: Profile Details',
                  textAlign: TextAlign.center,
                  style: _stepTextStyle,
                ),
                const SizedBox(height: 30),

                // --- Personal Information Section ---
                _buildSectionContainer(
                  title: 'Personal Information',
                  children: [
                    _buildTextField(
                        controller: _nicknameController,
                        labelText: 'Nickname',
                        hintText: 'E.g., Alex',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Nickname is required';
                          return null;
                        }),
                    _buildTextField(
                        controller: _ageController,
                        labelText: 'Age',
                        hintText: 'Enter your age',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.cake_outlined,
                        isNumeric: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Age is required';
                          if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Enter a valid age';
                          return null;
                        }),
                    _buildTextField(
                        controller: _genderController,
                        labelText: 'Gender',
                        prefixIcon: Icons.wc_outlined,
                        hintText: 'E.g., Male, Female, Other'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                              controller: _weightController,
                              labelText: 'Current Weight',
                              hintText: 'e.g., 70 kg',
                              prefixIcon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                              isNumeric: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Weight is required';
                                if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Enter a valid weight';
                                return null;
                              }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                              controller: _heightController,
                              labelText: 'Height',
                              hintText: 'e.g., 175 cm',
                              prefixIcon: Icons.height_outlined,
                              keyboardType: TextInputType.number,
                              isNumeric: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Height is required';
                                if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Enter a valid height';
                                return null;
                              }),
                        ),
                      ],
                    ),
                  ],
                ),


                // --- Health Goals Section ---
                _buildSectionContainer(
                    title: 'Health Goals',
                    children: [
                      _buildSelectionList(
                        items: healthGoals,
                        selectedIndex: selectedHealthGoalIndex,
                        onSelected: (index) {
                          setState(() => selectedHealthGoalIndex = index);
                        },
                      ),
                    ]
                ),


                // --- Activity and Lifestyle Section ---
                _buildSectionContainer(
                    title: 'Activity & Lifestyle',
                    sectionSubtitle: 'How would you describe your activity level?',
                    children: [
                      _buildSelectionList(
                        items: activityLevels,
                        selectedIndex: selectedActivityLevelIndex,
                        onSelected: (index) {
                          setState(() => selectedActivityLevelIndex = index);
                        },
                      ),
                    ]
                ),


                // --- NEXT Button ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0), // More vertical padding
                  child: SizedBox(
                    width: double.infinity,
                    height: 60, // Taller button
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // More rounded
                        ),
                        elevation: 3,
                      ),
                      onPressed: _saveUserData,
                      child: const Text('NEXT', style: _buttonTextStyle),
                    ),
                  ),
                ),

                if (widget.userId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      "UID: ${widget.userId}",
                      textAlign: TextAlign.center,
                      style: _smallDebugTextStyle,
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

