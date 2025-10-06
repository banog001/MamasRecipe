import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'createMealPlan.dart';
import 'editDietitianProfile.dart';// Ensure this path is correct

// Note: No need to import HomePageDietitian here anymore if it's just content for a tab

class DietitianProfile extends StatefulWidget {
  const DietitianProfile({super.key});

  @override
  State<DietitianProfile> createState() => _DietitianProfileState();
}

class _DietitianProfileState extends State<DietitianProfile> {
  // --- Style Definitions (Can be shared or defined locally if specific adjustments are needed) ---
  static const Color _primaryBrandColor = Color(0xFF4CAF50);
  static const Color _accentBrandColor = Color(0xFF66BB6A);
  static const Color _textOnPrimaryBrandColor = Colors.white; // Used for text on primary color elements
  static const String _primaryFontFamily = 'PlusJakartaSans';

  // Base text styles (can be part of a shared theme)
  // static const TextStyle _appBarTitleBaseStyle = TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, fontSize: 20); // No longer needed here
  static const TextStyle _userNameBaseStyle = TextStyle(fontFamily: _primaryFontFamily, fontSize: 22, fontWeight: FontWeight.bold);
  static const TextStyle _infoCardLabelBaseStyle = TextStyle(fontFamily: _primaryFontFamily, fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle _infoCardValueBaseStyle = TextStyle(fontFamily: _primaryFontFamily, fontSize: 16, fontWeight: FontWeight.bold);
  static const TextStyle _sectionTitleBaseStyle = TextStyle(fontFamily: _primaryFontFamily, fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle _buttonTextBaseStyle = TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5);
  // static const TextStyle _caloriesTextBaseStyle = TextStyle(fontFamily: _primaryFontFamily, fontSize: 14, fontWeight: FontWeight.w500);

  double _calculateBMI(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

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

    if (user == null) {
      return Container(
        color: currentScaffoldBgColor,
        child: Center(child: Text("No user logged in", style: TextStyle(fontFamily: _primaryFontFamily, color: currentTextColorPrimary))),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: currentScaffoldBgColor,
            child: const Center(child: CircularProgressIndicator(color: _primaryBrandColor)),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color: currentScaffoldBgColor,
            child: Center(child: Text("Error: ${snapshot.error}", style: TextStyle(fontFamily: _primaryFontFamily, color: currentTextColorPrimary))),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            color: currentScaffoldBgColor,
            child: Center(child: Text("No user data found", style: TextStyle(fontFamily: _primaryFontFamily, color: currentTextColorPrimary))),
          );
        }

        final data = snapshot.data!;
        final String firestoreFirstName = data['firstName'] ?? '';
        final String firestoreLastName = data['lastName'] ?? '';
        final String displayName = (firestoreFirstName.isNotEmpty || firestoreLastName.isNotEmpty)
            ? '$firestoreFirstName $firestoreLastName'.trim()
            : user.displayName ?? "Dietitian User";
        final String? photoUrl = data['profile'] ?? user.photoURL;

        // The main content of the profile page, now without its own Scaffold or AppBar.
        // It will be displayed as the body of the HomePageDietitian's Scaffold.
        return Container(
          color: currentScaffoldBgColor, // Background for the tab's content area
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // --- Profile Header ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 30), // Added some top padding
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
                              radius: 55,
                              backgroundColor: Colors.white,
                              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? Icon(Icons.health_and_safety_outlined, size: 60, color: currentPrimaryColor)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 3,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const EditProfileDietitianPage(),
                                    ),
                                  );
                                },
                                customBorder: const CircleBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.all(7.0),
                                  child: Icon(Icons.edit_outlined, size: 22, color: currentPrimaryColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(displayName, style: userNameStyle.copyWith(fontSize: 24)),
                      if (user.email != null && user.email!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(user.email!, style: userEmailStyle),
                      ],
                    ],
                  ),
                ),

                // --- Professional Summary ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Professional Summary", style: sectionTitleStyle),
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
                                    icon: Icons.group_outlined,
                                    label: "Clients",
                                    value: (data["clientCount"] ?? 0).toString(),
                                    labelStyle: infoCardLabelStyle,
                                    valueStyle: infoCardValueStyle,
                                    iconColor: currentPrimaryColor,
                                  ),
                                  _InfoCard(
                                    icon: Icons.article_outlined,
                                    label: "Plans Created",
                                    value: (data["plansCreatedCount"] ?? 0).toString(),
                                    labelStyle: infoCardLabelStyle,
                                    valueStyle: infoCardValueStyle,
                                    iconColor: currentPrimaryColor,
                                  ),
                                  _InfoCard(
                                    icon: Icons.star_border_outlined,
                                    label: "Rating",
                                    value: (data["averageRating"] ?? "N/A").toString(),
                                    labelStyle: infoCardLabelStyle,
                                    valueStyle: infoCardValueStyle,
                                    iconColor: currentPrimaryColor,
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

                // --- Dietitian Tools ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dietitian Tools", style: sectionTitleStyle),
                      const SizedBox(height: 12),
                      Card(
                          elevation: 2,
                          color: currentCardBgColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Icon(Icons.edit_note_outlined, color: currentPrimaryColor, size: 28),
                            title: Text(
                              "Create & Manage Plans",
                              style: _sectionTitleBaseStyle.copyWith(
                                  fontSize: 16, fontWeight: FontWeight.w500, color: currentTextColorPrimary),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios_rounded, color: currentTextColorSecondary, size: 18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateMealPlanPage()),
                              );
                            },
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Bottom padding for scroll view
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: labelStyle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: valueStyle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
