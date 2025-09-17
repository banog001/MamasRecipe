import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // ✅ import your home.dart

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  // --- Style Definitions from your "Second UserProfile" ---
  static const Color _primaryBrandColor = Color(0xFF4CAF50); // Theme green
  static const Color _accentBrandColor = Color(0xFF66BB6A);
  static const Color _textOnPrimaryBrandColor = Colors.white;
  static const String _primaryFontFamily = 'PlusJakartaSans';

  static const TextStyle _appBarTitleBaseStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );
  static const TextStyle _userNameBaseStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle _infoCardLabelBaseStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13, // Adjusted from original 14 for the new card style
    fontWeight: FontWeight.w500,
  );
  static const TextStyle _infoCardValueBaseStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16, // Was 14, making it bolder for the new card style
    fontWeight: FontWeight.bold,
  );
  static const TextStyle _sectionTitleBaseStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle _buttonTextBaseStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 14,
    letterSpacing: 0.5,
  );
  static const TextStyle _caloriesTextBaseStyle = TextStyle( // Added from second design
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  // --- End Base Style Definitions ---

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // --- Determine THEMED Colors ---
    final Color currentScaffoldBgColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
    final Color currentCardBgColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color currentTextColorPrimary = isDarkMode ? Colors.white70 : Colors.black87;
    final Color currentTextColorSecondary = isDarkMode ? Colors.white54 : Colors.black54;
    final Color currentPrimaryColor = _primaryBrandColor;
    final Color currentAccentColor = _accentBrandColor;
    final Color currentTextColorOnPrimary = _textOnPrimaryBrandColor;

    // --- Create THEMED TextStyles ---
    final TextStyle appBarTitleStyle = _appBarTitleBaseStyle.copyWith(color: currentTextColorOnPrimary);
    final TextStyle userNameStyle = _userNameBaseStyle.copyWith(color: currentTextColorOnPrimary);
    final TextStyle infoCardLabelStyle = _infoCardLabelBaseStyle.copyWith(color: currentTextColorSecondary);
    final TextStyle infoCardValueStyle = _infoCardValueBaseStyle.copyWith(color: currentTextColorPrimary);
    final TextStyle sectionTitleStyle = _sectionTitleBaseStyle.copyWith(color: currentTextColorPrimary);
    final TextStyle buttonTextStyle = _buttonTextBaseStyle.copyWith(color: currentTextColorOnPrimary);
    final TextStyle userEmailStyle = TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 14,
      color: currentTextColorOnPrimary.withOpacity(0.8),
    );
    final TextStyle caloriesTextStyle = _caloriesTextBaseStyle.copyWith(color: currentPrimaryColor);


    if (user == null) {
      return Scaffold(
        backgroundColor: currentScaffoldBgColor,
        body: const Center(child: Text("No user logged in")),
      );
    }

    // Data from your first UserProfile (or fetch dynamically if needed)
    final String displayName = user.displayName ?? "Unknown User";
    final String? photoUrl = user.photoURL;

    // Hardcoded values from your first UserProfile's _InfoCard for simplicity
    // In a real app, these would come from Firestore or another data source.
    const String weightValue = "54 kg";
    const String heightValue = "165 cm";
    const String bmiValue = "19.8";
    const String dailyCalories = "1,850 kcal";

    return Scaffold(
      backgroundColor: currentScaffoldBgColor,
      appBar: AppBar(
        title: Text("My Profile", style: appBarTitleStyle), // Changed title
        backgroundColor: currentPrimaryColor,
        elevation: 1, // Added from second design
        iconTheme: IconThemeData(color: currentTextColorOnPrimary), // Added from second design
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section from "Second UserProfile" design
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                color: currentPrimaryColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.elliptical(150, 30), // Elliptical border
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Stack( // Profile picture from "Second UserProfile"
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50, // Increased radius
                          backgroundColor: Colors.white,
                          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Icon(Icons.person_outline, size: 55, color: currentPrimaryColor) // Outline icon
                              : null,
                        ),
                      ),
                      Positioned( // Edit button from "Second UserProfile"
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Edit profile picture tapped!"))
                              );
                              // TODO: Implement actual edit profile picture logic
                            },
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(Icons.edit_outlined, size: 20, color: currentPrimaryColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(displayName, style: userNameStyle),
                  if (user.email != null && user.email!.isNotEmpty) ...[ // Display email if available
                    const SizedBox(height: 4),
                    Text(user.email!, style: userEmailStyle),
                  ]
                ],
              ),
            ),

            // Health Overview section (Weight, Height, BMI) - styled like "Second UserProfile"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Health Overview", style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: currentCardBgColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _InfoCard(
                                icon: Icons.monitor_weight_outlined, // Updated icon
                                label: "Weight",
                                value: weightValue, // From first UserProfile data
                                labelStyle: infoCardLabelStyle,
                                valueStyle: infoCardValueStyle,
                                iconColor: currentPrimaryColor,
                              ),
                              _InfoCard(
                                icon: Icons.height_outlined, // Updated icon
                                label: "Height",
                                value: heightValue, // From first UserProfile data
                                labelStyle: infoCardLabelStyle,
                                valueStyle: infoCardValueStyle,
                                iconColor: currentPrimaryColor,
                              ),
                              _InfoCard(
                                icon: Icons.assessment_outlined, // Updated icon (BMI could use this or fitness_center)
                                label: "BMI",
                                value: bmiValue, // From first UserProfile data
                                labelStyle: infoCardLabelStyle,
                                valueStyle: infoCardValueStyle,
                                iconColor: currentPrimaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row( // Daily Calories from "Second UserProfile"
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_fire_department_outlined, color: currentPrimaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text("Daily Calories Needed:", style: infoCardLabelStyle), // Use themed label style
                              const SizedBox(width: 6),
                              Text(dailyCalories, style: caloriesTextStyle), // Use themed calorie style
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Favorites section (Button from first, Text from second for consistency)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Meal Plans", style: sectionTitleStyle), // Title from second design
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: currentCardBgColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              "Favorites & Saved", // Text from second design
                              style: _sectionTitleBaseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: currentTextColorPrimary)
                          ),
                          ElevatedButton.icon( // Button from second design, action from first if needed
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentAccentColor, // Use accent for button
                              foregroundColor: currentTextColorOnPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: () {
                              // TODO: Implement your "My Meal Plan" navigation or action
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("View My Meal Plan tapped!"))
                              );
                            },
                            icon: const Icon(Icons.restaurant_menu_outlined, size: 18),
                            label: Text("View Plans", style: buttonTextStyle),
                          ),
                        ],
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

      // ✅ Bottom nav from your first UserProfile (functionality preserved)
      //    Styled like the second UserProfile
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          selectedItemColor: currentTextColorOnPrimary, // Themed
          unselectedItemColor: currentTextColorOnPrimary.withOpacity(0.7), // Themed
          backgroundColor: currentPrimaryColor, // Themed
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            // Your existing navigation logic from the first UserProfile
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => home(initialIndex: index),
              ),
            );
          },
          items: const [ // Using outlined icons for consistency with second design's style
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_calendar_outlined), activeIcon: Icon(Icons.edit_calendar), label: 'Schedule'),
            BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Messages'),
          ],
        ),
      ),
    );
  }
}

// _InfoCard from your "Second UserProfile" - it takes styles as parameters
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final Color iconColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded( // Added Expanded to ensure cards take equal space if in a Row
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: labelStyle, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: valueStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

