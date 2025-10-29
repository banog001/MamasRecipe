import 'package:flutter/material.dart';
import 'login.dart';
import 'termsAndConditions.dart';
const String termsAndConditions = """
TERMS AND CONDITIONS FOR MAMA'S RECIPE

Effective Date: May 25, 2025

Welcome to Mama's Recipe, a Personalized and Customizable Meal Planner and Dietitian Advisory Application. By accessing or using our services, you agree to be bound by these Terms and Conditions.


1. ACCEPTANCE OF TERMS

By clicking "I Agree" or by accessing and using the Mama's Recipe application, you agree to be bound by these Terms and Conditions, all applicable laws, and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this app.

2. SERVICE DESCRIPTION

Mama's Recipe provides personalized meal planning tools, personalized meal customization features, and a platform to connect users with independent dietitians for advisory services and personalized meal plan creation.

3. HEALTH AND MEDICAL DISCLAIMER (CRUCIAL)

⚠️ MAMA'S RECIPE IS NOT A MEDICAL PROVIDER.

Always seek the advice of a physician or other qualified health provider with any questions you may have regarding a medical condition or before making changes to your diet, health regimen, or exercise routine.

The dietitians available on our platform are independent professionals. While we facilitate the connection, Mama's Recipe is not responsible for the advice or services they provide. You acknowledge that you are using their services at your own risk.

4. USER OBLIGATIONS AND CONDUCT

• You are responsible for maintaining the confidentiality of your account.
• You agree not to use the service for any unlawful purposes or to share harmful, defamatory, or misleading content.

5. INTELLECTUAL PROPERTY

• All content, including core recipes, application design, text, graphics, and underlying software, are the exclusive property of Mama's Recipe or its licensors and are protected by copyright.
• You may not reproduce, duplicate, copy, sell, or exploit any portion of the service without express written permission.

6. PAYMENTS AND SUBSCRIPTIONS

• Dietitian advisory and certain premium meal planning features may require payment or a subscription.
• All fees are non-refundable. We reserve the right to change our pricing at any time.

7. TERMINATION

We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including, without limitation, if you breach these Terms and Conditions.

8. GOVERNING LAW

These Terms shall be governed by the laws of the Philippines, without regard to its conflict of law provisions.
""";

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _primaryColor;
    final Color textColorPrimary = _textColorPrimary(context);
    final Color textColorSecondary = _textColorSecondary(context);
    final Color cardBgColor = _cardBgColor(context);
    final Color scaffoldBgColor = _scaffoldBgColor(context);

    return Container(
      color: scaffoldBgColor,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      child: Column(
        children: [
          // Premium Header with Gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.85),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Terms & Conditions',
                              style: _getTextStyle(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Mama\'s Recipe Platform',
                              style: _getTextStyle(
                                context,
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 24,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content with Enhanced Styling
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formatted T&C Content
                  SelectableText.rich(
                    TextSpan(
                      children: _buildFormattedContent(context, textColorPrimary, textColorSecondary, primaryColor),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Box at the end
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      border: 1.0.border(color: primaryColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'By continuing to use the application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                            style: _getTextStyle(
                              context,
                              fontSize: 13,
                              color: textColorSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Premium Footer with Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBgColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.4),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'I Understand',
                    style: _getTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildFormattedContent(
      BuildContext context,
      Color textColorPrimary,
      Color textColorSecondary,
      Color primaryColor,
      ) {
    final lines = termsAndConditions.split('\n');
    final spans = <TextSpan>[];

    for (final line in lines) {
      if (line.isEmpty) {
        spans.add(TextSpan(text: '\n', style: _getTextStyle(context, height: 0.5)));
      } else if (line.contains('━━━')) {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: _getTextStyle(
              context,
              fontSize: 12,
              color: primaryColor.withOpacity(0.3),
            ),
          ),
        );
      } else if (line.startsWith(RegExp(r'^\d+\.'))) {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: _getTextStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              height: 1.6,
            ),
          ),
        );
      } else if (line.startsWith('•')) {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: _getTextStyle(
              context,
              fontSize: 14,
              color: textColorSecondary,
              height: 1.5,
            ),
          ),
        );
      } else if (line.contains('⚠️')) {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: _getTextStyle(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
              height: 1.5,
            ),
          ),
        );
      } else if (line.contains('MAMA\'S RECIPE IS NOT A MEDICAL PROVIDER')) {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: _getTextStyle(
              context,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade400,
              height: 1.5,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: _getTextStyle(
              context,
              fontSize: 14,
              color: textColorPrimary,
              height: 1.5,
            ),
          ),
        );
      }
    }

    return spans;
  }
}

extension on double {
  border({required Color color}) {}
}

void showTermsAndConditions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return const TermsAndConditionsScreen();
    },
  );
}

// Theme functions from login.dart
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);

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

const Color _textColorOnPrimary = Colors.white;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      double? height,
    }) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor =
      color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    height: height,
  );
}