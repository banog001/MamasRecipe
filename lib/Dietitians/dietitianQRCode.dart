import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../email/OTPSender.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter/services.dart';

import 'package:mamas_recipe/widget/custom_snackbar.dart';

class DietitianQRCodePage extends StatefulWidget {
  const DietitianQRCodePage({super.key});

  @override
  State<DietitianQRCodePage> createState() => _DietitianQRCodePageState();
}

class _DietitianQRCodePageState extends State<DietitianQRCodePage> {
  late EmailOtpService _emailOtpService;
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

    _emailOtpService = EmailOtpService(
      senderEmail: 'mamas.recipe0@gmail.com',       // replace later with secure storage
      appPassword: 'gbsk ioml dham zgme', // your Gmail app password
    );
  }

  // REPLACE your _showLoadingDialogBeforeOTP method with this fixed version

  void _showLoadingDialogBeforeOTP(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated circular loading indicator
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor,
                      _primaryColor.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Main loading text
              Text(
                'Sending OTP',
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle with email
              Text(
                'We\'re sending a verification code to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Animated dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryColor.withOpacity(
                          0.3 + (index * 0.2),
                        ),
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

    // ✅ SEND OTP INSIDE THE LOADING DIALOG
    _sendOtpAndProceed(email);
  }

// ✅ NEW METHOD: Send OTP and handle the dialog flow
  Future<void> _sendOtpAndProceed(String email) async {
    try {
      // This is where the actual email delay happens
      await _emailOtpService.sendOtpToEmail(email);

      if (!mounted) return;

      // Close the loading dialog after OTP is actually sent
      Navigator.of(context).pop();

      // Now show the OTP verification dialog
      await _showOtpVerificationDialog(email);
    } catch (e) {
      if (!mounted) return;

      // Close the loading dialog on error
      Navigator.of(context).pop();

      CustomSnackBar.show(
        context,
        'Failed to send OTP. Please try again.',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _qrCodeImage = File(pickedFile.path);
      });
    }
  }
