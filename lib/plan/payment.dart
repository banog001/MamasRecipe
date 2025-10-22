import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../email/paymentNotifDietitian.dart';
import '../pages/home.dart';

class PaymentPage extends StatefulWidget {
  final String planType;
  final String planPrice;
  final String dietitianName;
  final String dietitianEmail;
  final String dietitianProfile;
  // NEW PARAMETERS
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
    this.dietitianId, // Optional for backward compatibility
    this.priceAmount, // Optional for backward compatibility
    this.durationDays, // Optional for backward compatibility
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _qrPicUrl;
  bool _isLoading = true;
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

  // Initialize and resolve payment data
  Future<void> _initializePaymentData() async {
    setState(() => _isLoading = true);

    // If dietitianId is already provided, use it
    if (widget.dietitianId != null) {
      _resolvedDietitianId = widget.dietitianId;
      _resolvedPriceAmount = widget.priceAmount;
      _resolvedDurationDays = widget.durationDays;
    } else {
      // Fetch dietitianId from email (backward compatibility)
      await _fetchDietitianId();

      // Parse price and duration from planType if not provided
      _resolvePlanDetails();
    }

    await _fetchDietitianQrPic();
  }

  // Fetch dietitian ID from email
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

  // Resolve plan details from planType string (backward compatibility)
  void _resolvePlanDetails() {
    // Extract price from planPrice string (e.g., "₱ 250.00" -> 250.0)
    final priceString = widget.planPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    _resolvedPriceAmount = double.tryParse(priceString) ?? 0.0;

    // Determine duration from planType
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
        _resolvedDurationDays = 30; // Default to monthly
    }
  }

  // Fetch dietitian's qrpic
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

  // Upload image to Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dbc77ko88';
    const uploadPreset = 'receipts';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
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

  // Pick image from gallery (≤ 10MB)
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    final fileSizeMB = imageFile.lengthSync() / (1024 * 1024);

    if (fileSizeMB > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Image too large (${fileSizeMB.toStringAsFixed(2)} MB). Max allowed is 10 MB.",
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uploadedUrl = await _uploadImageToCloudinary(imageFile);
    if (uploadedUrl != null) {
      setState(() {
        _uploadedReceiptUrl = uploadedUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt uploaded successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload receipt")),
      );
    }

    setState(() => _isLoading = false);
  }

  // Save receipt data and create subscription
  Future<void> _saveReceiptData() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    if (_uploadedReceiptUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your receipt first.")),
      );
      return;
    }

    if (_resolvedDietitianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Dietitian information not found.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calculate subscription dates
      final now = DateTime.now();
      final durationDays = _resolvedDurationDays ?? 30;
      final endDate = now.add(Duration(days: durationDays));

      // Create subscription document
      final subscriptionRef = await _firestore.collection('subscriptions').add({
        'dietitianId': _resolvedDietitianId,
        'userId': user.uid,
        'subscriptionType': widget.planType,
        'status': 'pending', // Will be 'active' after admin approval
        'price': _resolvedPriceAmount ?? 0.0,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
      });

      // Save receipt with subscription reference
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

      // Send email notification to dietitian
      await EmailSender.sendPaymentNotification(
        toEmail: widget.dietitianEmail,
        clientName: user.displayName ?? "A client",
        planType: widget.planType,
        planPrice: widget.planPrice,
        receiptUrl: _uploadedReceiptUrl!,
      );

      // Update dietitian's subscriber count temporarily
      await _updateDietitianStats();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Receipt submitted successfully. Your subscription will be activated after approval.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const home()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Error saving receipt: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update dietitian statistics
  Future<void> _updateDietitianStats() async {
    if (_resolvedDietitianId == null) return;

    try {
      // Fetch all active subscriptions for this dietitian
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

      // Update dietitian document
      await _firestore.collection('Users').doc(_resolvedDietitianId).update({
        'activeSubscriptions': activeCount,
        'totalRevenue': totalRevenue,
        'totalCommission': totalRevenue * 0.10,
        'subscriptionBreakdown': {
          'weekly': weeklyCount,
          'monthly': monthlyCount,
          'yearly': yearlyCount,
        },
        'clientCount': activeCount, // Update client count
      });
    } catch (e) {
      debugPrint('Error updating dietitian stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const String fontFamily = 'Poppins';
    const Color primaryColor = Color(0xFF1B8C53);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Plan Summary",
          style: TextStyle(
            fontFamily: fontFamily,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(widget.dietitianProfile),
            ),
            const SizedBox(height: 15),
            Text(
              widget.dietitianName,
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.dietitianEmail,
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              "You selected the ${widget.planType} Plan",
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Price: ${widget.planPrice}",
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Duration: ${_resolvedDurationDays ?? 30} days",
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(color: primaryColor)
            else if (_qrPicUrl != null)
              Column(
                children: [
                  const Text(
                    "Scan this QR code to pay:",
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _qrPicUrl!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndUploadImage,
              icon: const Icon(Icons.upload),
              label: const Text("Upload Receipt"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_uploadedReceiptUrl != null) ...[
              const SizedBox(height: 20),
              Image.network(_uploadedReceiptUrl!, height: 150),
            ],
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveReceiptData,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isLoading ? "Processing..." : "Mark as Paid"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}