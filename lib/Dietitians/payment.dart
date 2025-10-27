import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- THEME & STYLING CONSTANTS ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade100;

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
    }) {
  return TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
  );
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final _currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  static const Map<String, double> commissionRates = {
    'weekly': 0.15,
    'monthly': 0.10,
    'yearly': 0.08,
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
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: _primaryColor,
        foregroundColor: _textColorOnPrimary,
        title: Text(
          'Commission Payment',
          style: _getTextStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('User data not found', style: _getTextStyle(context, fontSize: 18)),
                ],
              ),
            );
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('receipts')
                .where('dietitianID', isEqualTo: currentUserId)
                .orderBy('timeStamp', descending: true)
                .snapshots(),
            builder: (context, receiptsSnapshot) {
              final paymentData = _getPaymentDataFromUser(
                userData,
                receiptsSnapshot.hasData ? receiptsSnapshot.data!.docs : [],
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(context, paymentData),
                    const SizedBox(height: 24),
                    _buildPaymentMetricsGrid(context, paymentData),
                    const SizedBox(height: 24),
                    _buildCommissionBreakdown(context, paymentData),
                    const SizedBox(height: 24),
                    _buildTransactionHistorySection(
                      context,
                      receiptsSnapshot.hasData ? receiptsSnapshot.data!.docs : [],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, Map<String, dynamic> paymentData) {
    final isPaymentPeriod = _isPaymentPeriod();
    final nextPaymentDate = _getNextPaymentDate();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, Color(0xFF45a049)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                        'Commission Payment',
                        style: _getTextStyle(
                          context,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textColorOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPaymentPeriod ? 'Payment period is active' : 'Next period: $nextPaymentDate',
                        style: _getTextStyle(
                          context,
                          fontSize: 13,
                          color: _textColorOnPrimary.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.payments_rounded, color: _textColorOnPrimary, size: 40),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPaymentPeriod ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isPaymentPeriod ? Icons.schedule : Icons.calendar_today,
                    size: 16,
                    color: isPaymentPeriod ? Colors.orange[900] : Colors.blue[900],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPaymentPeriod
                          ? 'Payment period: 1st to 5th of the month'
                          : 'Next payment: $nextPaymentDate',
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMetricsGrid(BuildContext context, Map<String, dynamic> paymentData) {
    final metrics = [
      {
        'value': '₱${(paymentData['totalRevenue'] as double).toStringAsFixed(0)}',        'label': 'Total Revenue',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF2196F3),
      },
      {
        'value': '₱${(paymentData['dietitianEarnings'] as double).toStringAsFixed(0)}',
        'label': 'Your Earnings',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF4CAF50),
      },
      {
        'value': '₱${(paymentData['totalCommissionOwed'] as double).toStringAsFixed(0)}',
        'label': 'Amount Due',
        'icon': FontAwesomeIcons.pesoSign,
        'color': Colors.red.shade600,
      },
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: metrics.map((metric) {
        return _buildMetricCard(
          context,
          value: metric['value'] as String,
          label: metric['label'] as String,
          icon: metric['icon'] as IconData,
          color: metric['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(
      BuildContext context, {
        required String value,
        required String label,
        required IconData icon,
        required Color color,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(label, style: _getTextStyle(context, fontSize: 11, color: _textColorSecondary(context)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCommissionBreakdown(BuildContext context, Map<String, dynamic> paymentData) {
    final planTypeCounts = paymentData['planTypeCounts'] as Map<String, int>;
    final planTypeRevenue = paymentData['planTypeRevenue'] as Map<String, double>;
    final planTypeCommission = paymentData['planTypeCommission'] as Map<String, double>;

    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.analytics_rounded, color: _primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Commission Breakdown', style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildPlanTypeBreakdown('Weekly', 'weekly', planTypeCounts, planTypeRevenue, planTypeCommission, context),
            const SizedBox(height: 16),
            _buildPlanTypeBreakdown('Monthly', 'monthly', planTypeCounts, planTypeRevenue, planTypeCommission, context),
            const SizedBox(height: 16),
            _buildPlanTypeBreakdown('Yearly', 'yearly', planTypeCounts, planTypeRevenue, planTypeCommission, context),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(paymentData['totalCommissionOwed']),
                icon: const Icon(Icons.payment_rounded, color: _textColorOnPrimary),
                label: Text('Pay Commission',
                    style: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold, color: _textColorOnPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
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
      BuildContext context,
      ) {
    final count = counts[planType] ?? 0;
    final rev = revenue[planType] ?? 0.0;
    final comm = commission[planType] ?? 0.0;
    final rate = (commissionRates[planType] ?? 0.0) * 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _scaffoldBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _textColorPrimary(context).withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label Plans', style: _getTextStyle(context, fontSize: 15, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(12)),
                child: Text('$count transaction${count != 1 ? 's' : ''}',
                    style: const TextStyle(fontFamily: _primaryFontFamily, fontSize: 11, color: _textColorOnPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDetailRow(context, 'Rate', '${rate.toStringAsFixed(0)}%', Colors.grey),
          const SizedBox(height: 8),
          _buildDetailRow(context, 'Revenue', '₱${rev.toStringAsFixed(2)}', Colors.blue),
          const SizedBox(height: 8),
          _buildDetailRow(context, 'Commission', '₱${comm.toStringAsFixed(2)}', Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _getTextStyle(context, fontSize: 13, color: _textColorSecondary(context))),
        Text(value, style: _getTextStyle(context, fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTransactionHistorySection(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.history_rounded, color: _primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Transaction History', style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTransactionList(context, docs),
      ],
    );
  }

  Widget _buildTransactionList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    final validDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      return status != 'pending' && status != 'declined';
    }).toList();

    if (validDocs.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: _cardBgColor(context), borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]),
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text('No completed transactions', style: _getTextStyle(context, fontSize: 14, color: _textColorSecondary(context))),
        ),
      );
    }

    return Column(
      children: validDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _buildTransactionCard(context, data);
      }).toList(),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> data) {
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
      formattedDate = DateFormat('MMM dd, yyyy â€¢ hh:mm a').format(timestamp.toDate());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
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
                      Text('${planType[0].toUpperCase()}${planType.substring(1)} Plan',
                          style: _getTextStyle(context, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: _getTextStyle(context, fontSize: 12, color: _textColorSecondary(context))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(fontFamily: _primaryFontFamily, fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(status))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Price', priceString, _textColorPrimary(context)),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Earnings', '₱${earnings.toStringAsFixed(2)}', Colors.green),            const SizedBox(height: 8),
            _buildDetailRow(context, 'Commission (${(commissionRate * 100).toStringAsFixed(0)}%)', '₱${commission.toStringAsFixed(2)}',                Colors.red.shade600),
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

  Map<String, dynamic> _getPaymentDataFromUser(
      Map<String, dynamic> userData,
      List<QueryDocumentSnapshot> receipts,
      ) {
    final totalRevenue = (userData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalCommission = (userData['totalCommission'] as num?)?.toDouble() ?? 0.0;
    final overallEarnings = (userData['overallEarnings'] as num?)?.toDouble() ?? 0.0;
    final weeklyCommission = (userData['weeklyCommission'] as num?)?.toDouble() ?? 0.0;
    final monthlyCommission = (userData['monthlyCommission'] as num?)?.toDouble() ?? 0.0;
    final yearlyCommission = (userData['yearlyCommission'] as num?)?.toDouble() ?? 0.0;

    int weeklyCount = 0, monthlyCount = 0, yearlyCount = 0;
    double weeklyRevenue = 0.0, monthlyRevenue = 0.0, yearlyRevenue = 0.0;

    for (var doc in receipts) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      final commissionPaid = data['commissionPaid'] ?? false;

      if (!commissionPaid && status != 'pending' && status != 'declined') {
        final planType = (data['planType'] ?? '').toString().toLowerCase();
        final priceString = data['planPrice'] ?? '₱ 0.00';
        final price = _parsePrice(priceString);

        switch (planType) {
          case 'weekly':
            weeklyCount++;
            weeklyRevenue += price;
            break;
          case 'monthly':
            monthlyCount++;
            monthlyRevenue += price;
            break;
          case 'yearly':
            yearlyCount++;
            yearlyRevenue += price;
            break;
        }
      }
    }

    final currentEarnings = totalRevenue - totalCommission;

    return {
      'totalRevenue': totalRevenue,
      'totalCommissionOwed': totalCommission,
      'dietitianEarnings': currentEarnings,
      'overallEarnings': overallEarnings,
      'totalTransactions': weeklyCount + monthlyCount + yearlyCount,
      'planTypeCounts': {'weekly': weeklyCount, 'monthly': monthlyCount, 'yearly': yearlyCount},
      'planTypeRevenue': {'weekly': weeklyRevenue, 'monthly': monthlyRevenue, 'yearly': yearlyRevenue},
      'planTypeCommission': {'weekly': weeklyCommission, 'monthly': monthlyCommission, 'yearly': yearlyCommission},
    };
  }

  double _parsePrice(String priceString) {
    try {
      final cleanPrice = priceString.replaceAll('₱', '').replaceAll(',', '').replaceAll(' ', '').trim();
      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  void _showPaymentDialog(double amountOwed) {
    String? uploadedReceiptUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: _cardBgColor(context),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -50,
                            left: -80,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.06), shape: BoxShape.circle),
                            ),
                          ),
                          Positioned(
                            bottom: -60,
                            right: -90,
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.06), shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.payment_rounded, color: _primaryColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Pay Commission',
                                      style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: _scaffoldBgColor(context), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                Text('Amount to Pay', style: _getTextStyle(context, fontSize: 14, color: _textColorSecondary(context))),
                                const SizedBox(height: 8),
                                Text('₱${amountOwed.toStringAsFixed(2)}',
                                    style: TextStyle(fontFamily: _primaryFontFamily, fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red[700])),                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Scan QR Code to Pay',
                              style: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2, size: 120, color: Colors.grey[800]),
                                const SizedBox(height: 8),
                                Text('GCash / PayMaya',
                                    style: _getTextStyle(context, fontSize: 14, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Upload Payment Receipt',
                              style: _getTextStyle(context, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          if (uploadedReceiptUrl != null) ...[
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green, width: 2)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(uploadedReceiptUrl!, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey[400]))),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text('Receipt uploaded successfully',
                                    style: _getTextStyle(context, color: Colors.green, fontWeight: FontWeight.w600)),
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
                            icon: const Icon(Icons.upload_file, color: _textColorOnPrimary),
                            label: Text(
                              uploadedReceiptUrl == null ? 'Upload Receipt' : 'Change Receipt',
                              style: const TextStyle(fontFamily: _primaryFontFamily, color: _textColorOnPrimary),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ),
                              if (uploadedReceiptUrl != null)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _markAsPaid(amountOwed, uploadedReceiptUrl!),
                                    icon: const Icon(Icons.check, color: _textColorOnPrimary),
                                    label: const Text('Mark as Paid',
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                          color: _textColorOnPrimary,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                            ],
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
      ),
    );
  }

  Future<String?> _uploadPaymentReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return null;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

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

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt uploaded successfully!'), backgroundColor: Colors.green),
        );

        return imageUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading receipt: $e'), backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<void> _markAsPaid(double amount, String receiptUrl) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final dietitianDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();

      final dietitianData = dietitianDoc.data() as Map<String, dynamic>?;
      final dietitianName = '${dietitianData?['firstName'] ?? ''} ${dietitianData?['lastName'] ?? ''}'.trim();
      final dietitianEmail = dietitianData?['email'] ?? '';

      final receiptsSnapshot = await FirebaseFirestore.instance
          .collection('receipts')
          .where('dietitianID', isEqualTo: currentUserId)
          .get();

      List<String> receiptIds = [];
      double weeklyComm = 0.0, monthlyComm = 0.0, yearlyComm = 0.0;
      double totalRevenue = 0.0, totalEarnings = 0.0;

      for (var doc in receiptsSnapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final commissionPaid = data['commissionPaid'] ?? false;

        if (!commissionPaid && status != 'pending' && status != 'declined') {
          receiptIds.add(doc.id);

          final planType = (data['planType'] ?? '').toString().toLowerCase();
          final priceString = data['planPrice'] ?? '₱ 0.00';
          final price = _parsePrice(priceString);

          totalRevenue += price;

          if (commissionRates.containsKey(planType)) {
            final commission = price * commissionRates[planType]!;
            final earnings = price - commission;

            totalEarnings += earnings;

            switch (planType) {
              case 'weekly':
                weeklyComm += commission;
                break;
              case 'monthly':
                monthlyComm += commission;
                break;
              case 'yearly':
                yearlyComm += commission;
                break;
            }
          }
        }
      }

      final paymentDoc = await FirebaseFirestore.instance.collection('commissionPayments').add({
        'dietitianID': currentUserId,
        'dietitianName': dietitianName,
        'dietitianEmail': dietitianEmail,
        'amount': amount,
        'totalRevenue': totalRevenue,
        'totalEarnings': totalEarnings,
        'receiptImageUrl': receiptUrl,
        'status': 'pending',
        'paymentDate': FieldValue.serverTimestamp(),
        'submittedAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'GCash/PayMaya',
        'verifiedAt': null,
        'verifiedBy': null,
        'notes': '',
        'receiptIds': receiptIds,
        'weeklyCommission': weeklyComm,
        'monthlyCommission': monthlyComm,
        'yearlyCommission': yearlyComm,
      });

      final batch = FirebaseFirestore.instance.batch();
      for (String receiptId in receiptIds) {
        final receiptRef = FirebaseFirestore.instance.collection('receipts').doc(receiptId);
        batch.update(receiptRef, {
          'commissionPaid': true,
          'commissionPaymentId': paymentDoc.id,
          'commissionPaidAt': FieldValue.serverTimestamp(),
        });
      }

      final userRef = FirebaseFirestore.instance.collection('Users').doc(currentUserId);
      batch.set(
        userRef,
        {
          'totalCommission': 0,
          'weeklyCommission': 0,
          'monthlyCommission': 0,
          'yearlyCommission': 0,
          'totalRevenue': 0,
          'totalEarnings': 0,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted successfully! Commission has been reset.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting payment: $e'), backgroundColor: Colors.red),
      );
    }
  }
}