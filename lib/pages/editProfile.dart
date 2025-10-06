import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _weightController = TextEditingController();
  Future<Map<String, dynamic>?>? _userDataFuture;

  static const String _primaryFontFamily = 'PlusJakartaSans';
  static const Color _primaryColor = Color(0xFF4CAF50);

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle _helperStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11,
    color: Colors.black54,
  );

  final String cloudName = "dbc77ko88";
  final String uploadPreset = "profile";

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData(); // 👈 Runs only once
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
      print("🔹 Cloudinary response: $resBody");

      final data = json.decode(resBody);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        print("❌ Upload failed: ${data['error']}");
        return null;
      }
    } catch (e) {
      print("❌ Upload error: $e");
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl;

    // 🔹 If a new profile image was chosen, upload it first
    if (_profileImage != null) {
      imageUrl = await _uploadToCloudinary(_profileImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload image.")),
        );
        return;
      }
    }

    // 🔹 Prepare data to update
    final updateData = <String, dynamic>{};

    // Add new image URL only if user picked one
    if (imageUrl != null) updateData['profile'] = imageUrl;

    // Add current weight (if it’s not empty)
    if (_weightController.text.trim().isNotEmpty) {
      updateData['currentWeight'] = _weightController.text.trim();
    }

    // 🔹 Update Firestore only if there’s something to change
    if (updateData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated successfully!")),
      );

      // Refresh data on screen
      setState(() {
        _userDataFuture = _getUserData();
        _profileImage = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No changes to save.")),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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
            onPressed: _saveProfile,
            child: _isUploading
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
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data;

          if (userData != null && userData["currentWeight"] != null && _weightController.text.isEmpty) {
            _weightController.text = userData["currentWeight"].toString();
          }
          final String? profileUrl = userData?['profile'];
          final String displayName = user?.displayName ?? "Unknown User";
          final String displayEmail = user?.email ?? "";

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(20, keyboardHeight > 0 ? 16 : 20, 20, keyboardHeight > 0 ? 20 : 24),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 3))],
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
                                            offset: Offset(0, 2))
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
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: keyboardHeight > 0 ? 12.0 : 16.0,
                            ),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Profile Information",
                                      style: TextStyle(
                                        fontFamily: _primaryFontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      "Current weight",
                                      controller: _weightController,
                                      helperText: "Cooldown after changing (30 days)",
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField("Change Password", obscure: true),
                                    const SizedBox(height: 10),
                                    _buildTextField("Confirm Password", obscure: true),
                                  ],
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
        },
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
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

  Widget _buildTextField(
      String label, {
        bool obscure = false,
        String? helperText,
        TextEditingController? controller,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: _primaryFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            fontFamily: _primaryFontFamily,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            helperText: helperText,
            helperStyle: const TextStyle(
              fontFamily: _primaryFontFamily,
              fontSize: 11,
              color: Colors.black54,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
