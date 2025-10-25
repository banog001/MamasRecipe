import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamas_recipe/widget/custom_snackbar.dart';
import 'home.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isSaving = false;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();

  int? selectedHealthGoalIndex;
  int? selectedActivityLevelIndex;
  double? currentBMI;
  String? bmiCategory;
  List<String>? suggestedHealthGoals;

  Future<Map<String, dynamic>?>? _userDataFuture;

  static const String _primaryFontFamily = 'PlusJakartaSans';
  static const Color _primaryColor = Color(0xFF4CAF50);

  final String cloudName = "dbc77ko88";
  final String uploadPreset = "profile";

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

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: _primaryColor),
                ),
                title: const Text("Choose from Gallery", style: TextStyle(fontFamily: _primaryFontFamily)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: _primaryColor),
                ),
                title: const Text("Take a Photo", style: TextStyle(fontFamily: _primaryFontFamily)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      setState(() => _isUploading = true);

      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      final data = json.decode(resBody);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    // Validate health data
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

    // Upload image if selected
    String? imageUrl;
    if (_profileImage != null) {
      imageUrl = await _uploadToCloudinary(_profileImage!);
      if (imageUrl == null) {
        _showErrorSnackBar("Failed to upload image");
        setState(() => _isSaving = false);
        return;
      }
    }

    // Prepare data to update
    final String healthGoal = healthGoals[selectedHealthGoalIndex!]["text"];
    final String activityLevel = activityLevels[selectedActivityLevelIndex!]["text"];
    final double bmi = _calculateBMI(weight, height);
    final calculatedBmiCategory = _getBMICategory(bmi)['category'];

    final updateData = <String, dynamic>{
      "currentWeight": weight,
      "height": height,
      "bmi": bmi.toStringAsFixed(2),
      "bmiCategory": calculatedBmiCategory,
      "goals": healthGoal,
      "activityLevel": activityLevel,
      "bmiUpdatedAt": FieldValue.serverTimestamp(),
    };

    if (imageUrl != null) {
      updateData['profile'] = imageUrl;
    }

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Profile updated successfully!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
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

  Map<String, dynamic> _validateHeightWeight(double weight, double height) {
    if (height < 50) {
      return {'isValid': false, 'message': 'Height is too low (minimum: 50 cm)', 'type': 'height'};
    }
    if (height > 250) {
      return {'isValid': false, 'message': 'Height is too high (maximum: 250 cm)', 'type': 'height'};
    }
    if (weight < 30) {
      return {'isValid': false, 'message': 'Weight is too low (minimum: 30 kg)', 'type': 'weight'};
    }
    if (weight > 500) {
      return {'isValid': false, 'message': 'Weight is too high (maximum: 500 kg)', 'type': 'weight'};
    }
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
    return {'isValid': true, 'message': 'Valid', 'type': 'valid'};
  }

  double _calculateBMI(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  Map<String, dynamic> _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return {'category': 'Underweight', 'color': Colors.blue, 'goals': ['Weight Gain']};
    } else if (bmi < 25) {
      return {'category': 'Normal Weight', 'color': Colors.green, 'goals': ['Maintain Weight', 'Workout']};
    } else if (bmi < 30) {
      return {'category': 'Overweight', 'color': Colors.orange, 'goals': ['Weight Loss', 'Workout']};
    } else {
      return {'category': 'Obese', 'color': Colors.red, 'goals': ['Weight Loss']};
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

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .get();

    final data = snapshot.data();

    // Initialize form data
    if (data != null) {
      _weightController.text = data['currentWeight']?.toString() ?? '';
      _heightController.text = data['height']?.toString() ?? '';

      final String currentGoal = data['goals'] ?? '';
      final int goalIndex = healthGoals.indexWhere((goal) => goal['text'] == currentGoal);
      selectedHealthGoalIndex = (goalIndex != -1) ? goalIndex : null;

      final String currentActivity = data['activityLevel'] ?? '';
      final int activityIndex = activityLevels.indexWhere((level) => level['text'] == currentActivity);
      selectedActivityLevelIndex = (activityIndex != -1) ? activityIndex : null;

      _updateBMI();
    }

    return data;
  }

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
        child: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Please enter valid numbers',
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
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
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                validation['message'] ?? 'Invalid input',
                style: const TextStyle(
                  fontFamily: _primaryFontFamily,
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
            border: Border.all(color: categoryColor.withOpacity(0.3), width: 2),
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
                      const Text(
                        "Your BMI",
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentBMI!.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
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
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
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
              if (suggestedHealthGoals != null && suggestedHealthGoals!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: categoryColor.withOpacity(0.2), height: 24),
                    const Text(
                      "Recommended Goals for Your BMI:",
                      style: TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
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
                            style: TextStyle(
                              fontFamily: _primaryFontFamily,
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: (_isUploading || _isSaving) ? null : _saveProfile,
            child: (_isUploading || _isSaving)
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: _primaryFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          final userData = snapshot.data;
          final String? profileUrl = userData?['profile'];
          final String displayName = user?.displayName ?? "Unknown User";
          final String displayEmail = user?.email ?? "";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (profileUrl != null && profileUrl.isNotEmpty)
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: (_profileImage == null && (profileUrl == null || profileUrl.isEmpty))
                                  ? const Icon(Icons.person_outline, size: 42, color: _primaryColor)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                onTap: _showImageSourceDialog,
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(Icons.camera_alt, color: _primaryColor, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (displayEmail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          displayEmail,
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Health Information Form
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Personal Information",
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Weight (kg)",
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _weightController,
                                          focusNode: _weightFocusNode,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => _updateBMI(),
                                          decoration: InputDecoration(
                                            hintText: 'e.g., 70',
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                            prefixIcon: const Icon(Icons.monitor_weight_outlined, color: _primaryColor, size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: _primaryColor, width: 2),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                        const Text(
                                          "Height (cm)",
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _heightController,
                                          focusNode: _heightFocusNode,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => _updateBMI(),
                                          decoration: InputDecoration(
                                            hintText: 'e.g., 170',
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                            prefixIcon: const Icon(Icons.height, color: _primaryColor, size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: _primaryColor, width: 2),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Health Goals Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Health Goals",
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "What would you like to achieve?",
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: healthGoals.length,
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, index) {
                                  final item = healthGoals[index];
                                  final bool isItemSelected = selectedHealthGoalIndex == index;

                                  return GestureDetector(
                                    onTap: () => setState(() => selectedHealthGoalIndex = index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: isItemSelected ? _primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isItemSelected ? _primaryColor : Colors.grey.shade300,
                                          width: isItemSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
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
                                              style: TextStyle(
                                                fontFamily: _primaryFontFamily,
                                                fontSize: 15,
                                                fontWeight: isItemSelected ? FontWeight.bold : FontWeight.w500,
                                                color: isItemSelected ? _primaryColor : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isItemSelected)
                                            const Icon(Icons.check_circle, color: _primaryColor, size: 20),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Activity Level Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Activity & Lifestyle",
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "How would you describe your activity level?",
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: activityLevels.length,
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, index) {
                                  final item = activityLevels[index];
                                  final bool isItemSelected = selectedActivityLevelIndex == index;

                                  return GestureDetector(
                                    onTap: () => setState(() => selectedActivityLevelIndex = index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: isItemSelected ? _primaryColor.withOpacity(0.1) : Colors.grey.shade100,
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
                                                  style: TextStyle(
                                                    fontFamily: _primaryFontFamily,
                                                    fontSize: 15,
                                                    fontWeight: isItemSelected ? FontWeight.bold : FontWeight.w500,
                                                    color: isItemSelected ? _primaryColor : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              if (isItemSelected)
                                                const Icon(Icons.check_circle, color: _primaryColor, size: 20),
                                            ],
                                          ),
                                          if (item["description"] != null) ...[
                                            const SizedBox(height: 6),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 36),
                                              child: Text(
                                                item["description"],
                                                style: const TextStyle(
                                                  fontFamily: _primaryFontFamily,
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
            unselectedItemColor: Colors.white.withOpacity(0.6),
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
  }
}