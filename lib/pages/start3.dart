import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start4.dart';

// --- Theme Helpers ---
const String _primaryFontFamily = 'PlusJakartaSans';

const Color _primaryColor = Color(0xFF4CAF50);
Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white;
Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;
Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;
Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;
const Color _textColorOnPrimary = Colors.white;

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
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    height: height,
  );
}
// --- End Theme Helpers ---

class MealPlanningScreen3 extends StatefulWidget {
  final String userId;
  const MealPlanningScreen3({super.key, required this.userId});

  @override
  State<MealPlanningScreen3> createState() => _MealPlanningScreen3State();
}

class _MealPlanningScreen3State extends State<MealPlanningScreen3> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  final List<String> _goals = [
    'Weight Loss',
    'Weight Gain',
    'Muscle Gain',
    'General Health',
    'Manage Diabetes',
    'Heart Health',
  ];
  String? _selectedGoal;

  void _skipStep() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MealPlanningScreen4(userId: widget.userId),
      ),
    );
  }

  Future<void> _submitDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a health goal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'age': int.tryParse(_ageController.text) ?? 0,
        'goals': _selectedGoal,
        'tutorialStep': 3, // Update tutorial step
      };

      // Update the user's document in the 'Users' collection
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .set(updateData, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MealPlanningScreen4(userId: widget.userId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Styled TextField Helper ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: _getTextStyle(context, fontSize: 16),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _getTextStyle(
          context,
          color: _textColorSecondary(context),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: _primaryColor, size: 20),
        filled: true,
        fillColor: _scaffoldBgColor(context),
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
          borderSide: BorderSide(color: _primaryColor, width: 2),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Skip Button ---
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton(
                    onPressed: _skipStep,
                    child: Text(
                      'Skip for now',
                      style: _getTextStyle(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textColorSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Header ---
              Text(
                "Your Health Goals",
                style: _getTextStyle(
                  context,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Help us personalize your experience by providing a few details.",
                style: _getTextStyle(
                  context,
                  fontSize: 16,
                  color: _textColorSecondary(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // --- Form Area ---
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _ageController,
                          label: "Your Age",
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your age';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "What's your primary goal?",
                          style: _getTextStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColorPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: _goals.map((goal) {
                            final isSelected = _selectedGoal == goal;
                            return FilterChip(
                              label: Text(goal),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedGoal = goal;
                                });
                              },
                              labelStyle: _getTextStyle(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? _textColorOnPrimary
                                    : _primaryColor,
                              ),
                              backgroundColor: _cardBgColor(context),
                              selectedColor: _primaryColor,
                              checkmarkColor: _textColorOnPrimary,
                              side: BorderSide(
                                color: isSelected
                                    ? _primaryColor
                                    : _primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Submit Button ---
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: _primaryColor.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text(
                      "SAVE & CONTINUE",
                      style: _getTextStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColorOnPrimary,
                        letterSpacing: 0.5,
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
  }
}