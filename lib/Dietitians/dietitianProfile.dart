import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editDietitianProfile.dart';
import 'createMealPlan.dart';
import 'homePageDietitian.dart';
import 'dietitianQRCode.dart';
import 'dietitianSubscriberPage.dart';
import 'app_theme.dart';

class DietitianProfile extends StatefulWidget {
  const DietitianProfile({super.key});

  @override
  State<DietitianProfile> createState() => _DietitianProfileState();
}

class _DietitianProfileState extends State<DietitianProfile> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = scaffoldBgColor(context);
    final Color cardColor = cardBgColor(context);
    final Color textPrimary = textColorPrimary(context);
    final Color textSecondary = textColorSecondary(context);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final String firstName = data['firstName'] ?? '';
        final String lastName = data['lastName'] ?? '';
        final String fullName = (firstName + ' ' + lastName).trim().isNotEmpty
            ? (firstName + ' ' + lastName).trim()
            : user?.displayName ?? 'Dietitian';
        final String email = user?.email ?? '';
        final String profileUrl = data['profile'] ?? user?.photoURL ?? '';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(
              "My Profile",
              style: getTextStyle(
                context,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColorOnPrimary,
              ),
            ),
            backgroundColor: primaryColor,
            elevation: 1,
            iconTheme: const IconThemeData(color: textColorOnPrimary),
          ),
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    color: primaryColor,
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
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage: (profileUrl.isNotEmpty)
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: (profileUrl.isEmpty)
                                  ? const Icon(
                                Icons.person_outline,
                                size: 42,
                                color: primaryColor,
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const EditProfileDietitianPage(),
                                    ),
                                  ).then((_) {
                                    // Refresh profile data when returning
                                    setState(() {});
                                  });
                                },
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: primaryColor,
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
                        style: getTextStyle(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColorOnPrimary,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: getTextStyle(
                            context,
                            fontSize: 14,
                            color: textColorOnPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                      if (data['qrCodeUrl'] != null && data['qrCodeUrl']!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DietitianQRCodePage(),
                                ),
                              );
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
                                    style: getTextStyle(
                                      context,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      data['qrCodeUrl']!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      cacheWidth: 120,
                                      cacheHeight: 120,
                                      gaplessPlayback: true,
                                      filterQuality: FilterQuality.low,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: primaryColor,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_2_outlined,
                                            size: 48,
                                            color: primaryColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Tap to view full size",
                                    style: getTextStyle(
                                      context,
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Professional Summary",
                        style: getTextStyle(
                          context,
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
                                  (data["clientCount"] ?? 0).toString(), textPrimary),
                              _summaryItem(Icons.article_outlined, "Plans Created",
                                  (data["plansCreatedCount"] ?? 0).toString(), textPrimary),
                              _summaryItem(Icons.star_border_outlined, "Rating",
                                  (data["averageRating"] ?? "N/A").toString(), textPrimary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dietitian Tools",
                        style: getTextStyle(
                          context,
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
                              color: primaryColor, size: 28),
                          title: Text(
                            "My QR Code",
                            style: getTextStyle(
                              context,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            "Upload & share with clients",
                            style: getTextStyle(
                              context,
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded,
                              color: textSecondary, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DietitianQRCodePage(),
                              ),
                            );
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
                              color: primaryColor, size: 28),
                          title: Text(
                            "Create & Manage Plans",
                            style: getTextStyle(
                              context,
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
              color: primaryColor,
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
                backgroundColor: primaryColor,
                selectedItemColor: Colors.white.withOpacity(0.6),
                unselectedItemColor: textColorOnPrimary.withOpacity(0.6),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    if (user == null) return null;
    final snapshot =
    await FirebaseFirestore.instance.collection("Users").doc(user!.uid).get();

    final data = snapshot.data();
    return data;
  }

  Widget _summaryItem(IconData icon, String label, String value, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: getTextStyle(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: getTextStyle(
            context,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
