import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../email/paymentNotifDietitian.dart';
import '../pages/home.dart';
import 'package:dotted_border/dotted_border.dart'; // Import for receipt preview

import 'package:mamas_recipe/widget/custom_snackbar.dart';

// --- Theme Helpers ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade50;
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

class PaymentPage extends StatefulWidget {
  final String planType;
  final String planPrice;
  final String dietitianName;
  final String dietitianEmail;
  final String dietitianProfile;
  final String? dietitianId;
  final double? priceAmount;
  final int? durationDays;

  const PaymentPage({
    super.key,
    required this.planType,
    required this.planPrice,
    required this.dietitianName,
    required this.dietitianEmail,
    required this.dietitianProfile,
    this.dietitianId,
    this.priceAmount,
    this.durationDays,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _qrPicUrl;
  bool _isLoading = true;
  bool _isUploading = false; // Separate loading state for submission
  String? _uploadedReceiptUrl;
  String? _resolvedDietitianId;
  double? _resolvedPriceAmount;
  int? _resolvedDurationDays;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializePaymentData();
  }

  // --- All backend logic functions (untouched, they are correct) ---
  Future<void> _initializePaymentData() async {
    setState(() => _isLoading = true);
    if (widget.dietitianId != null) {
      _resolvedDietitianId = widget.dietitianId;
      _resolvedPriceAmount = widget.priceAmount;
      _resolvedDurationDays = widget.durationDays;
    } else {
      await _fetchDietitianId();
      _resolvePlanDetails();
    }
    await _fetchDietitianQrPic();
  }

  Future<void> _fetchDietitianId() async {
    try {
      final query = await _firestore
          .collection('Users')
          .where('email', isEqualTo: widget.dietitianEmail)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        _resolvedDietitianId = query.docs.first.id;
      }
    } catch (e) {
      debugPrint("Error fetching dietitian ID: $e");
    }
  }

  void _resolvePlanDetails() {
    final priceString = widget.planPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    _resolvedPriceAmount = double.tryParse(priceString) ?? 0.0;
    switch (widget.planType.toLowerCase()) {
      case 'weekly':
        _resolvedDurationDays = 7;
        break;
      case 'monthly':
        _resolvedDurationDays = 30;
        break;
      case 'yearly':
        _resolvedDurationDays = 365;
        break;
      default:
        _resolvedDurationDays = 30;
    }
  }

