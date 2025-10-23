import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Uses XFile
import 'start4.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';
// import 'dart:io'; // <-- REMOVED for web compatibility

// --- Theme Helpers ---
const String _primaryFontFamily = 'PlusJakartaSans';

const Color _primaryColor = Color(0xFF4CAF50);
Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white;
Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;
Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;
Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;
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
  XFile? _prcIdImage; // <-- CHANGED: From File? to XFile?
  bool _isUploading = false;

  Future<void> _showImageSourceDialog() async {
    // (This function is fine as-is)
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading:
                  Icon(Icons.photo_library_outlined, color: _primaryColor),
                  title: Text(
                    'Choose from Gallery',
                    style: _getTextStyle(context),
                  ),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading:
                  Icon(Icons.camera_alt_outlined, color: _primaryColor),
                  title: Text(
                    'Take a Photo',
                    style: _getTextStyle(context),
                  ),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
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
          _prcIdImage = pickedFile; // <-- CHANGED: No longer wraps in File()
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to pick image: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    // (This function is fine as-is)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: _textColorOnPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }



  Future<void> _submitApplication() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_prcIdImage == null) {
      _showErrorSnackBar('Please upload your PRC ID image.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final cloudName = 'dbc77ko88';
      final uploadPreset = 'licensePic';
      final uploadUrl =
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'PRCPic';

      // --- CHANGED: Use fromBytes for web compatibility ---
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await _prcIdImage!.readAsBytes(),
        filename: _prcIdImage!.name, // Include a filename
      ));
      // --- End Change ---

      final response = await request.send();

      if (response.statusCode == 200) {
        final resData = json.decode(await response.stream.bytesToString());
        final imageUrl = resData['secure_url'];

        final updateData = {
          'licenseNum': int.tryParse(_prcLicenseController.text) ?? 0,
          'prcImageUrl': imageUrl,
          'status': 'pending',
          'tutorialStep': 3,
        };

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
        throw Exception(
            'Cloudinary upload failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    // (This function is fine as-is)
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DottedBorder(
          color: _primaryColor.withOpacity(0.7),
          strokeWidth: 2,
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          dashPattern: const [8, 4],
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
            ),
            child: _prcIdImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // --- CHANGED: Use Image.network for web ---
              // The path from image_picker on web is a URL (blob:...)
              child: Image.network(_prcIdImage!.path, fit: BoxFit.cover),
              // --- End Change ---
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 50,
                  color: _primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  "Tap to upload your PRC ID",
                  style: _getTextStyle(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "(JPG, PNG)",
                  style: _getTextStyle(
                    context,
                    fontSize: 13,
                    color: _textColorSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // (This function is fine as-is)
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),
              Text(
                "Verification Details",
                style: _getTextStyle(
                  context,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please provide your professional credentials. Your account will be reviewed by an administrator.",
                style: _getTextStyle(
                  context,
                  fontSize: 16,
                  color: _textColorSecondary(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _prcLicenseController,
                          label: "PRC License Number",
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your PRC License Number';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "PRC ID Image",
                          style: _getTextStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColorPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildImagePicker(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: _primaryColor.withOpacity(0.3),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text(
                      "SUBMIT & CONTINUE",
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