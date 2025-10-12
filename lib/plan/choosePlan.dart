import 'package:flutter/material.dart';
import 'payment.dart';

class ChoosePlanPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1B8C53);
    const String fontFamily = 'Poppins';

    // ✅ Plan button widget
    Widget _planButton(String label, String price) {
      return Expanded(
        child: InkWell(
          onTap: () {
            // 👇 Navigate to the next page, passing data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  planType: label,
                  planPrice: price,
                  dietitianName: dietitianName,
                  dietitianEmail: dietitianEmail,
                  dietitianProfile: dietitianProfile,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Feature box (unchanged)
    Widget _featureBox(String text) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose a Plan',
          style: TextStyle(
            fontFamily: fontFamily,
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
                color: primaryColor,
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
                            fontFamily: fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Gain more access to approved meal plans of dietitians",
                          style: TextStyle(
                            fontFamily: fontFamily,
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

            // Plan Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _planButton('Monthly', '₱ 250.00'),
                _planButton('Yearly', '₱ 2,999.00'),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "What you can do with premium:",
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            _featureBox("View all premium dietitian meal plans"),
            const SizedBox(height: 10),
            _featureBox("Access exclusive meal recommendations"),
          ],
        ),
      ),
    );
  }
}
