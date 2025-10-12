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

  const PaymentPage({
    super.key,
    required this.planType,
    required this.planPrice,
    required this.dietitianName,
    required this.dietitianEmail,
    required this.dietitianProfile,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _qrPicUrl;
  bool _isLoading = true;
  String? _uploadedReceiptUrl;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchDietitianQrPic();
  }

  // 🔹 Fetch dietitian's qrpic
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

  // 🔹 Upload image to Cloudinary
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

  // 🔹 Pick image from gallery (≤ 10MB)
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    final fileSizeMB = imageFile.lengthSync() / (1024 * 1024);

    if (fileSizeMB > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image too large (${fileSizeMB.toStringAsFixed(2)} MB). Max allowed is 10 MB.")),
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

  // 🔹 Save receipt data to Firestore
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

    try {
      final dietitianQuery = await _firestore
          .collection('Users')
          .where('email', isEqualTo: widget.dietitianEmail)
          .limit(1)
          .get();

      if (dietitianQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dietitian not found.")),
        );
        return;
      }

      final dietitianID = dietitianQuery.docs.first.id;

      // 🔹 Save to Firestore
      await _firestore.collection('receipts').add({
        'clientID': user.uid,
        'dietitianID': dietitianID,
        'planPrice': widget.planPrice,
        'planType': widget.planType,
        'receiptImg': _uploadedReceiptUrl,
        'status': 'pending',
        'timeStamp': FieldValue.serverTimestamp(),
      });

      // 🔹 Send Gmail email to the dietitian
      await EmailSender.sendPaymentNotification(
        toEmail: widget.dietitianEmail,
        clientName: user.displayName ?? "A client",
        planType: widget.planType,
        planPrice: widget.planPrice,
        receiptUrl: _uploadedReceiptUrl!,
      );


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt submitted successfully.")),
      );

      // 🔹 Navigate to Home.dart
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const home()),
      );

    } catch (e) {
      debugPrint("Error saving receipt: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
              onPressed: _pickAndUploadImage,
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
              onPressed: _saveReceiptData,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Mark as Paid"),
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
