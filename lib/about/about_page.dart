import 'package:flutter/material.dart';

// --- Styles copied from home.dart for consistency ---

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
        ? Colors.white
        : Colors.black87;

Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

// Text style helper copied from home.dart
TextStyle _getTextStyle(
    BuildContext context, {
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
    }) {
  return TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: fontSize ?? 14,
    fontWeight: fontWeight ?? FontWeight.w500,
    color: color ?? _textColorPrimary(context),
    height: height,
  );
}
// --- End of styles from home.dart ---

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the scaffold background color from home.dart
      backgroundColor: _scaffoldBgColor(context),
      body: CustomScrollView(
        slivers: [
          // Use a SliverAppBar to match the structure of home.dart
          SliverAppBar(
            backgroundColor: _scaffoldBgColor(context),
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                // Use dynamic text color
                color: _textColorPrimary(context),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "About Mama’s Recipe",
              // Use the text style helper from home.dart
              style: _getTextStyle(
                context,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          // Add padding for the content area
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildInfoCard(
                    context,
                    title: "Our Mission",
                    description:
                    "Mama's Recipe is dedicated to connecting you with professional dietitians. We believe in personalized, accessible, and expert-driven nutritional guidance to help you achieve your health and wellness goals.",
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: "What We Do",
                    description:
                    "Our app provides a seamless platform for you to find certified dietitians, book consultations and receive personalized meal plans. Whether you're managing a health condition or aiming for a healthier lifestyle, we're here to support you.",
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: "Our Commitment",
                    description:
                    "We are committed to quality and trust. All dietitians on our platform are vetted and certified. We prioritize your privacy and data security, ensuring a safe and supportive environment for your health journey.",
                  ),
                  // --- START: Added Footer ---
                  // This is the footer content you provided,
                  // adapted with dynamic colors.
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        Divider(
                          // Use dynamic secondary color
                          color: _textColorSecondary(context).withOpacity(0.5),
                          thickness: 1,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "© 2025 Mama’s Recipe",
                          style: _getTextStyle(
                            context,
                            // Use dynamic secondary color
                            color: _textColorSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4), // Added for spacing
                        Text(
                          "Developed by Tenorio, Ubana, & Virrey",
                          style: _getTextStyle(
                            context,
                            // Use dynamic secondary color
                            color: _textColorSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- END: Added Footer ---
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Updated info card to use styles from home.dart
  Widget _buildInfoCard(
      BuildContext context, {
        required String title,
        required String description,
      }) {
    return Container(
      decoration: BoxDecoration(
        // Use the card background color from home.dart
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(16), // Matching home.dart cards
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null, // No shadow in dark mode
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.info_outline,
                    color: _primaryColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  // Use the text style helper
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            // Use the text style helper with secondary color
            style: _getTextStyle(
              context,
              fontSize: 15,
              height: 1.6,
              color: _textColorSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

