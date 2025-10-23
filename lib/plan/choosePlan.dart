import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment.dart';
import 'package:intl/intl.dart';

// --- Theme Helpers ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade50; // Use a light grey for contrast
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

class ChoosePlanPage extends StatefulWidget {
  final String dietitianName;
  final String dietitianEmail;
  final String dietitianProfile;

  const ChoosePlanPage({
    super.key,
    required this.dietitianName,
    required this.dietitianEmail,
    required this.dietitianProfile,
  });

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage> {
  String? selectedPlanType;
  String? _dietitianId;
  bool _isLoading = true;

  double _weeklyPrice = 99.00;
  double _monthlyPrice = 250.00;
  double _yearlyPrice = 2999.00;
  final NumberFormat currencyFormatter = NumberFormat("#,##0.00", "en_US");

  Map<String, Map<String, dynamic>> get plans => {
    'weekly': {
      'name': 'Weekly Plan',
      'duration': '7 days',
      'price': _weeklyPrice,
      'displayPrice': '₱ ${currencyFormatter.format(_weeklyPrice)}',
      'durationDays': 7,
      'benefits': [
        'Access to dietitian meal plans',
        'Weekly updates',
        'Basic support',
      ],
      'icon': Icons.calendar_view_week,
      'color': Colors.blue.shade700,
    },
    'monthly': {
      'name': 'Monthly Plan',
      'duration': '30 days',
      'price': _monthlyPrice,
      'displayPrice': '₱ ${currencyFormatter.format(_monthlyPrice)}',
      'durationDays': 30,
      'benefits': [
        'Access to unlimited meal plans',
        'Monthly updates',
        'Priority support',
      ],
      'icon': Icons.calendar_view_month,
      'color': Colors.orange.shade700,
    },
    'yearly': {
      'name': 'Yearly Plan',
      'duration': '365 days',
      'price': _yearlyPrice,
      'displayPrice': '₱ ${currencyFormatter.format(_yearlyPrice)}',
      'durationDays': 365,
      'benefits': [
        'Unlimited meal plan access',
        'Weekly personalized updates',
        '24/7 premium support',
        'Save over 40% vs monthly',
      ],
      'icon': Icons.calendar_today,
      'color': Colors.purple.shade700,
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchDietitianData();
  }

  Future<void> _fetchDietitianData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: widget.dietitianEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final dietitianDoc = snapshot.docs.first;
        final data = dietitianDoc.data();

        setState(() {
          _dietitianId = dietitianDoc.id;
          _weeklyPrice = (data['weeklyPrice'] ?? 99.00).toDouble();
          _monthlyPrice = (data['monthlyPrice'] ?? 250.00).toDouble();
          _yearlyPrice = (data['yearlyPrice'] ?? 2999.00).toDouble();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching dietitian data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        title: Text(
          'Choose a Plan',
          style: _getTextStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColorOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumCard(context),
            const SizedBox(height: 20),
            _buildDietitianInfoCard(context),
            const SizedBox(height: 24),
            Text(
              "Select a plan:",
              style: _getTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...plans.entries.map((entry) {
              return _buildPlanCard(
                  context, entry.key, entry.value);
            }).toList(),
            if (selectedPlanType != null) ...[
              const SizedBox(height: 24),
              Text(
                "What you'll get:",
                style: _getTextStyle(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...plans[selectedPlanType]!['benefits']
                  .map<Widget>((benefit) {
                return _buildBenefitRow(
                  context,
                  benefit,
                  plans[selectedPlanType]!['color'],
                );
              }).toList(),
            ],
            const SizedBox(height: 40), // Spacer for button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Go Premium",
                  style: _getTextStyle(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Gain full access to approved meal plans from your dietitian.",
                  style: _getTextStyle(
                    context,
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.workspace_premium_outlined,
            color: Colors.white.withOpacity(0.8),
            size: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildDietitianInfoCard(BuildContext context) {
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
            backgroundImage: widget.dietitianProfile.isNotEmpty
                ? NetworkImage(widget.dietitianProfile)
                : null,
            child: widget.dietitianProfile.isEmpty
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dietitianName,
                  style: _getTextStyle(
                    context,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Licensed Dietitian',
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

  Widget _buildPlanCard(
      BuildContext context, String planKey, Map<String, dynamic> planData) {
    final isSelected = selectedPlanType == planKey;
    final Color color = planData['color'];

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlanType = planKey;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : _cardBgColor(context),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              planData['icon'],
              color: color,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planData['name'],
                    style: _getTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    planData['duration'],
                    style: _getTextStyle(
                      context,
                      fontSize: 13,
                      color: _textColorSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              planData['displayPrice'],
              style: _getTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(
      BuildContext context, String benefit, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: _getTextStyle(
                context,
                fontSize: 14,
                color: _textColorSecondary(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
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
          onPressed: selectedPlanType == null ? null : _proceedToPayment,
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
          child: Text(
            selectedPlanType == null
                ? 'Select a plan to continue'
                : 'Proceed to Payment',
            style: _getTextStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: selectedPlanType == null
                  ? Colors.grey.shade500
                  : _textColorOnPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _proceedToPayment() {
    if (selectedPlanType == null || _dietitianId == null) return;

    final planData = plans[selectedPlanType]!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          planType: selectedPlanType!,
          planPrice: planData['displayPrice'],
          dietitianName: widget.dietitianName,
          dietitianEmail: widget.dietitianEmail,
          dietitianProfile: widget.dietitianProfile,
          dietitianId: _dietitianId!,
          priceAmount: planData['price'],
          durationDays: planData['durationDays'],
        ),
      ),
    );
  }
}