  Future<void> _fetchDietitianQrPic() async {
    try {
      final query = await _firestore
          .collection('Users')
          .where('email', isEqualTo: widget.dietitianEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _qrPicUrl = query.docs.first.data()['qrpic'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching QR pic: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dbc77ko88';
    const uploadPreset = 'receipts';
    final url =
    Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'Receipts'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resData = await http.Response.fromStream(response);
      final data = json.decode(resData.body);
      return data['secure_url'];
    } else {
      debugPrint('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    final fileSizeMB = imageFile.lengthSync() / (1024 * 1024);

    if (fileSizeMB > 10) {
      CustomSnackBar.show(
        context,
        'Image too large (${fileSizeMB.toStringAsFixed(2)} MB). Max 10 MB.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _isUploading = true); // Use submission loader
    final uploadedUrl = await _uploadImageToCloudinary(imageFile);

    if (uploadedUrl != null) {
      setState(() {
        _uploadedReceiptUrl = uploadedUrl;
      });
      CustomSnackBar.show(
        context,
        'Receipt uploaded successfully',
        backgroundColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
      );
    } else {
      CustomSnackBar.show(
        context,
        'Failed to upload receipt',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
    setState(() => _isUploading = false);
  }

  Future<void> _saveReceiptData() async {
    final user = _auth.currentUser;
    if (user == null) {
      CustomSnackBar.show(
        context,
        'User not logged in.',
        backgroundColor: Colors.redAccent,
        icon: Icons.lock_outline,
      );
      return;
    }
    if (_uploadedReceiptUrl == null) {
      CustomSnackBar.show(
        context,
        'Please upload your receipt first.',
        backgroundColor: Colors.orange,
        icon: Icons.warning_outlined,
      );
      return;
    }
    if (_resolvedDietitianId == null) {
      CustomSnackBar.show(
        context,
        'Error: Dietitian information not found.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final now = DateTime.now();
      final durationDays = _resolvedDurationDays ?? 30;
      final endDate = now.add(Duration(days: durationDays));

      final subscriptionRef = await _firestore.collection('subscriptions').add({
        'dietitianId': _resolvedDietitianId,
        'userId': user.uid,
        'subscriptionType': widget.planType,
        'status': 'pending',
        'price': _resolvedPriceAmount ?? 0.0,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
      });

      await _firestore.collection('receipts').add({
        'clientID': user.uid,
        'dietitianID': _resolvedDietitianId,
        'subscriptionId': subscriptionRef.id,
        'planPrice': widget.planPrice,
        'planType': widget.planType,
        'receiptImg': _uploadedReceiptUrl,
        'status': 'pending',
        'timeStamp': FieldValue.serverTimestamp(),
      });

      await EmailSender.sendPaymentNotification(
        toEmail: widget.dietitianEmail,
        clientName: user.displayName ?? "A client",
        planType: widget.planType,
        planPrice: widget.planPrice,
        receiptUrl: _uploadedReceiptUrl!,
      );

      await _updateDietitianStats();
      if (!mounted) return;

      CustomSnackBar.show(
        context,
        'Receipt submitted! Your subscription will be activated after approval.',
        backgroundColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
        duration: const Duration(seconds: 4),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const home()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Error saving receipt: $e");
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        'Error: $e',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _updateDietitianStats() async {
    if (_resolvedDietitianId == null) return;
    try {
      final subscriptions = await _firestore
          .collection('subscriptions')
          .where('dietitianId', isEqualTo: _resolvedDietitianId)
          .get();

      double totalRevenue = 0;
      int activeCount = 0;
      int weeklyCount = 0;
      int monthlyCount = 0;
      int yearlyCount = 0;

      for (var doc in subscriptions.docs) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        final type = data['subscriptionType'];
        final status = data['status'];
        totalRevenue += price;
        if (status == 'active' || status == 'pending') activeCount++;
        switch (type) {
          case 'weekly':
            weeklyCount++;
            break;
          case 'monthly':
            monthlyCount++;
            break;
          case 'yearly':
            yearlyCount++;
            break;
        }
      }
      await _firestore.collection('Users').doc(_resolvedDietitianId).update({
        'activeSubscriptions': activeCount,
        'totalRevenue': totalRevenue,
        'totalCommission': totalRevenue * 0.10,
        'subscriptionBreakdown': {
          'weekly': weeklyCount,
          'monthly': monthlyCount,
          'yearly': yearlyCount,
        },
        'clientCount': activeCount,
      });
    } catch (e) {
      debugPrint('Error updating dietitian stats: $e');
    }
  }
  // --- End backend logic functions ---

  // --- Styled SnackBars ---

  // --- End Styled SnackBars ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        title: Text(
          "Payment",
          style: _getTextStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColorOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDietitianCard(context),
            const SizedBox(height: 20),
            _buildSummaryCard(context),
            const SizedBox(height: 20),
            _buildPaymentCard(context),
            const SizedBox(height: 20),
            _buildUploadCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  Widget _buildDietitianCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(widget.dietitianProfile),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Subscribing to:",
                  style: _getTextStyle(
                    context,
                    fontSize: 13,
                    color: _textColorSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.dietitianName,
                  style: _getTextStyle(
                    context,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.dietitianEmail,
                  style: _getTextStyle(
                    context,
                    fontSize: 14,
                    color: _textColorSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Summary",
            style: _getTextStyle(context,
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            context,
            "Plan:",
            widget.planType,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            "Duration:",
            "${_resolvedDurationDays ?? 30} days",
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            context,
            "Total Price:",
            widget.planPrice,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String title, String value,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: _getTextStyle(
            context,
            fontSize: 15,
            color: _textColorSecondary(context),
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: _getTextStyle(
            context,
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? _primaryColor : _textColorPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Payment Instructions",
            style: _getTextStyle(context,
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const SizedBox(
              height: 200,
              child:
              Center(child: CircularProgressIndicator(color: _primaryColor)),
            )
          else if (_qrPicUrl != null)
            Column(
              children: [
                Text(
                  "Scan this QR code to pay:",
                  style: _getTextStyle(
                    context,
                    fontSize: 15,
                    color: _textColorSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _qrPicUrl!,
                    height: 250,
                    width: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            )
          else
            Container(
              height: 150,
              child: Center(
                child: Text(
                  "Could not load QR Code.\nPlease contact dietitian.",
                  textAlign: TextAlign.center,
                  style: _getTextStyle(context, color: Colors.redAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Upload Receipt",
            style: _getTextStyle(context,
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload a screenshot of your payment to be verified.",
            textAlign: TextAlign.center,
            style: _getTextStyle(
              context,
              fontSize: 14,
              color: _textColorSecondary(context),
            ),
          ),
          const SizedBox(height: 20),
          if (_uploadedReceiptUrl == null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  "Upload Receipt Image",
                  style: _getTextStyle(context,
                      fontWeight: FontWeight.bold, color: _primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: const BorderSide(color: _primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                ClipRRect(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                        Image.network(_uploadedReceiptUrl!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    "Change Image",
                    style: _getTextStyle(context,
                        fontSize: 14, color: _primaryColor),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    bool canSubmit = _uploadedReceiptUrl != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (canSubmit && !_isUploading) ? _saveReceiptData : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: _textColorOnPrimary,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
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
            "Submit for Approval",
            style: _getTextStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: canSubmit
                  ? _textColorOnPrimary
                  : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}