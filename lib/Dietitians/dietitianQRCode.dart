import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DietitianQRCodePage extends StatefulWidget {
  const DietitianQRCodePage({super.key});

  @override
  State<DietitianQRCodePage> createState() => _DietitianQRCodePageState();
}

class _DietitianQRCodePageState extends State<DietitianQRCodePage> {
  File? _qrCodeImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  Future<Map<String, dynamic>?>? _userDataFuture;

  static const String _primaryFontFamily = 'PlusJakartaSans';
  static const Color _primaryColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _qrCodeImage = File(pickedFile.path);
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

  Future<String?> _uploadQRCodeImage(File imageFile) async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isUploading = false);
    return null;
  }

  Future<void> _saveQRCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_qrCodeImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a QR code image first.")),
      );
      return;
    }

    final String? imageUrl = await _uploadQRCodeImage(_qrCodeImage!);

    if (!mounted) return;

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload QR code. Please implement upload logic.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .update({'qrCodeUrl': imageUrl});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ QR code saved successfully!"),
          backgroundColor: _primaryColor,
        ),
      );

      setState(() {
        _userDataFuture = _getUserData();
        _qrCodeImage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving QR code: $e")),
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My QR Code",
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _saveQRCode,
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
          final String? qrCodeUrl = userData?['qrCodeUrl'];
          final String displayName = user?.displayName ?? "Unknown User";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 60,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Share this QR code with your clients",
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: _qrCodeImage != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _qrCodeImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : (qrCodeUrl != null && qrCodeUrl.isNotEmpty)
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    qrCodeUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Failed to load QR code",
                                            style: TextStyle(
                                              fontFamily: _primaryFontFamily,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                )
                                    : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No QR code uploaded",
                                      style: TextStyle(
                                        fontFamily: _primaryFontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Upload your QR code image",
                                      style: TextStyle(
                                        fontFamily: _primaryFontFamily,
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showImageSourceDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.upload_outlined, size: 20),
                                  label: Text(
                                    _qrCodeImage != null || (qrCodeUrl != null && qrCodeUrl.isNotEmpty)
                                        ? "Change QR Code"
                                        : "Upload QR Code",
                                    style: const TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: _primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "How to use your QR code",
                                    style: TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "• Upload your personal QR code image\n"
                                        "• Clients can scan it to connect with you\n"
                                        "• Update anytime by uploading a new image",
                                    style: TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
