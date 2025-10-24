import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'dart:io';
import 'package:excel/excel.dart' hide Border; // Hide Border from excel package
import 'package:flutter/material.dart' show Border;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import '../pages/login.dart';
import 'messagesDietitian.dart';
import 'createMealPlan.dart';
import 'dietitianProfile.dart';
import '../email/appointmentEmail.dart';

import 'package:mamas_recipe/widget/custom_snackbar.dart';

import 'package:mamas_recipe/about/about_page.dart';

// --- THEME & STYLING CONSTANTS (Available to the whole file) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

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

class HomePageDietitian extends StatefulWidget {
  final int initialIndex;
  const HomePageDietitian({super.key, this.initialIndex = 0});

  @override
  State<HomePageDietitian> createState() => _HomePageDietitianState();
}

class _HomePageDietitianState extends State<HomePageDietitian> {
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  late int selectedIndex;
  String firstName = "";
  String lastName = "";
  String profileUrl = "";
  bool _isUserNameLoading = true;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _setUserStatus("online");
    _updateGooglePhotoURL();
    loadUserName();
  }

  // --- WIDGETS FOR EACH TAB ---
  List<Widget> get _pages => [
    // 0: Analytics Dashboard Page
    const AnalyticsDashboard(),
    // 1: Schedule Page
    ScheduleCalendarPage(
      dietitianFirstName: firstName,
      dietitianLastName: lastName,
      isDietitianNameLoading: _isUserNameLoading,
    ),
    // 2: Messages Page
    if (firebaseUser != null)
      UsersListPage(
        currentUserId: firebaseUser!.uid,
        onNavigateToSchedule: () {
          setState(() {
            selectedIndex = 1; // Switch to Schedule tab (index 1)
          });
        },
      ),
  ];

  // --- APP BAR TITLE LOGIC ---
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Dietitian Dashboard";
      case 1:
        return "My Schedule";
      case 2:
        return "Messages";
      default:
        return "Dietitian App";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        body: Center(
          child: Text(
            "No dietitian user logged in.",
            style: _getTextStyle(context),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: _textColorOnPrimary, size: 28),
        title: Text(
          _getAppBarTitle(selectedIndex),
          style: _getTextStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DietitianProfile()),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _primaryColor.withOpacity(0.2),
                backgroundImage: (profileUrl.isNotEmpty)
                    ? NetworkImage(profileUrl)
                    : null,
                child: (profileUrl.isEmpty)
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: _textColorOnPrimary,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: (_pages.isNotEmpty && selectedIndex < _pages.length)
            ? _pages[selectedIndex]
            : Center(
                child: Text("Page not found", style: _getTextStyle(context)),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- DRAWER WIDGET ---
  Widget _buildDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Drawer(
        backgroundColor: _cardBgColor(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: _isUserNameLoading
                  ? _buildShimmerText(120, 18)
                  : Text(
                      (firstName.isNotEmpty || lastName.isNotEmpty)
                          ? "$firstName $lastName".trim()
                          : "User Profile",
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _textColorOnPrimary,
                      ),
                    ),
              accountEmail: _isUserNameLoading
                  ? _buildShimmerText(150, 14, topMargin: 4)
                  : Text(
                      firebaseUser!.email ?? "",
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontSize: 14,
                        color: _textColorOnPrimary,
                      ),
                    ),
              currentAccountPicture: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30, color: Colors.green),
                    );
                  }
                  final profileUrl =
                      (snapshot.data!.data()
                          as Map<String, dynamic>?)?['profile'] ??
                      '';
                  return CircleAvatar(
                    backgroundImage: profileUrl.isNotEmpty
                        ? NetworkImage(profileUrl)
                        : null,
                    backgroundColor: Colors.white,
                    child: profileUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.green,
                          )
                        : null,
                  );
                },
              ),
              decoration: const BoxDecoration(color: _primaryColor),
            ),
            _buildMenuTile('My Meal Plans', Icons.list_alt_outlined),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.black87),
              title: const Text(
                'About',
                style: TextStyle(fontFamily: _primaryFontFamily),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
            _buildMenuTile('Settings', Icons.settings_outlined),
            const Divider(indent: 16, endIndent: 16),
            _buildMenuTile('Logout', Icons.logout_outlined),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM NAVIGATION BAR WIDGET ---
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: _primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => setState(() => selectedIndex = index),
          selectedItemColor: _textColorOnPrimary,
          unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
          backgroundColor: _primaryColor,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedLabelStyle: _getTextStyle(
            context,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textColorOnPrimary,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
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
    );
  }

  // --- HELPER & LOGIC METHODS ---

  Widget _buildMenuTile(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _textColorPrimary(context), size: 24),
      title: Text(
        label,
        style: _getTextStyle(
          context,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: () async {
        Navigator.pop(context);
        if (label == 'Logout') {
          bool signedOut = await signOutFromGoogle();
          if (signedOut && mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPageMobile()),
              (Route<dynamic> route) => false,
            );
          }
        }
      },
      dense: true,
    );
  }

  Widget _buildShimmerText(
    double width,
    double height, {
    double topMargin = 0,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.6),
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(top: topMargin),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  void loadUserName() async {
    setState(() {
      _isUserNameLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (mounted && doc.exists) {
          final data = doc.data()!;
          setState(() {
            firstName = data['firstName'] as String? ?? '';
            lastName = data['lastName'] as String? ?? '';
            profileUrl = data['profile'] as String? ?? '';
          });
        }
      } catch (e) {
        debugPrint("Error loading user name: $e");
      }
    }
    if (mounted) {
      setState(() {
        _isUserNameLoading = false;
      });
    }
  }

  Future<void> _updateGooglePhotoURL() async {
    if (firebaseUser == null) return;
    final userDoc = FirebaseFirestore.instance
        .collection("Users")
        .doc(firebaseUser!.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists ||
        (snapshot.data()?['profile'] as String? ?? '').isEmpty) {
      if (firebaseUser!.photoURL != null) {
        await userDoc.set({
          "profile": firebaseUser!.photoURL,
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _setUserStatus(String status) async {
    if (firebaseUser != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(firebaseUser!.uid)
          .set({"status": status}, SetOptions(merge: true));
    }
  }

  Future<bool> signOutFromGoogle() async {
    try {
      await _setUserStatus("offline");
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      debugPrint("Sign out error (Dietitian): $e");
      return false;
    }
  }

  @override
  void dispose() {
    _setUserStatus("offline");
    super.dispose();
  }
}

// --- NEW ANALYTICS DASHBOARD WIDGET ---
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  late Future<Map<String, dynamic>> _analyticsData;

  @override
  void initState() {
    super.initState();
    _analyticsData = _fetchAnalyticsData();
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final dietitianId = FirebaseAuth.instance.currentUser?.uid;
    if (dietitianId == null) return {};

    final results = await Future.wait([
      _fetchSubscriptionData(dietitianId),
      _fetchMealPlanData(dietitianId),
      _fetchAppointmentData(dietitianId),
    ]);

    return {
      'subscriptions': results[0],
      'mealPlans': results[1],
      'appointments': results[2],
    };
  }

  Future<Map<String, dynamic>> _fetchSubscriptionData(
    String dietitianId,
  ) async {
    final subscriberSnap = await FirebaseFirestore.instance
        .collection('Users')
        .doc(dietitianId)
        .collection('subscriber')
        .get();

    int activeSubscriptions = subscriberSnap.docs.length;
    int monthlySubs = 0;
    int yearlySubs = 0;
    int weeklySubs = 0;
    int newClientsThisMonth = 0;
    final now = DateTime.now();

    for (var doc in subscriberSnap.docs) {
      final data = doc.data();
      final planType = data['planType']?.toString() ?? '';

      if (planType.toLowerCase() == 'monthly') monthlySubs++;
      if (planType.toLowerCase() == 'yearly') yearlySubs++;
      if (planType.toLowerCase() == 'weekly') weeklySubs++;

      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        if (date.year == now.year && date.month == now.month) {
          newClientsThisMonth++;
        }
      }
    }

    // Fetch total revenue from receipts collection (all approved payments)
    // This calculates cumulative revenue from ALL approved receipts ever
    double totalRevenue = 0.0;
    final receiptsSnap = await FirebaseFirestore.instance
        .collection('receipts')
        .where('dietitianID', isEqualTo: dietitianId)
        .where('status')
        .get();

    for (var doc in receiptsSnap.docs) {
      final data = doc.data();
      final priceString = data['planPrice']?.toString().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      if (priceString != null && priceString.isNotEmpty) {
        totalRevenue += double.tryParse(priceString) ?? 0.0;
      }
    }

    return {
      'activeSubscriptions': activeSubscriptions,
      'monthlySubs': monthlySubs,
      'yearlySubs': yearlySubs,
      'weeklySubs': weeklySubs,
      'newClientsThisMonth': newClientsThisMonth,
      'totalRevenue': totalRevenue,
    };
  }

  Future<Map<String, dynamic>> _fetchMealPlanData(String dietitianId) async {
    final mealPlanSnap = await FirebaseFirestore.instance
        .collection('mealPlans')
        .where('owner', isEqualTo: dietitianId)
        .get();

    String mostPopularPlanName = 'N/A';
    Map<String, dynamic> mostPopularPlanData = {};
    int maxLikes = -1;

    for (var doc in mealPlanSnap.docs) {
      final data = doc.data();
      final likes = data['likeCounts'] as int? ?? 0;

      if (likes > maxLikes) {
        maxLikes = likes;
        mostPopularPlanName = data['planType'] ?? 'Unnamed Plan';
        mostPopularPlanData = data;
      }
    }

    return {
      'plansCreated': mealPlanSnap.docs.length,
      'mostPopularPlan': mostPopularPlanName,
      'mostPopularPlanData': mostPopularPlanData,
    };
  }

  Future<Map<String, dynamic>> _fetchAppointmentData(String dietitianId) async {
    final scheduleSnap = await FirebaseFirestore.instance
        .collection('schedules')
        .where('dietitianID', isEqualTo: dietitianId)
        .get();

    int appointmentsThisMonth = 0;
    final now = DateTime.now();
    final clientFrequency = <String, int>{};
    final dayFrequency = <int, int>{};

    for (var doc in scheduleSnap.docs) {
      final data = doc.data();
      final dateStr = data['appointmentDate'] as String?;
      if (dateStr != null) {
        try {
          final date = DateFormat('yyyy-MM-dd HH:mm').parse(dateStr);
          if (date.year == now.year && date.month == now.month) {
            appointmentsThisMonth++;
          }
          dayFrequency[date.weekday] = (dayFrequency[date.weekday] ?? 0) + 1;
        } catch (e) {}
      }

      final clientName = data['clientName'] as String?;
      if (clientName != null) {
        clientFrequency[clientName] = (clientFrequency[clientName] ?? 0) + 1;
      }
    }

    String mostFrequentClient = 'N/A';
    if (clientFrequency.isNotEmpty) {
      mostFrequentClient = clientFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    String busiestDay = 'N/A';
    if (dayFrequency.isNotEmpty) {
      final busiestDayIndex = dayFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      busiestDay = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][busiestDayIndex - 1];
    }

    return {
      'appointmentsThisMonth': appointmentsThisMonth,
      'mostFrequentClient': mostFrequentClient,
      'busiestDay': busiestDay,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (!snapshot.hasData || snapshot.hasError || snapshot.data!.isEmpty) {
          return const Center(child: Text("Could not load analytics."));
        }

        final data = snapshot.data!;
        final subData = data['subscriptions'] ?? {};
        final mealData = data['mealPlans'] ?? {};
        final apptData = data['appointments'] ?? {};

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Welcome Header Card
            _buildWelcomeCard(context),
            const SizedBox(height: 20),

            // Key Metrics Grid (3-column layout)
            _buildMetricsGrid(context, subData),
            const SizedBox(height: 20),

            // Client & Subscriptions Card
            _buildClientSubscriptionCard(context, subData),
            const SizedBox(height: 16),

            // Meal Plan Engagement Card
            _buildMealPlanCard(context, mealData),
            const SizedBox(height: 16),

            // Appointments & Schedule Card
            _buildAppointmentCard(context, apptData),
            const SizedBox(height: 20),

            // Quick Actions Section
            _buildQuickActionsSection(context),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, Color(0xFF45a049)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: _getTextStyle(
                          context,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textColorOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your practice is thriving. Keep it up!',
                        style: _getTextStyle(
                          context,
                          fontSize: 13,
                          color: _textColorOnPrimary.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.trending_up_rounded,
                  color: _textColorOnPrimary,
                  size: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> subData) {
    final metrics = [
      {
        'value': (subData['activeSubscriptions'] ?? 0).toString(),
        'label': 'Active Clients',
        'icon': Icons.people_rounded,
        'color': const Color(0xFF4CAF50),
      },
      {
        'value': '\₱${(subData['totalRevenue'] ?? 0.0).toStringAsFixed(0)}',
        'label': 'Total Revenue',
        'icon': Icons.monetization_on_rounded,
        'color': const Color(0xFF2196F3),
      },
      {
        'value': (subData['newClientsThisMonth'] ?? 0).toString(),
        'label': 'New This Month',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFFFF9800),
      },
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: metrics.map((metric) {
        return _buildMetricCard(
          context,
          value: metric['value'] as String,
          label: metric['label'] as String,
          icon: metric['icon'] as IconData,
          color: metric['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: _getTextStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: _getTextStyle(
              context,
              fontSize: 11,
              color: _textColorSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientSubscriptionCard(
    BuildContext context,
    Map<String, dynamic> subData,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Client & Subscriptions',
                  style: _getTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Weekly Plans',
              '${subData['weeklySubs'] ?? 0}',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Monthly Plans',
              '${subData['monthlySubs'] ?? 0}',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Yearly Plans',
              '${subData['yearlySubs'] ?? 0}',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    Color accentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: _getTextStyle(context, fontSize: 14)),
          ],
        ),
        Text(
          value,
          style: _getTextStyle(
            context,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanCard(
    BuildContext context,
    Map<String, dynamic> mealData,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F61).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFFFF6F61),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Meal Plan Engagement',
                  style: _getTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              Icons.note_add_rounded,
              'Plans Created',
              mealData['plansCreated']?.toString() ?? '0',
            ),
            const SizedBox(height: 12),
            if (mealData['mostPopularPlan'] != null &&
                mealData['mostPopularPlanData'] != null &&
                mealData['mostPopularPlanData'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: _textColorSecondary(context).withOpacity(0.3)),
                  const SizedBox(height: 12),
                  _buildPopularPlanRow(context, mealData),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween, // We don't need this
      children: [
        // Left side (icon and label)
        Expanded(
          flex: 3, // Give more space to the label
          child: Row(
            children: [
              Icon(icon, color: _primaryColor, size: 18),
              const SizedBox(width: 10),
              // Expanded allows the text to truncate
              Expanded(
                child: Text(
                  label,
                  style: _getTextStyle(context, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12), // Spacer
        // Right side (value)
        Expanded(
          flex: 2, // Give less space to the value
          child: Text(
            value,
            style: _getTextStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end, // Aligns text to the right
          ),
        ),
      ],
    );
  }

  Widget _buildPopularPlanRow(
    BuildContext context,
    Map<String, dynamic> mealData,
  ) {
    final planData = mealData['mostPopularPlanData'] as Map<String, dynamic>;

    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with like count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Most Popular Plan',
                  style: _getTextStyle(
                    context,
                    fontSize: 12,
                    color: _textColorSecondary(context),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      (planData['likeCounts'] ?? 0).toString(),
                      style: _getTextStyle(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Plan name and type
            Text(
              mealData['mostPopularPlan'] ?? 'N/A',
              style: _getTextStyle(
                context,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (planData['planType'] != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  planData['planType'],
                  style: _getTextStyle(
                    context,
                    fontSize: 11,
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Meal details
            _buildMealItem(
              context,
              'Breakfast',
              planData['breakfast'] ?? '',
              planData['breakfastTime'] ?? '',
              Icons.wb_sunny_outlined,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildMealItem(
              context,
              'AM Snack',
              planData['amSnack'] ?? '',
              planData['amSnackTime'] ?? '',
              Icons.coffee_outlined,
              Colors.brown,
            ),
            const SizedBox(height: 12),
            _buildMealItem(
              context,
              'Lunch',
              planData['lunch'] ?? '',
              planData['lunchTime'] ?? '',
              Icons.restaurant_outlined,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildMealItem(
              context,
              'PM Snack',
              planData['pmSnack'] ?? '',
              planData['pmSnackTime'] ?? '',
              Icons.local_cafe_outlined,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildMealItem(
              context,
              'Dinner',
              planData['dinner'] ?? '',
              planData['dinnerTime'] ?? '',
              Icons.nightlight_outlined,
              Colors.indigo,
            ),
            if (planData['midnightSnack'] != null &&
                planData['midnightSnack'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMealItem(
                context,
                'Midnight Snack',
                planData['midnightSnack'],
                planData['midnightSnackTime'] ?? '',
                Icons.bedtime_outlined,
                Colors.blueGrey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(
    BuildContext context,
    String mealName,
    String mealContent,
    String mealTime,
    IconData icon,
    Color iconColor,
  ) {
    // Skip if meal content is empty
    if (mealContent.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mealName,
                style: _getTextStyle(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textColorSecondary(context),
                ),
              ),
              if (mealTime.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 11,
                      color: iconColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mealTime,
                      style: _getTextStyle(
                        context,
                        fontSize: 11,
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                mealContent,
                style: _getTextStyle(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context,
      Map<String, dynamic> apptData,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        // Use 16.0 for consistency with your other cards
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF9C27B0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // --- FIX ---
                // Wrapped in Expanded to prevent overflow
                Expanded(
                  child: Text(
                    'Appointments & Schedule',
                    style: _getTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // --- END FIX ---
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              Icons.event_available_rounded,
              'This Month',
              apptData['appointmentsThisMonth']?.toString() ?? '0',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              Icons.person_rounded,
              'Most Frequent Client',
              apptData['mostFrequentClient'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              Icons.date_range_rounded,
              'Busiest Day',
              apptData['busiestDay'] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: _getTextStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const PendingSubscriptionCard(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMealPlanPage()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: _textColorOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.post_add_rounded, size: 20),
            label: Text(
              'Create a New Meal Plan',
              style: _getTextStyle(
                context,
                color: _textColorOnPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: _cardBgColor(context),
      highlightColor: _scaffoldBgColor(context),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLoadingCard(height: 120),
          const SizedBox(height: 16),
          _buildLoadingCard(height: 160),
          const SizedBox(height: 16),
          _buildLoadingCard(height: 140),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// --- ALL OTHER WIDGETS FOR THIS FILE ---

class PendingSubscriptionCard extends StatelessWidget {
  const PendingSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dietitianId = FirebaseAuth.instance.currentUser?.uid;
    if (dietitianId == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionApprovalPage(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.group_add_outlined, color: _primaryColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Subscription Requests",
                      style: _getTextStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColorPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('receipts')
                          .where('dietitianID', isEqualTo: dietitianId)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            "Loading...",
                            style: _getTextStyle(
                              context,
                              fontSize: 13,
                              color: _textColorSecondary(context),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            "No pending requests.",
                            style: _getTextStyle(
                              context,
                              fontSize: 13,
                              color: _textColorSecondary(context),
                            ),
                          );
                        }
                        final count = snapshot.data!.docs.length;
                        return Text(
                          "$count request${count == 1 ? '' : 's'} to review",
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _textColorSecondary(context),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionApprovalPage extends StatelessWidget {
  const SubscriptionApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 1,
          backgroundColor: const Color(0xFF4CAF50),
          iconTheme: const IconThemeData(color: Colors.white, size: 28),
          title: const Text(
            "Manage Subscriptions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'PlusJakartaSans',
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontFamily: 'PlusJakartaSans',
            ),
            tabs: [
              Tab(text: "Pending Requests"),
              Tab(text: "Approved History"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SubscriptionRequests(status: 'pending'),
            SubscriptionRequests(status: 'approved'),
          ],
        ),
      ),
    );
  }
}

class SubscriptionRequests extends StatefulWidget {
  final String status;
  const SubscriptionRequests({super.key, required this.status});

  @override
  State<SubscriptionRequests> createState() => _SubscriptionRequestsState();
}

class _SubscriptionRequestsState extends State<SubscriptionRequests> {
  List<Map<String, dynamic>> _receiptsCache = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoadingData = true);
    _receiptsCache = await _fetchReceiptsWithClients(widget.status);
    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchReceiptsWithClients(
    String status,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final receiptsSnap = await FirebaseFirestore.instance
        .collection('receipts')
        .where('dietitianID', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: status)
        .orderBy('timeStamp', descending: true)
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in receiptsSnap.docs) {
      final data = doc.data();
      final clientID = data['clientID'];

      final clientDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(clientID)
          .get();

      if (!clientDoc.exists) {
        continue;
      }

      final clientData = clientDoc.data() ?? {};

      // Get timestamp
      String timestampStr = '';
      if (data['timeStamp'] != null) {
        try {
          final timestamp = data['timeStamp'] as Timestamp;
          timestampStr = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(timestamp.toDate());
        } catch (e) {
          timestampStr = 'N/A';
        }
      }

      results.add({
        "docId": doc.id,
        "clientID": clientID,
        "dietitianID": data['dietitianID'],
        "firstname":
            clientData['firstname'] ?? clientData['firstName'] ?? 'N/A',
        "lastname": clientData['lastname'] ?? clientData['lastName'] ?? 'N/A',
        "email": clientData['email'] ?? 'N/A',
        "planPrice": data['planPrice'] ?? '',
        "planType": data['planType'] ?? '',
        "status": data['status'] ?? '',
        "timestamp": timestampStr,
      });
    }

    return results;
  }

  Future<void> _exportToExcel() async {
    if (_receiptsCache.isEmpty) {
      CustomSnackBar.show(
        context,
        'No data to export.',
        backgroundColor: Colors.orange,
        icon: Icons.info_outline,
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );

      // Create Excel workbook
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Approved Subscriptions'];

      // Define headers
      final headers = [
        'Client Name',
        'Email',
        'Plan Type',
        'Plan Price',
        'Status',
        'Approved Date',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          backgroundColorHex: ExcelColor.green,
          fontColorHex: ExcelColor.white,
        );
      }

      // Add data rows
      for (int i = 0; i < _receiptsCache.length; i++) {
        final receipt = _receiptsCache[i];
        final rowIndex = i + 1;

        final rowData = [
          "${receipt['firstname']} ${receipt['lastname']}",
          receipt['email'],
          receipt['planType'],
          receipt['planPrice'],
          receipt['status'],
          receipt['timestamp'],
        ];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j].toString());
        }
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 20);
      }

      // ✅ Convert to Uint8List for FlutterFileDialog
      final excelBytes = Uint8List.fromList(excel.encode()!);

      // Generate filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'approved_subscriptions_$timestamp.xlsx';

      // Save file using FlutterFileDialog
      final params = SaveFileDialogParams(fileName: fileName, data: excelBytes);

      final filePath = await FlutterFileDialog.saveFile(params: params);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (filePath != null) {
        CustomSnackBar.show(
          context,
          'Excel file saved successfully!\n$filePath',
          backgroundColor: const Color(0xFF4CAF50),
          icon: Icons.file_download_done,
          duration: const Duration(seconds: 5),
        );
      } else {
        CustomSnackBar.show(context, 'File saving was cancelled.', backgroundColor: Colors.orange, icon: Icons.cancel_outlined);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      debugPrint('Error exporting to Excel: $e');
      if (mounted) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Error exporting to Excel: $e',
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
          );
        }
      }
    }
  }

  Future<void> _approveSubscription(Map<String, dynamic> receipt) async {
    try {
      final currentDietitian = FirebaseAuth.instance.currentUser;
      if (currentDietitian == null) {
        CustomSnackBar.show(context, 'You must be logged in.', backgroundColor: Colors.redAccent, icon: Icons.lock_outline);
        return;
      }

      final receiptId = receipt['docId'];
      final clientId = receipt['clientID'];
      final dietitianId = receipt['dietitianID'];
      final planType = receipt['planType'];
      final planPrice = receipt['planPrice'];

      DateTime now = DateTime.now();
      DateTime expirationDate;

      // if (planType.toString().toLowerCase() == 'weekly') {
      //   expirationDate = now.add(const Duration(days: 7));
      if (planType.toString().toLowerCase() == 'weekly') {
        // For testing only — expires in 1 hour instead of 7 days
        expirationDate = now.add(const Duration(hours: 1));
      } else if (planType.toString().toLowerCase() == 'monthly') {
        expirationDate = DateTime(now.year, now.month + 1, now.day);
      } else if (planType.toString().toLowerCase() == 'yearly') {
        expirationDate = DateTime(now.year + 1, now.month, now.day);
      } else {
        expirationDate = DateTime(now.year, now.month + 1, now.day);
      }

      final usersRef = FirebaseFirestore.instance.collection("Users");
      final clientRef = usersRef.doc(clientId);
      final dietitianRef = usersRef.doc(dietitianId);

      await dietitianRef.collection("subscriber").doc(clientId).set({
        "userId": clientId,
        "planType": planType,
        "price": planPrice,
        "status": "approved",
        "timestamp": FieldValue.serverTimestamp(),
        "expirationDate": Timestamp.fromDate(expirationDate),
      });

      await clientRef.collection("subscribeTo").doc(dietitianId).set({
        "dietitianId": dietitianId,
        "planType": planType,
        "price": planPrice,
        "status": "approved",
        "timestamp": FieldValue.serverTimestamp(),
        "expirationDate": Timestamp.fromDate(expirationDate),
      });

      await FirebaseFirestore.instance
          .collection("receipts")
          .doc(receiptId)
          .update({"status": "approved"});

      CustomSnackBar.show(
        context,
        'User subscription approved!',
        backgroundColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
      );

      // Reload data
      await _loadReceipts();
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Error approving user: $e',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFF4CAF50);
    }
  }

  Color _getPlanTypeColor(String planType) {
    switch (planType.toLowerCase()) {
      case 'monthly':
        return Colors.blue;
      case 'yearly':
        return Colors.purple;
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Export button for approved tab
        if (widget.status == 'approved')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: ElevatedButton.icon(
              onPressed: _isLoadingData ? null : _exportToExcel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                'Download as Excel File',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ),

        // List of receipts
        Expanded(
          child: _isLoadingData
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                )
              : _receiptsCache.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No ${widget.status} subscriptions found",
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: _receiptsCache.length,
                  itemBuilder: (context, index) {
                    final receipt = _receiptsCache[index];
                    final statusColor = _getStatusColor(receipt['status']);
                    final planTypeColor = _getPlanTypeColor(
                      receipt['planType'],
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${receipt['firstname']} ${receipt['lastname']}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4CAF50),
                                          fontFamily: 'PlusJakartaSans',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        receipt['planType'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'PlusJakartaSans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    receipt['status'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Price",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'PlusJakartaSans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      receipt['planPrice'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'PlusJakartaSans',
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Plan Type",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'PlusJakartaSans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: planTypeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        receipt['planType'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: planTypeColor,
                                          fontFamily: 'PlusJakartaSans',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (receipt['status'] == 'pending')
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _approveSubscription(receipt),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                    child: const Text(
                                      'Approve',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'PlusJakartaSans',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class UsersListPage extends StatefulWidget {
  final String currentUserId;
  final VoidCallback? onNavigateToSchedule; // Add this callback

  const UsersListPage({
    super.key,
    required this.currentUserId,
    this.onNavigateToSchedule, // Add this
  });

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  String get currentUserId => widget.currentUserId;

  String getChatRoomId(String userA, String userB) {
    if (userA.compareTo(userB) > 0) {
      return "$userB\_$userA";
    } else {
      return "$userA\_$userB";
    }
  }

  Future<Map<String, dynamic>> getLastMessage(
    BuildContext context,
    String chatRoomId,
    String otherUserName,
  ) async {
    final query = await FirebaseFirestore.instance
        .collection("messages")
        .where("chatRoomID", isEqualTo: chatRoomId)
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return {"message": "", "isMe": false, "time": ""};
    }

    final data = query.docs.first.data();
    String formattedTime = "";
    final timestamp = data["timestamp"];

    if (timestamp is Timestamp) {
      DateTime messageDate = timestamp.toDate();
      DateTime nowDate = DateTime.now();
      if (messageDate.year == nowDate.year &&
          messageDate.month == nowDate.month &&
          messageDate.day == nowDate.day) {
        formattedTime = TimeOfDay.fromDateTime(messageDate).format(context);
      } else {
        formattedTime = DateFormat('MMM d').format(messageDate);
      }
    }

    return {
      "message": data["message"] ?? "",
      "isMe": data["senderId"] == FirebaseAuth.instance.currentUser!.uid,
      "time": formattedTime,
      "senderName": data["senderName"] ?? "Unknown",
    };
  }

  /// ✅ Get followers of current dietitian
  Future<List<String>> getFollowerIds() async {
    try {
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('followers')
          .get();

      return followersSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching followers: $e');
      return [];
    }
  }

  /// ✅ Mark all messages as read for a specific chat
  Future<void> markMessagesAsRead(String chatRoomId, String receiverId) async {
    try {
      final unreadMessages = await FirebaseFirestore.instance
          .collection("messages")
          .where("chatRoomID", isEqualTo: chatRoomId)
          .where("receiverID", isEqualTo: currentUserId)
          .where("read", isEqualTo: "false")
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({"read": "true"});
      }

      // ✅ Also mark related notifications as read
      await markNotificationsAsRead(receiverId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// ✅ Mark notifications from a specific sender as read
  Future<void> markNotificationsAsRead(String senderId) async {
    try {
      final unreadNotifications = await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("notifications")
          .where("senderId", isEqualTo: senderId)
          .where("isRead", isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        await doc.reference.update({"isRead": true});
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentScaffoldBg = isDarkMode
        ? Colors.grey.shade900
        : Colors.grey.shade50;
    final Color currentAppBarBg = isDarkMode
        ? Colors.grey.shade800
        : Colors.white;
    final Color currentTabLabel = _textColorPrimary(context);
    final Color currentIndicator = _primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: currentScaffoldBg,
        appBar: AppBar(
          backgroundColor: currentAppBarBg,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: TabBar(
            labelColor: currentTabLabel,
            unselectedLabelColor: currentTabLabel.withOpacity(0.6),
            indicatorColor: currentIndicator,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontFamily: _primaryFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: _primaryFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              const Tab(text: "CHATS"),
              Tab(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text("NOTIFICATIONS"),
                    Positioned(
                      top: -1,
                      right: -1,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(currentUserId)
                            .collection('notifications')
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final unreadCount = snapshot.data!.docs.length;
                          return Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
        body: TabBarView(
          children: [
            // CHATS TAB - Modern Card Design
            FutureBuilder<List<String>>(
              future: getFollowerIds(),
              builder: (context, followerSnapshot) {
                if (followerSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final followerIds = followerSnapshot.data ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("Users")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _primaryColor),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No clients to chat with yet.",
                          style: _getTextStyle(
                            context,
                            fontSize: 16,
                            color: _textColorPrimary(context),
                          ),
                        ),
                      );
                    }

                    final users = snapshot.data!.docs;

                    // Filter users: Only admin and followers
                    final filteredUsers = users.where((userDoc) {
                      if (userDoc.id == currentUserId) return false;

                      final data = userDoc.data() as Map<String, dynamic>;
                      final role = data["role"]?.toString().toLowerCase() ?? "";

                      if (role == "admin") return true;
                      if (followerIds.contains(userDoc.id)) {
                        return true;
                      }

                      return false;
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Text(
                          "No clients following you yet.",
                          style: _getTextStyle(
                            context,
                            fontSize: 16,
                            color: _textColorPrimary(context),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 8.0,
                      ),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final userDoc = filteredUsers[index];
                        final data = userDoc.data() as Map<String, dynamic>;
                        final senderName =
                            "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                                .trim();
                        final chatRoomId = getChatRoomId(
                          currentUserId,
                          userDoc.id,
                        );

                        return FutureBuilder<Map<String, dynamic>>(
                          future: getLastMessage(
                            context,
                            chatRoomId,
                            senderName,
                          ),
                          builder: (context, snapshotMessage) {
                            String subtitleText = "No messages yet";
                            String timeText = "";

                            if (snapshotMessage.connectionState ==
                                    ConnectionState.done &&
                                snapshotMessage.hasData) {
                              final lastMsg = snapshotMessage.data!;
                              final lastMessage = lastMsg["message"] ?? "";
                              final lastSenderName =
                                  lastMsg["senderName"] ?? "";
                              timeText = lastMsg["time"] ?? "";

                              if (lastMessage.isNotEmpty) {
                                if (lastMsg["isMe"] ?? false) {
                                  subtitleText = "You: $lastMessage";
                                } else {
                                  subtitleText =
                                      "$lastSenderName: $lastMessage";
                                }
                              }
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 4.0,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    // Mark messages as read before navigating
                                    final chatRoomId = getChatRoomId(
                                      currentUserId,
                                      userDoc.id,
                                    );
                                    await markMessagesAsRead(
                                      chatRoomId,
                                      userDoc.id,
                                    );

                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MessagesPageDietitian(
                                                currentUserId: currentUserId,
                                                receiverId: userDoc.id,
                                                receiverName: senderName,
                                                receiverProfile:
                                                    data["profile"] ?? "",
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _cardBgColor(context),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar with online indicator
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: _primaryColor
                                                  .withOpacity(0.2),
                                              backgroundImage:
                                                  (data["profile"] != null &&
                                                      data["profile"]
                                                          .toString()
                                                          .isNotEmpty)
                                                  ? NetworkImage(
                                                      data["profile"],
                                                    )
                                                  : null,
                                              child:
                                                  (data["profile"] == null ||
                                                      data["profile"]
                                                          .toString()
                                                          .isEmpty)
                                                  ? Icon(
                                                      Icons.person_outline,
                                                      color: _primaryColor,
                                                      size: 24,
                                                    )
                                                  : null,
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _cardBgColor(
                                                      context,
                                                    ),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        // Chat info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                senderName,
                                                style: _getTextStyle(
                                                  context,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitleText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: _getTextStyle(
                                                  context,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: _textColorSecondary(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Time
                                        if (timeText.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              timeText,
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 12,
                                                color: _textColorSecondary(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),

            // NOTIFICATIONS TAB - Premium Design
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(currentUserId)
                  .collection("notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: _primaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No notifications yet",
                          style: _getTextStyle(
                            context,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textColorPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 12.0,
                  ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp? timestamp =
                        data["timestamp"] as Timestamp?;
                    String formattedTime = "";

                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      final now = DateTime.now();
                      if (date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day) {
                        formattedTime = DateFormat.jm().format(date);
                      } else if (date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day - 1) {
                        formattedTime = "Yesterday";
                      } else {
                        formattedTime = DateFormat('MMM d').format(date);
                      }
                    }

                    bool isRead = data["isRead"] == true;

                    // Determine icon and color based on type
                    IconData notificationIcon = Icons.notifications_rounded;
                    Color iconBgColor = _primaryColor;

                    if (data["type"] == "message") {
                      notificationIcon = Icons.chat_bubble_outline_rounded;
                      iconBgColor = const Color(0xFF2196F3);
                    } else if (data["type"] == "appointment" ||
                        data["type"] == "appointment_update") {
                      notificationIcon = Icons.event_available_outlined;
                      iconBgColor = const Color(0xFFFF9800);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: isRead
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  iconBgColor.withOpacity(0.08),
                                  iconBgColor.withOpacity(0.03),
                                ],
                              ),
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: isRead ? 0.5 : 2,
                        color: isRead
                            ? _cardBgColor(context)
                            : _cardBgColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: isRead
                              ? BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 0.5,
                                )
                              : BorderSide(
                                  color: iconBgColor.withOpacity(0.4),
                                  width: 1.5,
                                ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            if (!isRead) {
                              await FirebaseFirestore.instance
                                  .collection("Users")
                                  .doc(currentUserId)
                                  .collection("notifications")
                                  .doc(doc.id)
                                  .update({"isRead": true});
                            }

                            if (data["type"] == "message" &&
                                data["senderId"] != null &&
                                data["senderName"] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MessagesPageDietitian(
                                    receiverId: data["senderId"],
                                    receiverName: data["senderName"],
                                    currentUserId: currentUserId,
                                    receiverProfile:
                                        data["receiverProfile"] ?? "",
                                  ),
                                ),
                              );
                            } else if (data["type"] == "appointmentRequest" ||
                                data["type"] == "appointment" ||
                                data["type"] == "appointment_update") {
                              // Switch to Schedule tab using the callback
                              if (widget.onNavigateToSchedule != null) {
                                widget.onNavigateToSchedule!();
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Icon with colored background
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: iconBgColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: iconBgColor.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    notificationIcon,
                                    color: iconBgColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title and message
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              data["title"] ?? "Notification",
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 15,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                color: _textColorPrimary(
                                                  context,
                                                ),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                left: 8.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: iconBgColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        data["message"] ?? "",
                                        style: _getTextStyle(
                                          context,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: _textColorSecondary(context),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (formattedTime.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: _getTextStyle(
                                            context,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isRead
                                                ? _textColorSecondary(context)
                                                : iconBgColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleCalendarPage extends StatefulWidget {
  final String dietitianFirstName;
  final String dietitianLastName;
  final bool isDietitianNameLoading;

  const ScheduleCalendarPage({
    super.key,
    required this.dietitianFirstName,
    required this.dietitianLastName,
    required this.isDietitianNameLoading,
  });

  @override
  State<ScheduleCalendarPage> createState() => _ScheduleCalendarPageState();
}

class _ScheduleCalendarPageState extends State<ScheduleCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointmentsForCalendar();
  }

  Future<void> _loadAppointmentsForCalendar() async {
    final dietitianId = FirebaseAuth.instance.currentUser?.uid;
    if (dietitianId == null) {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoadingEvents = true);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('dietitianID', isEqualTo: dietitianId)
          .get();

      final Map<DateTime, List<dynamic>> eventsMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final appointmentDateStr = data['appointmentDate'] as String?;
        if (appointmentDateStr != null) {
          try {
            final appointmentDateTime = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).parse(appointmentDateStr);
            final dateOnly = DateTime.utc(
              appointmentDateTime.year,
              appointmentDateTime.month,
              appointmentDateTime.day,
            );
            if (eventsMap[dateOnly] == null) {
              eventsMap[dateOnly] = [];
            }
            eventsMap[dateOnly]!.add(data);
          } catch (e) {
            print("Error parsing appointment date for event loader: $e");
          }
        }
      }
      if (mounted) {
        setState(() {
          _events = eventsMap;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      print("Error loading appointments for calendar: $e");
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  bool _hasOverdueAppointment(DateTime day) {
    final events = _getEventsForDay(day);
    final now = DateTime.now();
    final normalizedToday = DateTime.utc(now.year, now.month, now.day);
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);

    // Only show overdue marker for PAST dates
    if (!normalizedDay.isBefore(normalizedToday)) {
      return false;
    }

    for (var event in events) {
      final status = (event['status'] ?? '').toString().toLowerCase().trim();
      // Only mark as overdue if CONFIRMED and NOT COMPLETED
      if (status == 'confirmed') {
        return true;
      }
    }
    return false;
  }

  bool _hasIncompleteAppointment(DateTime day) {
    final events = _getEventsForDay(day);
    final now = DateTime.now();
    final normalizedToday = DateTime.utc(now.year, now.month, now.day);
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);

    for (var event in events) {
      final status = (event['status'] ?? '').toString().toLowerCase().trim();

      // SKIP completed and cancelled appointments entirely
      if (status == 'completed' ||
          status == 'cancelled' ||
          status == 'cancel') {
        continue;
      }

      // Show red dot for:
      // 1. Current/future dates with any pending/waiting/confirmed status
      if (normalizedDay.isAfter(normalizedToday) ||
          isSameDay(normalizedDay, normalizedToday)) {
        return true;
      }
      // 2. Past dates - only show if NOT completed/cancelled (already checked above)
      else if (normalizedDay.isBefore(normalizedToday)) {
        return true;
      }
    }
    return false;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'confirmed') {
      return Colors.green;
    } else if (status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'cancel') {
      return Colors.red;
    } else if (status.toLowerCase().contains('waiting')) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  Future<void> _completeAppointment(String scheduleId) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(scheduleId)
          .update({'status': 'completed'});

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Appointment marked as completed!',
          backgroundColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle_outline,
        );
      }

      // Add small delay to ensure Firestore updates
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _loadAppointmentsForCalendar();
      }
    } catch (e) {
      print("Error completing appointment: $e");
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error completing appointment: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _showScheduleAppointmentDialog(DateTime selectedDate) async {
    final User? currentDietitian = FirebaseAuth.instance.currentUser;
    if (currentDietitian == null) {
      CustomSnackBar.show(
        context,
        'You must be logged in.',
        backgroundColor: Colors.redAccent,
        icon: Icons.warning_outlined
      );
      return;
    }

    TimeOfDay? selectedTime = TimeOfDay.now();
    String? selectedClientId;
    String selectedClientName = "Select Client";
    String? selectedClientEmail;
    TextEditingController notesController = TextEditingController();
    List<DocumentSnapshot> clients = [];

    try {
      // ✅ Fetch only clients with pending appointment requests
      QuerySnapshot appointmentRequestSnapshot = await FirebaseFirestore
          .instance
          .collection('appointmentRequest')
          .where('dietitianId', isEqualTo: currentDietitian.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      Set<String> pendingClientIds = {};
      for (var doc in appointmentRequestSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        pendingClientIds.add(data['clientId'] as String);
      }

      if (pendingClientIds.isEmpty && mounted) {
        CustomSnackBar.show(
          context,
          'No pending appointment requests from clients.',
          backgroundColor: Colors.orange,
          icon: Icons.info_outline,
        );
        return;
      }

      // Fetch user data for pending clients
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .get();

      for (var doc in userSnapshot.docs) {
        if (pendingClientIds.contains(doc.id)) {
          clients.add(doc);
        }
      }
    } catch (e) {
      print("Error fetching clients with pending requests: $e");
      CustomSnackBar.show(context, 'Error fetching clients: $e', backgroundColor: Colors.red, icon: Icons.error_outline);
      return;
    }

    if (clients.isEmpty && mounted) {
      CustomSnackBar.show(context, 'No clients found with pending appointment requests.', backgroundColor: Colors.orange, icon: Icons.info_outline);
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(
                'Schedule for ${DateFormat.yMMMMd().format(selectedDate)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    if (clients.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Client',
                          labelStyle: const TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        value: selectedClientId,
                        hint: Text(
                          selectedClientName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: clients.map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;
                          String name =
                              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
                                  .trim();
                          if (name.isEmpty) {
                            name = "Client ID: ${document.id.substring(0, 5)}";
                          }
                          return DropdownMenuItem<String>(
                            value: document.id,
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            selectedClientId = newValue;
                            if (newValue != null) {
                              final clientDoc = clients.firstWhere(
                                (doc) => doc.id == newValue,
                              );
                              final clientData =
                                  clientDoc.data() as Map<String, dynamic>;
                              selectedClientName =
                                  "${clientData['firstName'] ?? ''} ${clientData['lastName'] ?? ''}"
                                      .trim();
                              selectedClientEmail = clientData['email'] ?? '';
                              if (selectedClientName.isEmpty) {
                                selectedClientName =
                                    "Client ID: ${newValue.substring(0, 5)}";
                              }
                            } else {
                              selectedClientName = "Select Client";
                              selectedClientEmail = null;
                            }
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a client' : null,
                      )
                    else
                      const Text(
                        "No clients available.",
                        style: TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 15),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Color(0xFF4CAF50),
                      ),
                      title: Text(
                        'Time: ${selectedTime?.format(dialogContext) ?? 'Tap to select'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setStateDialog(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: const TextStyle(fontSize: 14),
                        hintText: 'Details for this appointment?',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Send Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    if (selectedClientId == null) {
                      CustomSnackBar.show(
                        dialogContext,
                        'Please select a client.',
                        backgroundColor: Colors.redAccent,
                        icon: Icons.warning_outlined
                      );
                      return;
                    }
                    if (selectedTime == null) {
                      CustomSnackBar.show(dialogContext, 'Please select an appointment time.', backgroundColor: Colors.redAccent, icon: Icons.schedule_outlined);
                      return;
                    }

                    final DateTime finalAppointmentDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    String dietitianDisplayName;
                    if (widget.isDietitianNameLoading) {
                      dietitianDisplayName =
                          currentDietitian.displayName ?? "Dietitian";
                    } else {
                      dietitianDisplayName =
                          (widget.dietitianFirstName.isNotEmpty ||
                              widget.dietitianLastName.isNotEmpty)
                          ? "${widget.dietitianFirstName} ${widget.dietitianLastName}"
                                .trim()
                          : currentDietitian.displayName ?? "Dietitian";
                    }

                    _saveScheduleToFirestore(
                      dietitianId: currentDietitian.uid,
                      dietitianName: dietitianDisplayName,
                      clientId: selectedClientId!,
                      clientName: selectedClientName,
                      clientEmail: selectedClientEmail ?? '',
                      appointmentDateTime: finalAppointmentDateTime,
                      notes: notesController.text.trim(),
                      status: 'Waiting for client response.',
                      contextForSnackBar: this.context,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveScheduleToFirestore({
    required String dietitianId,
    required String dietitianName,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required DateTime appointmentDateTime,
    required String notes,
    required String status,
    required BuildContext contextForSnackBar,
  }) async {
    try {
      final String appointmentDateStr = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(appointmentDateTime);
      final String createdAtStr = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());

      // ✅ Update appointmentRequest status to approved
      final appointmentRequestSnapshot = await FirebaseFirestore.instance
          .collection('appointmentRequest')
          .where('clientId', isEqualTo: clientId)
          .where('dietitianId', isEqualTo: dietitianId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (appointmentRequestSnapshot.docs.isNotEmpty) {
        for (var doc in appointmentRequestSnapshot.docs) {
          await doc.reference.update({'status': 'approved'});
        }
      }

      // ✅ Create schedule
      await FirebaseFirestore.instance.collection('schedules').add({
        'dietitianID': dietitianId,
        'dietitianName': dietitianName,
        'clientID': clientId,
        'clientName': clientName,
        'appointmentDate': appointmentDateStr,
        'notes': notes,
        'status': status,
        'createdAt': createdAtStr,
      });

      // ✅ Add notification
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(clientId)
          .collection("notifications")
          .add({
            "isRead": false,
            "title": "Appointment Scheduled",
            "message":
                "$dietitianName scheduled an appointment with you on ${DateFormat.yMMMMd().format(appointmentDateTime)} at ${DateFormat.jm().format(appointmentDateTime)}.",
            "type": "appointment",
            "receiverId": clientId,
            "receiverName": clientName,
            "senderId": dietitianId,
            "senderName": dietitianName,
            "timestamp": FieldValue.serverTimestamp(),
          });

      // ✅ Send email notification
      if (clientEmail.isNotEmpty) {
        final emailService = Appointmentemail();
        await emailService.sendAppointmentEmail(
          clientName: clientName,
          clientEmail: clientEmail,
          dietitianName: dietitianName,
          appointmentDate: appointmentDateTime,
          notes: notes,
        );
      }

      if (!mounted) return;
      CustomSnackBar.show(
        contextForSnackBar,
        'Appointment scheduled with $clientName successfully!',
        backgroundColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
      );
      _loadAppointmentsForCalendar();
    } catch (e) {
      print("Error saving schedule: $e");
      if (!mounted) return;
      CustomSnackBar.show(
        contextForSnackBar,
        'Error saving schedule: $e',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TableCalendar(
                locale: 'en_US',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendTextStyle: TextStyle(
                    color: const Color(0xFF4CAF50).withOpacity(0.8),
                  ),
                  defaultTextStyle: const TextStyle(color: Colors.black87),
                  markersMaxCount: 1,
                  markerSize: 5,
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Colors.black87,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Colors.black87,
                  ),
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final now = DateTime.now();
                    final normalizedToday = DateTime.utc(
                      now.year,
                      now.month,
                      now.day,
                    );
                    final normalizedDay = DateTime.utc(
                      date.year,
                      date.month,
                      date.day,
                    );
                    final isPastDate = normalizedDay.isBefore(normalizedToday);

                    // DEBUG: Print what we're checking
                    if (normalizedDay.month == 10 && normalizedDay.day == 22) {
                      print('📅 OCT 22 - isPastDate: $isPastDate');
                      print('📅 Events: ${_getEventsForDay(date)}');
                      for (var event in _getEventsForDay(date)) {
                        print('📅 Status: ${event['status']}');
                      }
                      print('📅 hasOverdue: ${_hasOverdueAppointment(date)}');
                      print(
                        '📅 hasIncomplete: ${_hasIncompleteAppointment(date)}',
                      );
                    }

                    if (_hasOverdueAppointment(date) && isPastDate) {
                      // Show exclamation mark for past confirmed appointments not completed
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          width: 16,
                          height: 16,
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      );
                    } else if (_hasIncompleteAppointment(date)) {
                      // Show red dot for active appointments
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          width: 8,
                          height: 8,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          if (_isLoadingEvents)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            )
          else if (_selectedDay != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Details for ${DateFormat.yMMMMd().format(_selectedDay!)}:",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildScheduledAppointmentsList(_selectedDay!),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text("Schedule New Appointment"),
                        onPressed: () {
                          if (_selectedDay != null) {
                            _showScheduleAppointmentDialog(_selectedDay!);
                          } else {
                            CustomSnackBar.show(context, 'Please select a day on the calendar first!', backgroundColor: Colors.redAccent, icon: Icons.calendar_today_outlined);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!_isLoadingEvents)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Select a day to see appointments.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduledAppointmentsList(DateTime selectedDate) {
    final dayEvents = _getEventsForDay(selectedDate);

    if (dayEvents.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No appointments scheduled for this day yet.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ),
      );
    }

    dayEvents.sort((a, b) {
      try {
        final dateA = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).parse(a['appointmentDate']);
        final dateB = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).parse(b['appointmentDate']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return Column(
      children: dayEvents.map((eventData) {
        final data = eventData as Map<String, dynamic>;
        DateTime appointmentDateTime;
        try {
          appointmentDateTime = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).parse(data['appointmentDate']);
        } catch (e) {
          return const SizedBox.shrink();
        }
        final formattedTime = DateFormat.jm().format(appointmentDateTime);
        final status = data['status'] ?? 'pending';
        final statusColor = _getStatusColor(status);
        final isConfirmed = status.toLowerCase() == 'confirmed';
        final isCompleted = status.toLowerCase() == 'completed';

        final now = DateTime.now();
        final normalizedToday = DateTime.utc(now.year, now.month, now.day);
        final normalizedAppointmentDate = DateTime.utc(
          appointmentDateTime.year,
          appointmentDateTime.month,
          appointmentDateTime.day,
        );
        final isOverdue =
            normalizedAppointmentDate.isBefore(normalizedToday) && !isCompleted;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isOverdue ? Colors.red.shade50 : Colors.white,
          child: ListTile(
            title: Text(
              "${data['clientName'] ?? 'Unknown Client'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Time: $formattedTime",
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  "Status: $status",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Please mark this appointment as complete",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if ((data['notes'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Notes: ${data['notes']}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            trailing: isConfirmed && !isCompleted
                ? SizedBox(
                    width: 100,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Complete',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        _completeAppointment(data['id']);
                      },
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
