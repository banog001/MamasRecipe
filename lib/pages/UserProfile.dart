import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'editProfile.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isFavoritesActive = true;

  // Matching home.dart design system
  static const String _primaryFontFamily = 'PlusJakartaSans';
  static const Color _primaryColor = Color(0xFF4CAF50);
  static const Color _accentColor = Color(0xFF66BB6A);
  static const Color _textColorOnPrimary = Colors.white;

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
      fontFamily: _primaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? _textColorPrimary(context),
    );
  }

  double _calculateBMI(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .get();
    return snapshot.data();
  }

  Future<List<Map<String, dynamic>>> _getFavoriteMealPlans(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get all likes for this user
      final likesSnapshot = await firestore
          .collection('likes')
          .where('userID', isEqualTo: userId)
          .get();

      if (likesSnapshot.docs.isEmpty) return [];

      final mealPlanIDs = likesSnapshot.docs.map((doc) => doc['mealPlanID'] as String).toList();
      final List<Map<String, dynamic>> mealPlans = [];

      // Get meal plan details for each liked meal plan
      for (String id in mealPlanIDs) {
        final mealPlanDoc = await firestore.collection('mealPlans').doc(id).get();
        if (mealPlanDoc.exists) {
          final planData = mealPlanDoc.data()!;
          planData['planId'] = id;

          String ownerId = planData['owner'] ?? '';
          String ownerName = 'Unknown Chef';

          if (ownerId.isNotEmpty) {
            final userDoc = await firestore.collection('Users').doc(ownerId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              ownerName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
              if (ownerName.isEmpty) ownerName = 'Unknown Chef';
            }
          }

          planData['ownerName'] = ownerName;
          mealPlans.add(planData);
        }
      }

      return mealPlans;
    } catch (e) {
      print('Error fetching favorite meal plans: $e');
      return [];
    }
  }

  Future<bool> _checkSubscriptionToDietitian(String userId, String dietitianId) async {
    if (dietitianId.isEmpty) return false;

    try {
      final firestore = FirebaseFirestore.instance;

      final subscriptionDoc = await firestore
          .collection('Users')
          .doc(userId)
          .collection('subscribeTo')
          .doc(dietitianId)
          .get();

      if (subscriptionDoc.exists) {
        final subData = subscriptionDoc.data() as Map<String, dynamic>;
        return subData['status'] == 'approved';
      }

      return false;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  TableRow _buildMealRow3(
      String label,
      dynamic value,
      dynamic time,
      bool isSubscribed,
      ) {
    final textStyle = TextStyle(
      fontSize: 14,
      fontFamily: _primaryFontFamily,
      color: Colors.black87,
    );

    final greyStyle = textStyle.copyWith(color: Colors.grey.shade600);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: greyStyle.copyWith(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            isSubscribed ? (value ?? "—") : "Locked 🔒",
            style: textStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            time ?? "—",
            style: greyStyle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        body: const Center(child: Text("No user logged in")),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _scaffoldBgColor(context),
            body: const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: _scaffoldBgColor(context),
            body: const Center(child: Text("No user data found")),
          );
        }

        final data = snapshot.data!;
        final double weight = double.tryParse(data["currentWeight"].toString()) ?? 0.0;
        final double height = double.tryParse(data["height"].toString()) ?? 0.0;
        final double bmi = _calculateBMI(weight, height);
        final String displayName = user.displayName ?? "Unknown User";
        final String? profileUrl = data['profile'];

        return Scaffold(
          backgroundColor: _scaffoldBgColor(context),
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
                // Profile Header - matching home.dart style
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
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage: (profileUrl != null &&
                                  profileUrl.isNotEmpty)
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: (profileUrl == null || profileUrl.isEmpty)
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const EditProfilePage(),
                                    ),
                                  );
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
                        displayName,
                        style: _getTextStyle(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textColorOnPrimary,
                        ),
                      ),
                      if (user.email != null && user.email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email!,
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            color: _textColorOnPrimary.withOpacity(0.8),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),

                // Health Overview - matching home.dart card style
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Health Overview",
                        style: _getTextStyle(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 3,
                        color: _cardBgColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _InfoCard(
                                icon: Icons.monitor_weight_outlined,
                                label: "Weight",
                                value: "${weight.toStringAsFixed(1)} kg",
                                context: context,
                              ),
                              _InfoCard(
                                icon: Icons.height_outlined,
                                label: "Height",
                                value: "${height.toStringAsFixed(1)} cm",
                                context: context,
                              ),
                              _InfoCard(
                                icon: Icons.assessment_outlined,
                                label: "BMI",
                                value: bmi > 0 ? bmi.toStringAsFixed(1) : "--",
                                context: context,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Meal Plans Section - matching home.dart style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Meal Plans",
                        style: _getTextStyle(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 3,
                        color: _cardBgColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isFavoritesActive
                                            ? _primaryColor
                                            : _cardBgColor(context),
                                        foregroundColor: _isFavoritesActive
                                            ? _textColorOnPrimary
                                            : _textColorPrimary(context),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          side: _isFavoritesActive
                                              ? BorderSide.none
                                              : BorderSide(
                                              color: _primaryColor
                                                  .withOpacity(0.3)),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        elevation: _isFavoritesActive ? 2 : 0,
                                      ),
                                      onPressed: () {
                                        if (!_isFavoritesActive) {
                                          setState(() {
                                            _isFavoritesActive = true;
                                          });
                                        }
                                      },
                                      child: Text(
                                        "Favorites",
                                        style: _getTextStyle(
                                          context,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _isFavoritesActive
                                              ? _textColorOnPrimary
                                              : _primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: !_isFavoritesActive
                                            ? _primaryColor
                                            : _cardBgColor(context),
                                        foregroundColor: !_isFavoritesActive
                                            ? _textColorOnPrimary
                                            : _textColorPrimary(context),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          side: !_isFavoritesActive
                                              ? BorderSide.none
                                              : BorderSide(
                                              color: _primaryColor
                                                  .withOpacity(0.3)),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        elevation: !_isFavoritesActive ? 2 : 0,
                                      ),
                                      onPressed: () {
                                        if (_isFavoritesActive) {
                                          setState(() {
                                            _isFavoritesActive = false;
                                          });
                                        }
                                      },
                                      child: Text(
                                        "My Plans",
                                        style: _getTextStyle(
                                          context,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: !_isFavoritesActive
                                              ? _textColorOnPrimary
                                              : _primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isFavoritesActive)
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _getFavoriteMealPlans(user.uid),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(color: _primaryColor),
                                      );
                                    }

                                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return Container(
                                        height: 120,
                                        alignment: Alignment.center,
                                        child: Text(
                                          "No favorite meal plans yet",
                                          style: _getTextStyle(
                                            context,
                                            fontSize: 14,
                                            color: _textColorSecondary(context),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }

                                    final mealPlans = snapshot.data!;

                                    return Column(
                                      children: mealPlans.map((plan) {
                                        final dietitianId = plan['owner'] ?? '';

                                        return FutureBuilder<bool>(
                                          future: _checkSubscriptionToDietitian(user.uid, dietitianId),
                                          builder: (context, subSnapshot) {
                                            bool isSubscribed = subSnapshot.data ?? false;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 8.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "Dietitian name: ${plan['ownerName'] ?? 'Unknown'}",
                                                        style: _getTextStyle(context, fontSize: 14, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "Meal plan type: ${plan['planType'] ?? 'N/A'}",
                                                        style: _getTextStyle(context, fontSize: 13),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Table(
                                                  columnWidths: const {
                                                    0: FlexColumnWidth(1.5),
                                                    1: FlexColumnWidth(2.5),
                                                    2: FlexColumnWidth(1.2),
                                                  },
                                                  border: TableBorder.symmetric(
                                                    inside: BorderSide(color: Colors.grey.shade300),
                                                  ),
                                                  children: [
                                                    _buildMealRow3("Breakfast", plan['breakfast'], plan['breakfastTime'], true),
                                                    _buildMealRow3("AM Snack", plan['amSnack'], plan['amSnackTime'], isSubscribed),
                                                    _buildMealRow3("Lunch", plan['lunch'], plan['lunchTime'], isSubscribed),
                                                    _buildMealRow3("PM Snack", plan['pmSnack'], plan['pmSnackTime'], isSubscribed),
                                                    _buildMealRow3("Dinner", plan['dinner'], plan['dinnerTime'], isSubscribed),
                                                    _buildMealRow3("Midnight Snack", plan['midnightSnack'], plan['midnightSnackTime'], isSubscribed),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            );
                                          },
                                        );
                                      }).toList(),
                                    );
                                  },
                                )
                              else
                                Container(
                                  height: 120,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Your created meal plans will appear here",
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 14,
                                      color: _textColorSecondary(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
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
                      builder: (_) => home(initialIndex: index),
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
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BuildContext context;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}