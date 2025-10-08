import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editDietitianProfile.dart';
import 'createMealPlan.dart';
import 'homePageDietitian.dart'; // make sure this path is correct
import 'dietitianQRCode.dart'; // Added import for QR code page

class DietitianProfile extends StatefulWidget {
  const DietitianProfile({super.key});

  @override
  State<DietitianProfile> createState() => _DietitianProfileState();
}

class _DietitianProfileState extends State<DietitianProfile> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  String? qrCodeUrl;
  String firstName = '';
  String lastName = '';
  String profileUrl = '';
  int clientCount = 0;
  int plansCreatedCount = 0;
  dynamic averageRating = 'N/A';

  // --- Brand Colors ---
  static const Color _primaryColor = Color(0xFF4CAF50);
  static const Color _accentColor = Color(0xFF66BB6A);
  static const Color _textOnPrimary = Colors.white;
  static const Color _textColorOnPrimary = Colors.white;
  static const String _fontFamily = 'PlusJakartaSans';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user!.uid)
          .get();

      if (snapshot.exists && mounted) {
        final data = snapshot.data() ?? {};
        setState(() {
          // TODO: Backend - Replace 'qrCodeUrl' with your actual field name in Firestore
          qrCodeUrl = data['qrCodeUrl'] as String?;
          firstName = data['firstName'] ?? '';
          lastName = data['lastName'] ?? '';
          profileUrl = data['profile'] ?? user?.photoURL ?? '';
          clientCount = data['clientCount'] ?? 0;
          plansCreatedCount = data['plansCreatedCount'] ?? 0;
          averageRating = data['averageRating'] ?? 'N/A';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? _textColorPrimary(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _scaffoldBgColor(context);
    final Color cardColor = _cardBgColor(context);
    final Color textPrimary = _textColorPrimary(context);
    final Color textSecondary = _textColorSecondary(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    final String fullName = (firstName + ' ' + lastName).trim().isNotEmpty
        ? (firstName + ' ' + lastName).trim()
        : user?.displayName ?? 'Dietitian';
    final String email = user?.email ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: _getTextStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: _textColorOnPrimary),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          key: ValueKey(profileUrl), // Add key to prevent rebuilds
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: (profileUrl.isNotEmpty)
                              ? NetworkImage(profileUrl)
                              : null,
                          child: (profileUrl.isEmpty)
                              ? const Icon(
                            Icons.person_outline,
                            size: 42,
                            color: _primaryColor,
                          )
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
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const EditProfileDietitianPage(),
                                ),
                              );
                              _loadUserData(); // Refresh data
                            },
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fullName,
                    style: _getTextStyle(
                      context,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColorOnPrimary,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        color: _textColorOnPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],

                  if (qrCodeUrl != null && qrCodeUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DietitianQRCodePage(),
                          ),
                        );
                        _loadUserData(); // Refresh data
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "My QR Code",
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                qrCodeUrl!,
                                key: ValueKey(qrCodeUrl), // Add key to prevent rebuilds
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                cacheWidth: 100, // Further reduced cache size
                                cacheHeight: 100,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.low,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: _primaryColor,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_2_outlined,
                                      size: 40,
                                      color: _primaryColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Tap to view full size",
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Professional Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Professional Summary",
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem(Icons.group_outlined, "Clients",
                              clientCount.toString(), textPrimary),
                          _summaryItem(Icons.article_outlined, "Plans Created",
                              plansCreatedCount.toString(), textPrimary),
                          _summaryItem(Icons.star_border_outlined, "Rating",
                              averageRating.toString(), textPrimary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dietitian Tools
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dietitian Tools",
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: const Icon(Icons.qr_code_2_outlined,
                          color: _primaryColor, size: 28),
                      title: Text(
                        "My QR Code",
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        "Upload & share with clients",
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          color: textSecondary, size: 18),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DietitianQRCodePage(),
                          ),
                        );
                        _loadUserData(); // Refresh data
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: const Icon(Icons.edit_note_outlined,
                          color: _primaryColor, size: 28),
                      title: Text(
                        "Create & Manage Plans",
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          color: textSecondary, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateMealPlanPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: _primaryColor,
            selectedItemColor: Colors.white.withOpacity(0.6),
            unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (index) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePageDietitian(initialIndex: index),
                ),
              );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_calendar_outlined),
                activeIcon: Icon(Icons.edit_calendar),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mail_outline),
                activeIcon: Icon(Icons.mail),
                label: 'Messages',
              ),
            ],
<<<<<<< HEAD
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
=======
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
>>>>>>> 6f21ce8 (last na)
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
