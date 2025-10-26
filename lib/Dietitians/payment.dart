import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const String _primaryFontFamily = 'YourFontFamily';
  static const Color _primaryColor = Colors.green;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Commission rates based on plan type
  static const Map<String, double> commissionRates = {
    'weekly': 0.15,   // 15%
    'monthly': 0.10,  // 10%
    'yearly': 0.08,   // 8%
  };

  bool _isPaymentPeriod() {
    final now = DateTime.now();
    return now.day >= 1 && now.day <= 5;
  }

  String _getNextPaymentDate() {
    final now = DateTime.now();
    DateTime nextPayment;

    if (now.day <= 5) {
      nextPayment = DateTime(now.year, now.month, 5);
    } else {
      // Next month's 5th
      if (now.month == 12) {
        nextPayment = DateTime(now.year + 1, 1, 5);
      } else {
        nextPayment = DateTime(now.year, now.month + 1, 5);
      }
    }

    return DateFormat('MMMM dd, yyyy').format(nextPayment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Commission Payment',
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('receipts')
            .where('dietitianID', isEqualTo: currentUserId)
            .orderBy('timeStamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No payment records found',
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final paymentData = _calculateCommissionOwed(docs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Owed Card
                _buildAmountOwedCard(paymentData),
                const SizedBox(height: 24),

                // Commission Breakdown
                _buildCommissionBreakdown(paymentData),
                const SizedBox(height: 24),

                // Transaction List
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTransactionList(docs),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calculateCommissionOwed(List<QueryDocumentSnapshot> docs) {
    double totalRevenue = 0.0;
    double totalCommissionOwed = 0.0;
    double dietitianEarnings = 0.0;
    int totalTransactions = 0;

    Map<String, int> planTypeCounts = {
      'weekly': 0,
      'monthly': 0,
      'yearly': 0,
    };

    Map<String, double> planTypeRevenue = {
      'weekly': 0.0,
      'monthly': 0.0,
      'yearly': 0.0,
    };

    Map<String, double> planTypeCommission = {
      'weekly': 0.0,
      'monthly': 0.0,
      'yearly': 0.0,
    };

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      final commissionPaid = data['commissionPaid'] ?? false; // NEW: Check if commission paid

      // Skip pending, declined, and already paid commissions
      if (status == 'pending' || status == 'declined' || commissionPaid) {
        continue;
      }

      final planType = (data['planType'] ?? '').toString().toLowerCase();
      final priceString = data['planPrice'] ?? '₱ 0.00';
      final price = _parsePrice(priceString);

      if (price > 0 && commissionRates.containsKey(planType)) {
        final commissionRate = commissionRates[planType]!;
        final commission = price * commissionRate;
        final earnings = price - commission;

        totalRevenue += price;
        totalCommissionOwed += commission;
        dietitianEarnings += earnings;
        totalTransactions++;

        planTypeCounts[planType] = (planTypeCounts[planType] ?? 0) + 1;
        planTypeRevenue[planType] = (planTypeRevenue[planType] ?? 0.0) + price;
        planTypeCommission[planType] = (planTypeCommission[planType] ?? 0.0) + commission;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalCommissionOwed': totalCommissionOwed,
      'dietitianEarnings': dietitianEarnings,
      'totalTransactions': totalTransactions,
      'planTypeCounts': planTypeCounts,
      'planTypeRevenue': planTypeRevenue,
      'planTypeCommission': planTypeCommission,
    };
  }

  double _parsePrice(String priceString) {
    try {
      // Remove currency symbol, spaces, and commas
      final cleanPrice = priceString
          .replaceAll('₱', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();
      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildAmountOwedCard(Map<String, dynamic> data) {
    final isPaymentPeriod = _isPaymentPeriod();
    final nextPaymentDate = _getNextPaymentDate();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.red[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Commission Payment Due',
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPaymentPeriod ? Colors.orange[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isPaymentPeriod ? Colors.orange[900] : Colors.blue[900],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPaymentPeriod
                          ? 'Payment period: 1st to 5th of the month'
                          : 'Next payment period: $nextPaymentDate',
                      style: TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPaymentPeriod ? Colors.orange[900] : Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24, thickness: 1),
            _buildSummaryRow(
              'Total Revenue',
              '₱ ${data['totalRevenue'].toStringAsFixed(2)}',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Your Earnings',
              '₱ ${data['dietitianEarnings'].toStringAsFixed(2)}',
              Colors.green,
            ),
            const Divider(height: 24, thickness: 1),
            _buildSummaryRow(
              'Amount You Owe',
              '₱ ${data['totalCommissionOwed'].toStringAsFixed(2)}',
              Colors.red[700]!,
              isLarge: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // onPressed: isPaymentPeriod
                //     ? () => _showPaymentDialog(data['totalCommissionOwed'])
                //     : null,
                onPressed: () => _showPaymentDialog(data['totalCommissionOwed']),
                icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                label: Text(
                  // isPaymentPeriod ? 'Pay Commission' : 'Payment Unavailable',
                  'Pay Commission',
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: isPaymentPeriod ? Colors.red[700] : Colors.grey,
                  backgroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // if (!isPaymentPeriod)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8),
            //     child: Text(
            //       'Payment can only be made between the 1st and 5th of each month',
            //       style: TextStyle(
            //         fontFamily: _primaryFontFamily,
            //         fontSize: 12,
            //         color: Colors.red[700],
            //         fontStyle: FontStyle.italic,
            //       ),
            //       textAlign: TextAlign.center,
            //     ),
            //   ),
            const SizedBox(height: 12),
            Text(
              'Total Transactions: ${data['totalTransactions']}',
              style: TextStyle(
                fontFamily: _primaryFontFamily,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            fontSize: isLarge ? 18 : 16,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            fontSize: isLarge ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showPaymentDialog(double amountOwed) {
    String? uploadedReceiptUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.qr_code_2, color: _primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Pay Commission',
                  style: TextStyle(fontFamily: _primaryFontFamily),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Amount to Pay',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱ ${amountOwed.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scan QR Code to Pay',
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // QR Code Image Placeholder
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 180, color: Colors.grey[800]),
                        const SizedBox(height: 8),
                        Text(
                          'GCash / PayMaya',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upload Payment Receipt',
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Show uploaded receipt preview if exists
                  if (uploadedReceiptUrl != null) ...[
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          uploadedReceiptUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Receipt uploaded successfully',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = await _uploadPaymentReceipt();
                      if (url != null) {
                        setDialogState(() {
                          uploadedReceiptUrl = url;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: Text(
                      uploadedReceiptUrl == null ? 'Upload Receipt' : 'Change Receipt',
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (uploadedReceiptUrl != null)
                ElevatedButton.icon(
                  onPressed: () => _markAsPaid(amountOwed, uploadedReceiptUrl!),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Mark as Paid',
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _uploadPaymentReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return null;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload to Cloudinary
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dbc77ko88/image/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = 'receipts';
      request.fields['folder'] = 'Receipts';

      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final imageUrl = responseData['secure_url'];

        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        return imageUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _markAsPaid(double amount, String receiptUrl) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get dietitian details
      final dietitianDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .get();

      final dietitianData = dietitianDoc.data() as Map<String, dynamic>?;
      final dietitianName = '${dietitianData?['firstName'] ?? ''} ${dietitianData?['lastName'] ?? ''}'.trim();
      final dietitianEmail = dietitianData?['email'] ?? '';

      // Get all unpaid receipts (receipts without commissionPaid field or commissionPaid = false)
      final receiptsSnapshot = await FirebaseFirestore.instance
          .collection('receipts')
          .where('dietitianID', isEqualTo: currentUserId)
          .get();

      // Collect receipt IDs that are being paid for
      List<String> receiptIds = [];
      for (var doc in receiptsSnapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final commissionPaid = data['commissionPaid'] ?? false;

        // Only include receipts that haven't been paid and are not pending/declined
        if (!commissionPaid && status != 'pending' && status != 'declined') {
          receiptIds.add(doc.id);
        }
      }

      // Create commission payment record with receipt references
      final paymentDoc = await FirebaseFirestore.instance.collection('commissionPayments').add({
        'dietitianID': currentUserId,
        'dietitianName': dietitianName,
        'dietitianEmail': dietitianEmail,
        'amount': amount,
        'receiptImageUrl': receiptUrl,
        'status': 'pending', // pending, verified, rejected
        'paymentDate': FieldValue.serverTimestamp(),
        'submittedAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'GCash/PayMaya',
        'verifiedAt': null,
        'verifiedBy': null,
        'notes': '',
        'receiptIds': receiptIds, // Store which receipts this payment covers
      });

      // Mark all receipts as having commission paid (pending verification)
      final batch = FirebaseFirestore.instance.batch();
      for (String receiptId in receiptIds) {
        final receiptRef = FirebaseFirestore.instance.collection('receipts').doc(receiptId);
        batch.update(receiptRef, {
          'commissionPaid': true,
          'commissionPaymentId': paymentDoc.id, // Reference to the payment record
          'commissionPaidAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Close loading dialog
      Navigator.pop(context);
      // Close payment dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted successfully! Commission has been marked as paid.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCommissionBreakdown(Map<String, dynamic> data) {
    final planTypeCounts = data['planTypeCounts'] as Map<String, int>;
    final planTypeRevenue = data['planTypeRevenue'] as Map<String, double>;
    final planTypeCommission = data['planTypeCommission'] as Map<String, double>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: _primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Commission Breakdown',
                  style: TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            _buildPlanTypeBreakdown('Weekly', 'weekly', planTypeCounts, planTypeRevenue, planTypeCommission),
            const SizedBox(height: 16),
            _buildPlanTypeBreakdown('Monthly', 'monthly', planTypeCounts, planTypeRevenue, planTypeCommission),
            const SizedBox(height: 16),
            _buildPlanTypeBreakdown('Yearly', 'yearly', planTypeCounts, planTypeRevenue, planTypeCommission),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTypeBreakdown(
      String label,
      String planType,
      Map<String, int> counts,
      Map<String, double> revenue,
      Map<String, double> commission,
      ) {
    final count = counts[planType] ?? 0;
    final rev = revenue[planType] ?? 0.0;
    final comm = commission[planType] ?? 0.0;
    final rate = (commissionRates[planType] ?? 0.0) * 100;
    final earnings = rev - comm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label Plans',
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count transactions',
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Commission Rate: ${rate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: _primaryFontFamily,
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Revenue:',
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₱ ${rev.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Earnings:',
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₱ ${earnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commission Owed:',
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₱ ${comm.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<QueryDocumentSnapshot> docs) {
    // Filter out pending and declined transactions
    final validDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      return status != 'pending' && status != 'declined';
    }).toList();

    if (validDocs.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No completed transactions',
              style: TextStyle(
                fontFamily: _primaryFontFamily,
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: validDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _buildTransactionCard(data);
      }).toList(),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final planType = (data['planType'] ?? '').toString().toLowerCase();
    final priceString = data['planPrice'] ?? '₱ 0.00';
    final price = _parsePrice(priceString);
    final commissionRate = commissionRates[planType] ?? 0.0;
    final commission = price * commissionRate;
    final earnings = price - commission;
    final status = data['status'] ?? 'unknown';

    Timestamp? timestamp = data['timeStamp'];
    String formattedDate = 'N/A';
    if (timestamp != null) {
      formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${planType[0].toUpperCase()}${planType.substring(1)} Plan',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plan Price:',
                  style: TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  priceString,
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Earnings:',
                  style: TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '₱ ${earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 12, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commission Owed (${(commissionRate * 100).toStringAsFixed(0)}%):',
                  style: TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₱ ${commission.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}