// REPLACE your _showOtpVerificationDialog method with this improved version

  Future<void> _showOtpVerificationDialog(String email) async {
    final otpController = TextEditingController();
    bool isVerifying = false;
    bool isSendingOtp = true; // Track OTP sending state
    String? otpErrorMessage;

    // Send OTP via the service
    try {
      await _emailOtpService.sendOtpToEmail(email);
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        'Failed to send OTP. Please try again.',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                // Main content card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor,
                                _primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 24,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Email Verification',
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter the 6-digit OTP sent to $email',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              // OTP Input Field
                              Container(
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _primaryColor.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  controller: otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  enabled: !isVerifying,
                                  style: TextStyle(
                                    fontFamily: _primaryFontFamily,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 12,
                                    color: _primaryColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '000000',
                                    hintStyle: TextStyle(
                                      fontSize: 28,
                                      letterSpacing: 12,
                                      color: Colors.grey.shade300,
                                    ),
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Error Message (if any)
                              if (otpErrorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 20,
                                        color: Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          otpErrorMessage!,
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontSize: 13,
                                            color: Colors.red.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // Verify Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isVerifying
                                      ? null
                                      : () async {
                                    setState(() {
                                      isVerifying = true;
                                      otpErrorMessage = null;
                                    });

                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );

                                    final enteredOtp =
                                    otpController.text.trim();

                                    if (enteredOtp.length != 6) {
                                      setState(() {
                                        otpErrorMessage =
                                        'Please enter a valid 6-digit OTP';
                                        isVerifying = false;
                                      });
                                      return;
                                    }

                                    final isValid =
                                    _emailOtpService.verifyOtp(
                                      enteredOtp,
                                    );

                                    if (isValid) {
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      _showImageSourceDialog();
                                    } else {
                                      setState(() {
                                        otpErrorMessage =
                                        'Invalid or expired OTP. Please try again.';
                                        isVerifying = false;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: _primaryColor.withOpacity(0.3),
                                    disabledBackgroundColor:
                                    Colors.grey.shade300,
                                  ),
                                  icon: isVerifying
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                      : const Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                  ),
                                  label: Text(
                                    isVerifying ? 'Verifying...' : 'Verify OTP',
                                    style: TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Cancel Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: isVerifying
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: isVerifying
                                          ? Colors.grey.shade300
                                          : _primaryColor,
                                      width: 1.5,
                                    ),
                                    foregroundColor: isVerifying
                                        ? Colors.grey.shade400
                                        : _primaryColor,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Info Text
                              Text(
                                "Check your email for the 6-digit code",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    otpController.dispose();
  }

  Future<void> _downloadFileFromAssets(BuildContext context) async {
    try {
      // 1️⃣ Load PDF from assets
      final byteData = await rootBundle.load('lib/assets/files/DIETITIAN-SERVICE-AGREEMENT.pdf');

      // 2️⃣ Prepare save dialog parameters
      final params = SaveFileDialogParams(
        data: byteData.buffer.asUint8List(),
        fileName: 'DIETITIAN-SERVICE-AGREEMENT.pdf',
        // fileType and allowedExtensions are no longer needed
      );

      // 3️⃣ Open save dialog
      final savedFilePath = await FlutterFileDialog.saveFile(params: params);

      // 4️⃣ Notify user
      if (savedFilePath != null) {
        CustomSnackBar.show(context, 'PDF downloaded successfully', backgroundColor: Colors.green, icon: Icons.file_download_done);

      } else {
        CustomSnackBar.show(context, 'Save canceled by user', backgroundColor: Colors.orange, icon: Icons.cancel_outlined);

      }
    } catch (e) {
      print('$e');
      CustomSnackBar.show(context, 'Error saving PDF: $e', backgroundColor: Colors.red, icon: Icons.error_outline);

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
    try {
      // Cloudinary unsigned upload preset (create this in Cloudinary console)
      const cloudName = 'dbc77ko88';
      const uploadPreset = 'qrpicture';

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = json.decode(responseData.body);
        setState(() => _isUploading = false);
        return data['secure_url'];
      } else {
        debugPrint('Cloudinary upload failed: ${responseData.body}');
        setState(() => _isUploading = false);
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      setState(() => _isUploading = false);
      return null;
    }
  }

  Future<void> _saveQRCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_qrCodeImage == null) {
      if (!mounted) return;
      CustomSnackBar.show(context, 'Please select a QR code image first.', backgroundColor: Colors.orange, icon: Icons.warning_outlined);

      return;
    }

    final String? imageUrl = await _uploadQRCodeImage(_qrCodeImage!);

    if (!mounted) return;

    if (imageUrl == null) {
      CustomSnackBar.show(context, 'Failed to upload QR code. Please implement upload logic.', backgroundColor: Colors.red, icon: Icons.error_outline);

      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .set({'qrpic': imageUrl}, SetOptions(merge: true));

      if (!mounted) return;

      // Fetch the updated data again
      final updatedData = await _getUserData();

      setState(() {
        _userDataFuture = Future.value(updatedData); // ✅ force refresh
        _qrCodeImage = null;
      });

      CustomSnackBar.show(context, 'QR code saved successfully!', backgroundColor: const Color(0xFF4CAF50), icon: Icons.check_circle_outline);

    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(context, 'Error saving QR code: $e', backgroundColor: Colors.red, icon: Icons.error_outline);

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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          final String? qrCodeUrl = userData?['qrpic'];
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
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    final hasQrPic = userData?['qrpic'] != null &&
                                        (userData?['qrpic'] as String).isNotEmpty;
                                    final qrApproved = userData?['qrapproved'] ?? false;
                                    if (user == null) return;

                                    if (!hasQrPic && !qrApproved) {
                                      // Create qrstatus field as "pending"
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection("Users")
                                            .doc(user.uid)
                                            .set({'qrstatus': 'pending'}, SetOptions(merge: true));

                                        CustomSnackBar.show(
                                          context,
                                          'Your request has been sent. We\'ll check your QR code soon!',
                                          backgroundColor: Colors.green,
                                          icon: Icons.check_circle_outline,
                                        );
                                      } catch (e) {
                                        CustomSnackBar.show(
                                          context,
                                          'Failed to send request: $e',
                                          backgroundColor: Colors.red,
                                          icon: Icons.error_outline,
                                        );
                                      }
                                      return;
                                    }

                                    // If qrpic exists or is approved, proceed with OTP verification to upload/change QR
                                    if (user.email != null) {
                                      // Show loading dialog while sending OTP
                                      _showLoadingDialogBeforeOTP(user.email!);
                                    } else {
                                      CustomSnackBar.show(
                                        context,
                                        'No email found for your account.',
                                        backgroundColor: Colors.orange,
                                        icon: Icons.mail_outline,
                                      );
                                    }
                                  },
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
                                    (() {
                                      final hasQrPic = userData?['qrpic'] != null &&
                                          (userData?['qrpic'] as String).isNotEmpty;
                                      final qrApproved = userData?['qrapproved'] ?? false;
                                      final qrStatus = userData?['qrstatus'] ?? '';

                                      if ((userData?['qrpic'] == null ||
                                          (userData?['qrpic'] as String).isEmpty) &&
                                          !qrApproved &&
                                          qrStatus == 'pending') {
                                        return "Request to upload QR Code";
                                      } else if ((userData?['qrpic'] == null ||
                                          (userData?['qrpic'] as String).isEmpty) &&
                                          qrApproved &&
                                          qrStatus == 'approved') {
                                        return "Upload QR Code";
                                      } else if (hasQrPic && qrApproved && qrStatus == 'approved') {
                                        return "Change QR Code";
                                      } else {
                                        // fallback text
                                        return "Upload QR Code";
                                      }
                                    })(),
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
                              // your existing QR code UI here...

                              const SizedBox(height: 20),

                              // 🧾 File download section
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'DIETITIAN-SERVICE-AGREEMENT.pdf',
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download_rounded, color: _primaryColor),
                                      onPressed: () => _downloadFileFromAssets(context),
                                    ),
                                  ],
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
                                    "• Upload your personal GcashQR or any bankQR code image\n"
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
