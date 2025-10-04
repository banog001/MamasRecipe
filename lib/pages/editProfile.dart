import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // 🔹 Replace with your Cloudinary info
  final String cloudName = "dbc77ko88";
  final String uploadPreset = "profile";

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
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Upload to Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      setState(() => _isUploading = true);

      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      print("🔹 Cloudinary response: $resBody"); // <--- ADD THIS

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


  // 🔹 Save to Firestore
  Future<void> _saveProfile() async {
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please choose a profile image first.")),
      );
      return;
    }

    final imageUrl = await _uploadToCloudinary(_profileImage!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .update({'profile': imageUrl});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Profile updated successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Profile Picture
          Container(
            color: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person,
                        size: 80, color: Colors.black54)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.green, size: 20),
                        onPressed: _showImageSourceDialog,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form Fields
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField("Username"),
                    const SizedBox(height: 16),
                    _buildTextField("Current weight",
                        helperText: "Cooldown after changing (30 days)"),
                    const SizedBox(height: 16),
                    _buildTextField("Change Password", obscure: true),
                    const SizedBox(height: 16),
                    _buildTextField("Confirm Password", obscure: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: ""),
        ],
      ),
    );
  }

  Widget _buildTextField(String label,
      {bool obscure = false, String? helperText}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const UnderlineInputBorder(),
      ),
    );
  }
}
