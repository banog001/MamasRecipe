import 'package:flutter/material.dart';

// Import necessary styling constants from login.dart to maintain the theme
// NOTE: This import assumes login.dart is in the same directory and contains
// the theme constants like _primaryColor, _getTextStyle, etc.
import 'login.dart';

/// Static content for the Terms and Conditions based on the "MAMA'S RECIPE" application
const String _termsAndConditionsContent = """
## Terms and Conditions for Mama's Recipe

**Effective Date: October 29, 2025**

Welcome to Mama’s Recipe, a Personalized and Customizable Meal Planner and Dietitian Advisory Application. By accessing or using our services, you agree to be bound by these Terms and Conditions (T&C).

---

### 1. Acceptance of Terms

By clicking "I Agree" or by accessing and using the Mama's Recipe application, you agree to be bound by these T&C, all applicable laws, and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this app.

### 2. Service Description

Mama's Recipe provides personalized meal planning tools, recipe customization features, and a platform to connect users with independent dietitians for advisory services and personalized meal plan creation.

### 3. Health and Medical Disclaimer (Crucial)

**MAMA'S RECIPE IS NOT A MEDICAL PROVIDER.**
* The content, including recipes, suggested meal plans, and nutritional information, is provided for informational purposes only. It is **not** a substitute for professional medical advice, diagnosis, or treatment.
* Always seek the advice of a physician or other qualified health provider with any questions you may have regarding a medical condition or before making changes to your diet, health regimen, or exercise routine.
* The dietitians available on our platform are independent professionals. While we facilitate the connection, Mama's Recipe is not responsible for the advice or services they provide. You acknowledge that you are using their services at your own risk.

### 4. User Obligations and Conduct

* You must be at least 18 years old to use the Dietitian Advisory services.
* You are responsible for maintaining the confidentiality of your account password.
* You agree not to use the service for any unlawful purposes or to share harmful, defamatory, or misleading content.

### 5. Intellectual Property

* All content, including the core recipes, application design, text, graphics, and underlying software, are the exclusive property of Mama's Recipe or its licensors and are protected by copyright.
* You may not reproduce, duplicate, copy, sell, or exploit any portion of the service without express written permission.

### 6. Payments and Subscriptions

* Dietitian advisory and certain premium meal planning features may require payment or a subscription.
* All fees are non-refundable unless otherwise stated in writing. We reserve the right to change our pricing at any time.

### 7. Termination

We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including, without limitation, if you breach the T&C.

### 8. Governing Law

These Terms shall be governed by the laws of the Philippines, without regard to its conflict of law provisions.

---

By continuing to use the application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.
""";

/// Themed modal screen for displaying the Terms and Conditions.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Re-accessing theme variables from login.dart for consistency
    final Color primaryColor = _primaryColor;
    final Color textColorPrimary = _textColorPrimary(context);
    final Color cardBgColor = _cardBgColor(context);

    return Container(
      // Use card background color for the modal body
      color: cardBgColor,
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // Header with the primary color theme
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mama\'s Recipe Terms and Conditions',
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColorOnPrimary, // White text on primary color
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _textColorOnPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Scrollable T&C Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: SelectableText(
                // Simple formatting to make headers bold within the text block
                _termsAndConditionsContent.replaceAll('## ', '').replaceAll('### ', '\n\n**'),
                textAlign: TextAlign.justify,
                style: _getTextStyle(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textColorPrimary,
                  height: 1.5,
                ).copyWith(
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          // Footer / Close Button Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: _textColorOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Close',
                  style: _getTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColorOnPrimary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Function to display the themed modal.
void showTermsAndConditions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Important for rounded corners on the header
    builder: (BuildContext context) {
      return const TermsAndConditionsScreen();
    },
  );
}

// Replicate essential theme functions/variables from login.dart here
// for the new T&C file to compile and access.

// --- STYLES REPLICATION FROM login.dart ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50); // The app's main green color

Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;

Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

const Color _textColorOnPrimary = Colors.white;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      double? height,
    }) {
  return TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    height: height,
  );
}
