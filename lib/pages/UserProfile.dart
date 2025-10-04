import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart'; // ✅ your home.dart
import 'editProfile.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

// --- State Class ---
class _UserProfileState extends State<UserProfile> {
  // --- Style Definitions ---
  bool _isFavoritesActive = true; // default active
  static const Color _primaryBrandColor = Color(0xFF4CAF50);
  static const Color _accentBrandColor = Color(0xFF66BB6A);
  static const Color _textOnPrimaryBrandColor = Colors.white;
  static const String _primaryFontFamily = 'PlusJakartaSans';

  static const TextStyle _appBarTitleBaseStyle =
  TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, fontSize: 20);
  static const TextStyle _userNameBaseStyle =
  TextStyle(fontFamily: _primaryFontFamily, fontSize: 22, fontWeight: FontWeight.bold);
  static const TextStyle _infoCardLabelBaseStyle =
  TextStyle(fontFamily: _primaryFontFamily, fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle _infoCardValueBaseStyle =
  TextStyle(fontFamily: _primaryFontFamily, fontSize: 16, fontWeight: FontWeight.bold);
  static const TextStyle _sectionTitleBaseStyle =
  TextStyle(fontFamily: _primaryFontFamily, fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle _buttonTextBaseStyle =
  TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5);
  static const TextStyle _caloriesTextBaseStyle =
  TextStyle(fontFamily: _primaryFontFamily, fontSize: 14, fontWeight: FontWeight.w500);

  // --- BMI Formula ---
  double _calculateBMI(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // --- Fetch user data from Firestore ---
  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance.collection("Users").doc(user.uid).get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Theme colors
    final Color currentScaffoldBgColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
    final Color currentCardBgColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color currentTextColorPrimary = isDarkMode ? Colors.white70 : Colors.black87;
    final Color currentTextColorSecondary = isDarkMode ? Colors.white54 : Colors.black54;
    final Color currentPrimaryColor = _primaryBrandColor;
    final Color currentAccentColor = _accentBrandColor;
    final Color currentTextColorOnPrimary = _textOnPrimaryBrandColor;

    // Text styles
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

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: currentScaffoldBgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: currentScaffoldBgColor,
            body: const Center(child: Text("No user data found")),
          );
        }

        final data = snapshot.data!;
        final double weight = (data["currentWeight"] ?? 0).toDouble();
        final double height = (data["height"] ?? 0).toDouble();
        final double bmi = _calculateBMI(weight, height);

        final String displayName = user.displayName ?? "Unknown User";
        final String? profileUrl = snapshot.data?['profile'];

        return Scaffold(
          backgroundColor: currentScaffoldBgColor,
          appBar: AppBar(
            title: Text("My Profile", style: appBarTitleStyle),
            backgroundColor: currentPrimaryColor,
            elevation: 1,
            iconTheme: IconThemeData(color: currentTextColorOnPrimary),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // --- Profile Header ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  decoration: BoxDecoration(
                    color: currentPrimaryColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.elliptical(150, 30)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Stack(
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
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: (profileUrl == null || profileUrl.isEmpty)
                                  ? Icon(Icons.person_outline, size: 55, color: currentPrimaryColor)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const EditProfilePage()),
                                  );
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
                      if (user.email != null && user.email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(user.email!, style: userEmailStyle),
                      ]
                    ],
                  ),
                ),

                // --- Health Overview ---
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
                                    icon: Icons.monitor_weight_outlined,
                                    label: "Weight",
                                    value: "${weight.toStringAsFixed(1)} kg",
                                    labelStyle: infoCardLabelStyle,
                                    valueStyle: infoCardValueStyle,
                                    iconColor: currentPrimaryColor,
                                  ),
                                  _InfoCard(
                                    icon: Icons.height_outlined,
                                    label: "Height",
                                    value: "${height.toStringAsFixed(1)} cm",
                                    labelStyle: infoCardLabelStyle,
                                    valueStyle: infoCardValueStyle,
                                    iconColor: currentPrimaryColor,
                                  ),
                                  _InfoCard(
                                    icon: Icons.assessment_outlined,
                                    label: "BMI",
                                    value: bmi > 0 ? bmi.toStringAsFixed(1) : "--",
                                    labelStyle: infoCardLabelStyle,
                                    valueStyle: infoCardValueStyle,
                                    iconColor: currentPrimaryColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

// --- Meal Plans Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Single Main Title for the Section
                      Text("My Meal Plans", style: sectionTitleStyle),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        color: currentCardBgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Toggle Buttons Row ---
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isFavoritesActive
                                            ? currentPrimaryColor
                                            : currentCardBgColor, // Use card background for inactive
                                        foregroundColor: _isFavoritesActive
                                            ? currentTextColorOnPrimary
                                            : currentTextColorPrimary, // Use primary text for inactive
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: _isFavoritesActive
                                              ? BorderSide.none
                                              : BorderSide(color: currentPrimaryColor.withOpacity(0.5)), // Border for inactive
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        elevation: _isFavoritesActive ? 2 : 0,
                                      ),
                                      onPressed: () {
                                        if (!_isFavoritesActive) { // Only update if not already active
                                          setState(() {
                                            _isFavoritesActive = true;
                                          });
                                        }
                                      },
                                      child: Text("Favorites", style: _buttonTextBaseStyle.copyWith(
                                          color: _isFavoritesActive ? currentTextColorOnPrimary : currentPrimaryColor,
                                          fontSize: 13
                                      )),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: !_isFavoritesActive
                                            ? currentPrimaryColor
                                            : currentCardBgColor,
                                        foregroundColor: !_isFavoritesActive
                                            ? currentTextColorOnPrimary
                                            : currentTextColorPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: !_isFavoritesActive
                                              ? BorderSide.none
                                              : BorderSide(color: currentPrimaryColor.withOpacity(0.5)),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        elevation: !_isFavoritesActive ? 2 : 0,
                                      ),
                                      onPressed: () {
                                        if (_isFavoritesActive) { // Only update if not already active
                                          setState(() {
                                            _isFavoritesActive = false;
                                          });
                                        }
                                      },
                                      child: Text("My Plans", style: _buttonTextBaseStyle.copyWith(
                                          color: !_isFavoritesActive ? currentTextColorOnPrimary : currentPrimaryColor,
                                          fontSize: 13
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // --- Dynamic Content Area ---
                              // This is where you would display the actual list of meal plans
                              // based on the _isFavoritesActive state.
                              // For now, it's a placeholder.
                              Container(
                                height: 150, // Example height, adjust as needed
                                alignment: Alignment.center,
                                child: Text(
                                  _isFavoritesActive
                                      ? "Displaying Favorite Meal Plans..."
                                      : "Displaying Your Created Meal Plans...",
                                  style: _infoCardLabelBaseStyle.copyWith(color: currentTextColorSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                // TODO: Replace with a FutureBuilder/StreamBuilder to load
                                // - Favorite meal plans if _isFavoritesActive is true
                                // - User's created meal plans if _isFavoritesActive is false
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

          // --- Bottom Navigation ---
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            child: BottomNavigationBar(
              selectedItemColor: currentTextColorOnPrimary.withOpacity(0.7),
              unselectedItemColor: currentTextColorOnPrimary.withOpacity(0.7),
              backgroundColor: currentPrimaryColor,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: (index) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => home(initialIndex: index)),
                );
              },
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.edit_calendar_outlined),
                    activeIcon: Icon(Icons.edit_calendar),
                    label: 'Schedule'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Messages'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- InfoCard Widget ---
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
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
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
