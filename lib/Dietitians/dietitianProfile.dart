import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editDietitianProfile.dart';
import 'createMealPlan.dart';
import 'homePageDietitian.dart';
import 'dietitianQRCode.dart';
import 'dietitianSubscriberPage.dart';
import 'app_theme.dart';
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFF4CAF50);
const Color textColorOnPrimary = Colors.white;

Color inputFillColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200;

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

    Widget _buildProfileBackground(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final shapeColor =
      isDark ? primaryColor.withOpacity(0.08) : primaryColor.withOpacity(0.05);

      return Positioned.fill(
        child: Container(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 80,
                right: -150,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -120,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(
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
          body: Stack(
            children: [
              _buildProfileBackground(context),
              SingleChildScrollView(
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
                                  border:
                                  Border.all(color: Colors.white, width: 3),
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
                                  elevation: 1,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                          const EditProfileDietitianPage(),
                                        ),
                                      ).then((_) {
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "About",
                            style: getTextStyle(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: FutureBuilder<Map<String, dynamic>?>(
                              future: _getUserData(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                        color: primaryColor),
                                  );
                                }

                                final bio = snapshot.data?['bio'] as String? ??
                                    'No bio added yet';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.info_outlined,
                                            color: primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Bio",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      bio,
                                      style: getTextStyle(
                                        context,
                                        fontSize: 14,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
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
                          Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                FutureBuilder<int>(
                                  future: _getSubscriberCount(),
                                  builder: (context, snapshot) {
                                    return Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.group_outlined,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Subscribers",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          snapshot.data?.toString() ?? "0",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                Container(
                                  width: 1,
                                  height: 80,
                                  color: textSecondary.withOpacity(0.1),
                                ),
                                FutureBuilder<int>(
                                  future: _getPlansCreatedCount(),
                                  builder: (context, snapshot) {
                                    return Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.article_outlined,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Plans Created",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          snapshot.data?.toString() ?? "0",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                Container(
                                  width: 1,
                                  height: 80,
                                  color: textSecondary.withOpacity(0.1),
                                ),
                                FutureBuilder<int>(
                                  future: _getFollowersCount(),
                                  builder: (context, snapshot) {
                                    return Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.people_alt_outlined,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Followers",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          snapshot.data?.toString() ?? "0",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Service Pricing",
                            style: getTextStyle(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: InkWell(
                              onTap: () async {
                                final currentData = await _getUserData();
                                if (mounted) {
                                  await showPricingDialog(context, currentData);
                                  setState(() {});
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.attach_money_outlined,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Set Your Pricing",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Configure your consultation rates",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
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
                          Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const DietitianQRCodePage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_2_outlined,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "My QR Code",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Upload & share with clients",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const CreateMealPlanPage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.edit_note_outlined,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Create & Manage Plans",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Build new meal plans for clients",
                                          style: getTextStyle(
                                            context,
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
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
    final snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user!.uid)
        .get();
    return snapshot.data();
  }

  Future<int> _getSubscriberCount() async {
    if (user == null) return 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user!.uid)
          .collection("subscriber")
          .where("status", isNotEqualTo: "expired")
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error fetching subscriber count: $e");
      return 0;
    }
  }

  Future<int> _getPlansCreatedCount() async {
    if (user == null) return 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("mealPlans")
          .where("owner", isEqualTo: user!.uid)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error fetching plans count: $e");
      return 0;
    }
  }

  Future<int> _getFollowersCount() async {
    if (user == null) return 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user!.uid)
          .collection("followers")
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error fetching followers count: $e");
      return 0;
    }
  }

  Widget _summaryItem(
      IconData icon, String label, String value, Color textColor) {
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

class PriceHelper {
  static Future<void> checkAndApplyPendingPrices(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final priceChangeStatus = data['priceChangeStatus'];
      final effectiveDate = data['priceChangeEffectiveDate'] as Timestamp?;

      if (priceChangeStatus == 'pending' && effectiveDate != null) {
        final effectiveDateTime = effectiveDate.toDate();
        final now = DateTime.now();

        if (now.isAfter(effectiveDateTime) ||
            now.isAtSameMomentAs(effectiveDateTime)) {
          final pendingWeekly = data['pendingWeeklyPrice'];
          final pendingMonthly = data['pendingMonthlyPrice'];
          final pendingYearly = data['pendingYearlyPrice'];

          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .update({
            'weeklyPrice': pendingWeekly ?? data['weeklyPrice'],
            'monthlyPrice': pendingMonthly ?? data['monthlyPrice'],
            'yearlyPrice': pendingYearly ?? data['yearlyPrice'],
            'priceChangeStatus': 'applied',
            'lastPriceUpdate': FieldValue.serverTimestamp(),
            'pendingWeeklyPrice': FieldValue.delete(),
            'pendingMonthlyPrice': FieldValue.delete(),
            'pendingYearlyPrice': FieldValue.delete(),
            'priceChangeEffectiveDate': FieldValue.delete(),
          });

          debugPrint('✅ Pending prices applied successfully for user: $userId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking/applying pending prices: $e');
    }
  }
}

class PricingDialog extends StatefulWidget {
  final Map<String, dynamic>? currentPricing;

  const PricingDialog({super.key, this.currentPricing});

  @override
  State<PricingDialog> createState() => _PricingDialogState();
}

class _PricingDialogState extends State<PricingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _yearlyController = TextEditingController();
  bool _isSaving = false;
  bool _hasExistingPricing = false;
  bool _isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    _initializePricing();
    _checkPendingPrices();
  }

  Future<void> _checkPendingPrices() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await PriceHelper.checkAndApplyPendingPrices(userId);
    }
  }

  Future<void> _initializePricing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingPrices = false);
      return;
    }

    try {
      await PriceHelper.checkAndApplyPendingPrices(user.uid);
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        if (mounted) setState(() => _isLoadingPrices = false);
        return;
      }

      final data = userDoc.data()!;
      final weekly = data['weeklyPrice'];
      final monthly = data['monthlyPrice'];
      final yearly = data['yearlyPrice'];

      _hasExistingPricing = (weekly != null && weekly > 0) ||
          (monthly != null && monthly > 0) ||
          (yearly != null && yearly > 0);

      if (mounted) {
        setState(() {
          _weeklyController.text = weekly?.toString() ?? '';
          _monthlyController.text = monthly?.toString() ?? '';
          _yearlyController.text = yearly?.toString() ?? '';
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing pricing: $e');
      if (mounted) setState(() => _isLoadingPrices = false);
    }
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasExistingPricing) {
      final confirmed = await _showConfirmationDialog();
      if (confirmed != true) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Remove commas before parsing
      final weeklyPrice = double.tryParse(_weeklyController.text.replaceAll(',', '')) ?? 0.0;
      final monthlyPrice = double.tryParse(_monthlyController.text.replaceAll(',', '')) ?? 0.0;
      final yearlyPrice = double.tryParse(_yearlyController.text.replaceAll(',', '')) ?? 0.0;

      final effectiveDate = _calculateBusinessDays(DateTime.now(), 7);

      if (_hasExistingPricing) {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user.uid)
            .update({
          'pendingWeeklyPrice': weeklyPrice,
          'pendingMonthlyPrice': monthlyPrice,
          'pendingYearlyPrice': yearlyPrice,
          'priceChangeEffectiveDate': Timestamp.fromDate(effectiveDate),
          'priceChangeStatus': 'pending',
        });
        await _notifySubscribers(user.uid, effectiveDate);
      } else {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user.uid)
            .update({
          'weeklyPrice': weeklyPrice,
          'monthlyPrice': monthlyPrice,
          'yearlyPrice': yearlyPrice,
          'priceChangeStatus': 'active',
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hasExistingPricing
                  ? "Price change scheduled for ${_formatDate(effectiveDate)}"
                  : "Pricing updated successfully!",
            ),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating pricing: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildDialogBackground(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: cardBgColor(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -50,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -90,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              _buildDialogBackground(context),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_outlined,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Confirm Price Change",
                            style: getTextStyle(context,
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your pricing will be updated after 7 business days.",
                      style: getTextStyle(context,
                          fontSize: 14, color: textColorSecondary(context)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Effective Date: ${_formatDate(_calculateBusinessDays(DateTime.now(), 7))}",
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "All your subscribers will be notified.",
                      style: getTextStyle(context,
                          fontSize: 13, color: textColorSecondary(context)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: primaryColor.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: getTextStyle(context,
                                    color: textColorSecondary(context),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: textColorOnPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 1,
                              ),
                              child: Text(
                                "Confirm",
                                style: getTextStyle(context,
                                    color: textColorOnPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _notifySubscribers(
      String dietitianId, DateTime effectiveDate) async {
    try {
      final dietitianDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(dietitianId)
          .get();
      if (!dietitianDoc.exists) return;
      final dietitianData = dietitianDoc.data()!;
      final dietitianName =
      "${dietitianData['firstName'] ?? ''} ${dietitianData['lastName'] ?? ''}"
          .trim();
      final monthlyOld =
          (dietitianData['monthlyPrice'] as num?)?.toString() ?? 'N/A';
      final monthlyNew =
          (dietitianData['pendingMonthlyPrice'] as num?)?.toString() ??
              monthlyOld;
      final weeklyOld =
          (dietitianData['weeklyPrice'] as num?)?.toString() ?? 'N/A';
      final weeklyNew =
          (dietitianData['pendingWeeklyPrice'] as num?)?.toString() ?? weeklyOld;
      final yearlyOld =
          (dietitianData['yearlyPrice'] as num?)?.toString() ?? 'N/A';
      final yearlyNew =
          (dietitianData['pendingYearlyPrice'] as num?)?.toString() ?? yearlyOld;
      final subscribersSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(dietitianId)
          .collection('subscriber')
          .get();
      for (var subDoc in subscribersSnapshot.docs) {
        final clientId = subDoc.id;
        final notificationRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(clientId)
            .collection('notifications')
            .doc();
        await notificationRef.set({
          'isRead': false,
          'message':
          '$dietitianName has updated their pricing. New rates will be effective on ${_formatDate(effectiveDate)}.',
          'senderId': dietitianId,
          'senderName': dietitianName,
          'dietitianName': dietitianName,
          'timestamp': FieldValue.serverTimestamp(),
          'title': 'Price Change',
          'type': 'priceChange',
          'monthlyOldPrice': monthlyOld,
          'monthlyNewPrice': monthlyNew,
          'weeklyOldPrice': weeklyOld,
          'weeklyNewPrice': weeklyNew,
          'yearlyOldPrice': yearlyOld,
          'yearlyNewPrice': yearlyNew,
          'effectiveDate': effectiveDate,
        });
      }
    } catch (e) {
      debugPrint('Error notifying subscribers: $e');
    }
  }

  DateTime _calculateBusinessDays(DateTime startDate, int businessDays) {
    DateTime currentDate = startDate;
    int daysAdded = 0;
    while (daysAdded < businessDays) {
      currentDate = currentDate.add(const Duration(days: 1));
      if (currentDate.weekday != DateTime.saturday &&
          currentDate.weekday != DateTime.sunday) {
        daysAdded++;
      }
    }
    return currentDate;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  void _showPricingInfo(BuildContext context, String title, List<String> features) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            backgroundColor: cardBgColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: getTextStyle(context,
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "What's included:",
                    style: getTextStyle(context,
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                features[index],
                                style: getTextStyle(context,
                                    fontSize: 13,
                                    color: textColorSecondary(context)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Got it",
                        style: getTextStyle(context,
                            fontSize: 16,
                            color: textColorOnPrimary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
        );
      },
    );
  }

  Widget _buildPriceField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    List<String>? helpFeatures,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: getTextStyle(context,
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            if (helpFeatures != null)
              GestureDetector(
                onTap: () => _showPricingInfo(context, label, helpFeatures),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: primaryColor,
                      width: 1.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.question_mark,
                    color: primaryColor,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: getTextStyle(context),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            getTextStyle(context, color: textColorSecondary(context)),
            prefixIcon: Icon(icon, color: primaryColor),
            prefixText: "₱ ",
            prefixStyle:
            getTextStyle(context, fontWeight: FontWeight.w500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: inputFillColor(context),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a price";
            }
            final price = double.tryParse(value);
            if (price == null || price < 0) {
              return "Please enter a valid price";
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrices) {
      return Dialog(
        backgroundColor: cardBgColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading current prices...',
                style: getTextStyle(context, color: textColorSecondary(context)),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: cardBgColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.attach_money_outlined,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Set Your Pricing",
                        style: getTextStyle(context,
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: textColorSecondary(context)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _hasExistingPricing
                      ? "Update your consultation rates (7-day notice)"
                      : "Configure your consultation rates",
                  style: getTextStyle(context,
                      fontSize: 14, color: textColorSecondary(context)),
                ),
                const SizedBox(height: 24),
                _buildPriceField(
                  context: context,
                  controller: _weeklyController,
                  label: "Weekly Price",
                  hint: "Enter weekly rate",
                  icon: Icons.calendar_view_week_outlined,
                  helpFeatures: [
                    'Receive one (1) 7-day meal plan, personalized by your dietitian.',
                    'Specialized messaging support: Ask specific questions about your personalized meal plan.',
                    'Get tailored answers based on your personal preferences and health goals.',
                    'View and download all previous meal plans posted by this dietitian.',
                    'Full access to view and schedule your personalized meal plan in the calendar section.',
                    'Download your meal plan as a PDF for offline viewing.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildPriceField(
                  context: context,
                  controller: _monthlyController,
                  label: "Monthly Price",
                  hint: "Enter monthly rate",
                  icon: Icons.calendar_month_outlined,
                  helpFeatures: [
                    'Receive four (4) customized meal plans throughout the month.',
                    'Priority messaging support for your dietary questions and concerns.',
                    'Personalized nutrition guidance based on your specific health goals.',
                    'Unlimited access to the complete plan library.',
                    'Advanced calendar scheduling with meal plan tracking.',
                    'Download all your meal plans as PDFs anytime.',
                    'Better value compared to weekly pricing.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildPriceField(
                  context: context,
                  controller: _yearlyController,
                  label: "Yearly Price",
                  hint: "Enter yearly rate",
                  icon: Icons.calendar_today_outlined,
                  helpFeatures: [
                    'Receive fifty-two (52) personalized meal plans throughout the year.',
                    'Premium messaging support with priority response times.',
                    'Comprehensive nutrition coaching and lifestyle guidance.',
                    'Full unlimited access to the dietitian\'s plan library.',
                    'Complete calendar management and meal plan organization.',
                    'Batch download all yearly plans as PDFs.',
                    'Best value offering - save more with annual commitment.',
                    'Consistent relationship with your dedicated dietitian.',
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: primaryColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            "Cancel",
                            style: getTextStyle(context,
                                fontSize: 16,
                                color: textColorSecondary(context),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _savePricing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: textColorOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 1,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            "Save",
                            style: getTextStyle(context,
                                fontSize: 16,
                                color: textColorOnPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPricingDialog(
    BuildContext context, Map<String, dynamic>? currentPricing) async {
  await showDialog(
    context: context,
    builder: (dialogContext) => PricingDialog(currentPricing: currentPricing),
  );
}