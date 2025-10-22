import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment.dart';

const String _primaryFontFamily = 'Poppins';
const Color _primaryColor = Color(0xFF1B8C53);
const Color _textColorOnPrimary = Colors.white;

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

  // Subscription plan details with pricing matching your existing implementation
  final Map<String, Map<String, dynamic>> plans = {
    'weekly': {
      'name': 'Weekly Plan',
      'duration': '7 days',
      'price': 99.00, // ₱99.00
      'displayPrice': '₱ 99.00',
      'durationDays': 7,
      'description': 'Get access to meal plans for 7 days',
      'benefits': [
        'Access to dietitian meal plans',
        'Weekly updates',
        'Basic support',
      ],
      'icon': Icons.calendar_view_week,
      'color': Colors.blue,
    },
    'monthly': {
      'name': 'Monthly Plan',
      'duration': '30 days',
      'price': 250.00, // ₱250.00 (your existing price)
      'displayPrice': '₱ 250.00',
      'durationDays': 30,
      'description': 'Get access to meal plans for 30 days',
      'benefits': [
        'Access to unlimited meal plans',
        'Monthly updates',
        'Priority support',
      ],
      'icon': Icons.calendar_view_month,
      'color': Colors.orange,
    },
    'yearly': {
      'name': 'Yearly Plan',
      'duration': '365 days',
      'price': 2999.00, // ₱2,999.00 (your existing price)
      'displayPrice': '₱ 2,999.00',
      'durationDays': 365,
      'description': 'Get access to meal plans for full year',
      'benefits': [
        'Unlimited meal plan access',
        'Weekly personalized updates',
        '24/7 premium support',
        'Save over 40% vs monthly',
      ],
      'icon': Icons.calendar_today,
      'color': Colors.purple,
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchDietitianId();
  }

  Future<void> _fetchDietitianId() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: widget.dietitianEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _dietitianId = snapshot.docs.first.id;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching dietitian ID: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose a Plan',
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Premium",
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Gain more access to approved meal plans of dietitians",
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.asset('assets/images/salad.png'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dietitian Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dietitianName,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Licensed Dietitian',
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plan Selection
            const Text(
              "Select a plan:",
              style: TextStyle(
                fontFamily: _primaryFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Plan Cards
            ...plans.entries.map((entry) {
              final planKey = entry.key;
              final planData = entry.value;
              final isSelected = selectedPlanType == planKey;

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
                    color: isSelected
                        ? planData['color'].withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? planData['color']
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: planData['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          planData['icon'],
                          color: planData['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planData['name'],
                              style: const TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              planData['duration'],
                              style: TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            planData['displayPrice'],
                            style: TextStyle(
                              fontFamily: _primaryFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: planData['color'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            if (selectedPlanType != null) ...[
              const SizedBox(height: 20),
              const Text(
                "What you can do with premium:",
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...plans[selectedPlanType]!['benefits'].map<Widget>((benefit) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: plans[selectedPlanType]!['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 24),

            // Proceed to Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedPlanType == null ? null : _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  selectedPlanType == null
                      ? 'Select a plan to continue'
                      : 'Proceed to Payment',
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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