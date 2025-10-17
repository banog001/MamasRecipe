import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'start4.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class MealPlanningScreen3Dietitian extends StatefulWidget {
  final String userId;
  const MealPlanningScreen3Dietitian({super.key, required this.userId});

  @override
  State<MealPlanningScreen3Dietitian> createState() =>
      _MealPlanningScreen3DietitianState();
}

class _MealPlanningScreen3DietitianState
    extends State<MealPlanningScreen3Dietitian> {
  final _formKey = GlobalKey<FormState>();
  final _prcLicenseController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _prcIdImage;
  bool _isUploading = false;

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _prcIdImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_prcIdImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your PRC ID image.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload image to Cloudinary (unsigned upload)
      final cloudName = 'dbc77ko88';
      final uploadPreset = 'licensePic';
      final uploadUrl =
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'PRCPic'
        ..files.add(await http.MultipartFile.fromPath('file', _prcIdImage!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resData = json.decode(await response.stream.bytesToString());
        final imageUrl = resData['secure_url'];

        // Prepare updated data
        final updateData = {
          'licenseNum': int.tryParse(_prcLicenseController.text) ?? 0,
          'prcImageUrl': imageUrl,
          'status': 'pending', // stay pending until admin approves
        };

        // ✅ Update existing record (instead of creating)
        await FirebaseFirestore.instance
            .collection('dietitianApproval')
            .doc(widget.userId)
            .set(updateData, SetOptions(merge: true));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MealPlanningScreen4(userId: widget.userId),
          ),
        );
      } else {
        throw Exception('Cloudinary upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dietitian Application"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Verification Details",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please provide your professional credentials. Your account will be reviewed by an administrator.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _prcLicenseController,
                decoration: const InputDecoration(
                  labelText: "PRC License Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your PRC License Number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "PRC ID Image",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _prcIdImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_prcIdImage!, fit: BoxFit.cover),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Tap to upload your PRC ID"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SUBMIT APPLICATION & CONTINUE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}