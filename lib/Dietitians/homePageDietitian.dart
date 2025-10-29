import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'dart:io';
import 'package:excel/excel.dart' hide Border, TextSpan; // Hide Border and TextSpan from excelimport 'package:flutter/material.dart' show Border;
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

import '../email/declinedEmail.dart';

import '../dietitians/manageMealPlans.dart';
import 'payment.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'mealPlanRequest.dart';

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
            _buildMenuTile('Payment', Icons.payment_outlined),
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
        } else if (label == 'My Meal Plans') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageMealPlansPage()),
          );
        } else if (label == 'Payment') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentPage()),
          );
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
    // Fetch subscriber data
    final subscriberSnap = await FirebaseFirestore.instance
        .collection('Users')
        .doc(dietitianId)
        .collection('subscriber')
        .get();

    int activeSubscriptions = subscriberSnap.docs.length;
    int monthlySubs = 0;
    int yearlySubs = 0;
    int weeklySubs = 0;

    for (var doc in subscriberSnap.docs) {
      final data = doc.data();
      final planType = data['planType']?.toString() ?? '';

      if (planType.toLowerCase() == 'monthly') monthlySubs++;
      if (planType.toLowerCase() == 'yearly') yearlySubs++;
      if (planType.toLowerCase() == 'weekly') weeklySubs++;
    }

    // Fetch revenue data from Users collection
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(dietitianId)
        .get();

    final userData = userDoc.data();
    double totalRevenue = 0.0;
    double overallEarnings = 0.0;

    if (userData != null) {
      // Get totalRevenue and overallEarnings fields from Users document
      totalRevenue = (userData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      overallEarnings = (userData['overallEarnings'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'activeSubscriptions': activeSubscriptions,
      'monthlySubs': monthlySubs,
      'yearlySubs': yearlySubs,
      'weeklySubs': weeklySubs,
      'totalRevenue': totalRevenue,
      'overallEarnings': overallEarnings,
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
    // ADD this at the beginning of the method:
    final User? currentUser = FirebaseAuth.instance.currentUser;

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
                      // REPLACE 'Welcome Back!' with:
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String displayName = 'Welcome Back!';

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            final firstName = data['firstName'] ?? '';
                            final lastName = data['lastName'] ?? '';

                            if (firstName.isNotEmpty) {
                              displayName = 'Welcome $firstName!';
                            }
                          }

                          return Text(
                            displayName,
                            style: _getTextStyle(
                              context,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textColorOnPrimary,
                            ),
                          );
                        },
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
        'value': '₱${subData['overallEarnings']?.toString() ?? '0'}',
        'label': 'Overall Earnings',
        'icon': FontAwesomeIcons.pesoSign,
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

// REPLACE this widget inside _AnalyticsDashboardState in homePageDietitian.dart

  Widget _buildMealPlanCard(
      BuildContext context,
      Map<String, dynamic> mealData,
      ) {
    final mostPopularPlanData = mealData['mostPopularPlanData'] as Map<String, dynamic>?;
    final plansCreated = mealData['plansCreated'] ?? 0;
    final mostPopularPlan = mealData['mostPopularPlan'] ?? 'N/A';
    final description = mostPopularPlanData?['description']?.toString() ?? ''; // <-- Get the description

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
              plansCreated.toString(),
            ),

            // Only show popular plan section if data exists
            if (mostPopularPlanData != null && mostPopularPlanData.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: _textColorSecondary(context).withOpacity(0.3)),
              const SizedBox(height: 16),

              // Popular Plan Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Most Popular Plan',
                    style: _getTextStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        (mostPopularPlanData['likeCounts'] ?? 0).toString(),
                        style: _getTextStyle(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Plan Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor,
                      _primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        mostPopularPlan,
                        style: _getTextStyle(
                          context,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- ADDED: Description Box ---
              if (description.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.08), // Using primary color from dietitian theme
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.15), // Using primary color
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: _primaryColor, // Using primary color
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          description,
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textColorPrimary(context),
                          ),
                          // maxLines: 2, // You can limit lines if needed
                          // overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (description.isNotEmpty) const SizedBox(height: 16), // Add space if description exists
              // --- END: Added Description Box ---


              // Meals Section (Styled like home.dart)
              _buildMealItemExpanded(
                context,
                "Breakfast",
                mostPopularPlanData['breakfast'],
                mostPopularPlanData['breakfastTime'],
                Icons.wb_sunny_outlined,
                Colors.orange,
                isLocked: false,
              ),
              _buildMealItemExpanded(
                context,
                "AM Snack",
                mostPopularPlanData['amSnack'],
                mostPopularPlanData['amSnackTime'],
                Icons.coffee_outlined,
                Colors.brown,
                isLocked: false,
              ),
              _buildMealItemExpanded(
                context,
                "Lunch",
                mostPopularPlanData['lunch'],
                mostPopularPlanData['lunchTime'],
                Icons.restaurant_outlined,
                Colors.green,
                isLocked: false,
              ),
              _buildMealItemExpanded(
                context,
                "PM Snack",
                mostPopularPlanData['pmSnack'],
                mostPopularPlanData['pmSnackTime'],
                Icons.local_cafe_outlined,
                Colors.purple,
                isLocked: false,
              ),
              _buildMealItemExpanded(
                context,
                "Dinner",
                mostPopularPlanData['dinner'],
                mostPopularPlanData['dinnerTime'],
                Icons.nightlight_outlined,
                Colors.indigo,
                isLocked: false,
              ),
              if (mostPopularPlanData['midnightSnack'] != null &&
                  mostPopularPlanData['midnightSnack'].toString().isNotEmpty)
                _buildMealItemExpanded(
                  context,
                  "Midnight Snack",
                  mostPopularPlanData['midnightSnack'],
                  mostPopularPlanData['midnightSnackTime'],
                  Icons.bedtime_outlined,
                  Colors.blueGrey,
                  isLocked: false,
                ),
            ],
          ],
        ),
      ),
    );
  }

// ADD THIS NEW HELPER METHOD (if not already present):
  Widget _buildMealItemExpanded(
      BuildContext context,
      String mealName,
      String? mealContent,
      String? mealTime,
      IconData icon,
      Color iconColor, {
        bool isLocked = false,
      }) {
    // Skip if meal content is empty
    if (mealContent == null || mealContent.isEmpty || mealContent == '-') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : iconColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and meal name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLocked ? Colors.grey.shade600 : iconColor,
                      ),
                    ),
                    if ((mealTime ?? '').isNotEmpty && !isLocked) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: iconColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mealTime ?? '',
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Meal content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mealContent,
              style: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLocked
                    ? Colors.grey.shade500
                    : _textColorPrimary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  void _checkPendingRequestsAndNavigate(BuildContext context) async {
    try {
      final dietitianId = FirebaseAuth.instance.currentUser?.uid;
      if (dietitianId == null) {
        CustomSnackBar.show(
          context,
          'You must be logged in.',
          backgroundColor: Colors.redAccent,
          icon: Icons.warning_outlined,
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Checking requests...',
                    style: _getTextStyle(context, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Query for pending meal plan requests for this dietitian
      final snapshot = await FirebaseFirestore.instance
          .collection('mealPlanRequests')
          .where('dietitianId', isEqualTo: dietitianId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (snapshot.docs.isNotEmpty) {
        // There are pending requests - show dialog to ask
        if (mounted) {
          _showPendingRequestDialog(context, snapshot.docs);
        }
      } else {
        // No pending requests - go directly to CreateMealPlanPage
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateMealPlanPage()),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if error
      if (mounted) Navigator.pop(context);

      print('Error checking pending requests: $e');
      CustomSnackBar.show(
        context,
        'Error checking requests: $e',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void _showPendingRequestDialog(BuildContext context, List<QueryDocumentSnapshot> requests) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: _primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pending Meal Plan Requests',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You have ${requests.length} pending meal plan ${requests.length == 1 ? 'request' : 'requests'} from your clients.',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 14,
                    color: _textColorSecondary(dialogContext),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Would you like to create a personalized meal plan for them?',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateMealPlanPage()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'No',
                          style: _getTextStyle(
                            dialogContext,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MealPlanRequestCard(requests: requests)),
                          );
                          print('Navigate to personalized meal plan page with ${requests.length} requests');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Yes',
                          style: _getTextStyle(
                            dialogContext,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textColorOnPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
            onPressed: () => _checkPendingRequestsAndNavigate(context),
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
      length: 3,
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
              Tab(text: "Pending"),
              Tab(text: "Approved"),
              Tab(text: "Declined"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SubscriptionRequests(status: 'pending'),
            SubscriptionRequests(status: 'approved'),
            SubscriptionRequests(status: 'declined'),
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

      // FIXED: Keep planPrice as the original value (num or String), don't default to empty string
      results.add({
        "docId": doc.id,
        "clientID": clientID,
        "dietitianID": data['dietitianID'],
        "firstname":
        clientData['firstname'] ?? clientData['firstName'] ?? 'N/A',
        "lastname": clientData['lastname'] ?? clientData['lastName'] ?? 'N/A',
        "email": clientData['email'] ?? 'N/A',
        "planPrice": data['planPrice'] ?? 0, // Keep as number or 0, not empty string
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
      Sheet sheetObject = excel['${widget.status.toUpperCase()} Subscriptions'];

      // Define headers
      final headers = [
        'Client Name',
        'Email',
        'Plan Type',
        'Plan Price',
        'Status',
        'Date',
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

      // Convert to Uint8List for FlutterFileDialog
      final excelBytes = Uint8List.fromList(excel.encode()!);

      // Generate filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${widget.status}_subscriptions_$timestamp.xlsx';

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
        CustomSnackBar.show(
          context,
          'Error exporting to Excel: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  // Helper method to send notifications - ADD THIS METHOD
  Future<void> _sendNotification({
    required String receiverId,
    required String receiverName,
    required String senderId,
    required String senderName,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'isRead': false,
        'message': message,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'senderId': senderId,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'title': title,
        'type': type,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

// REPLACE YOUR _approveSubscription METHOD WITH THIS:
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

      print('Received planPrice: $planPrice (${planPrice.runtimeType})');
      print('Received planType: $planType');

      DateTime now = DateTime.now();
      DateTime expirationDate;

      if (planType.toString().toLowerCase() == 'weekly') {
        expirationDate = now.add(const Duration(days: 7));
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
        "receiptId": receiptId,
        "planType": planType,
        "price": planPrice,
        "status": "approved",
        "timestamp": FieldValue.serverTimestamp(),
        "expirationDate": Timestamp.fromDate(expirationDate),
      });

      await clientRef.collection("subscribeTo").doc(dietitianId).set({
        "dietitianId": dietitianId,
        "receiptId": receiptId,
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

      // Update dietitian's revenue and commission
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(dietitianRef);
        final currentData = snapshot.data() ?? {};

        double planPriceValue = 0.0;
        if (planPrice is num) {
          planPriceValue = planPrice.toDouble();
        } else if (planPrice is String) {
          String cleanPrice = planPrice.replaceAll(RegExp(r'[^\d.]'), '');
          planPriceValue = double.tryParse(cleanPrice) ?? 0.0;
        }

        print('Parsed planPriceValue: $planPriceValue');

        double totalRevenue = ((currentData['totalRevenue'] ?? 0) as num).toDouble();
        double weeklyCommission = ((currentData['weeklyCommission'] ?? 0) as num).toDouble();
        double monthlyCommission = ((currentData['monthlyCommission'] ?? 0) as num).toDouble();
        double yearlyCommission = ((currentData['yearlyCommission'] ?? 0) as num).toDouble();

        double commission = 0.0;

        if (planType.toString().toLowerCase() == 'weekly') {
          commission = planPriceValue * 0.15;
          weeklyCommission += commission;
        } else if (planType.toString().toLowerCase() == 'monthly') {
          commission = planPriceValue * 0.10;
          monthlyCommission += commission;
        } else if (planType.toString().toLowerCase() == 'yearly') {
          commission = planPriceValue * 0.08;
          yearlyCommission += commission;
        }

        totalRevenue += planPriceValue;
        double totalCommission = weeklyCommission + monthlyCommission + yearlyCommission;
        double totalEarnings = totalRevenue - totalCommission;

        double overallEarnings = ((currentData['overallEarnings'] ?? 0) as num).toDouble();
        double currentEarnings = planPriceValue - commission;
        overallEarnings += currentEarnings;

        print('Total Revenue: $totalRevenue');
        print('Commission: $commission');
        print('Total Commission: $totalCommission');
        print('Total Earnings: $totalEarnings');
        print('Current Earnings: $currentEarnings');
        print('Overall Earnings: $overallEarnings');

        transaction.update(dietitianRef, {
          "totalRevenue": totalRevenue,
          "weeklyCommission": weeklyCommission,
          "monthlyCommission": monthlyCommission,
          "yearlyCommission": yearlyCommission,
          "totalCommission": totalCommission,
          "totalEarnings": totalEarnings,
          "overallEarnings": overallEarnings,
        });
      });

      // Get dietitian name for notification
      final dietitianDoc = await dietitianRef.get();
      final dietitianData = dietitianDoc.data() ?? {};
      final dietitianName = "${dietitianData['firstName'] ?? ''} ${dietitianData['lastName'] ?? ''}".trim();

      // Send notification to client
      await _sendNotification(
        receiverId: clientId,
        receiverName: "${receipt['firstname']} ${receipt['lastname']}",
        senderId: dietitianId,
        senderName: dietitianName.isNotEmpty ? dietitianName : 'Your Dietitian',
        title: 'Subscription Approved',
        message: 'Your ${planType.toLowerCase()} subscription has been approved by ${dietitianName.isNotEmpty ? dietitianName : 'your dietitian'}. Your subscription is now active!',
        type: 'subscription',
      );

      CustomSnackBar.show(
        context,
        'User subscription approved and notification sent!',
        backgroundColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
      );

      await _loadReceipts();
    } catch (e) {
      print('Error in _approveSubscription: $e');
      CustomSnackBar.show(
        context,
        'Error approving user: $e',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

// REPLACE YOUR _declineSubscription METHOD WITH THIS:
  Future<void> _declineSubscription(Map<String, dynamic> receipt) async {
    String? declineReason;

    // Show reason dialog
    final reasonEntered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        final TextEditingController reasonController = TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: _cardBgColor(dialogContext),
            ),
        child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Decline Subscription',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(dialogContext),
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: _getTextStyle(
                      dialogContext,
                      fontSize: 14,
                      color: _textColorSecondary(dialogContext),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Please provide a reason for declining ',
                      ),
                      TextSpan(
                        text: '${receipt['firstname']} ${receipt['lastname']}',
                        style: _getTextStyle(
                          dialogContext,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textColorPrimary(dialogContext),
                        ),
                      ),
                      const TextSpan(
                        text: '\'s subscription request.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for declining...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          "Cancel",
                          style: _getTextStyle(
                            dialogContext,
                            fontWeight: FontWeight.bold,
                            color: _textColorSecondary(dialogContext),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a reason'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          declineReason = reasonController.text.trim();
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.red.withOpacity(0.3),
                        ),
                        child: Text(
                          "Decline",
                          style: _getTextStyle(
                            dialogContext,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
        );
      },
    );

    if (reasonEntered != true || declineReason == null) return;

    try {
      final currentDietitian = FirebaseAuth.instance.currentUser;
      if (currentDietitian == null) {
        CustomSnackBar.show(context, 'You must be logged in.',
            backgroundColor: Colors.redAccent, icon: Icons.lock_outline);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );

      final receiptId = receipt['docId'];
      final clientId = receipt['clientID'];
      final dietitianId = receipt['dietitianID'];

      // Update receipt status to declined
      await FirebaseFirestore.instance
          .collection("receipts")
          .doc(receiptId)
          .update({
        "status": "declined",
        "declinedAt": FieldValue.serverTimestamp(),
        "declineReason": declineReason,
      });

      // Get dietitian info
      final dietitianDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentDietitian.uid)
          .get();

      final dietitianData = dietitianDoc.data() ?? {};
      final dietitianName =
      "${dietitianData['firstName'] ?? ''} ${dietitianData['lastName'] ?? ''}"
          .trim();

      // Send notification to client with the reason
      await _sendNotification(
        receiverId: clientId,
        receiverName: "${receipt['firstname']} ${receipt['lastname']}",
        senderId: dietitianId,
        senderName: dietitianName.isNotEmpty ? dietitianName : 'Your Dietitian',
        title: 'Subscription Declined',
        message: 'Your ${receipt['planType'].toLowerCase()} subscription has been declined by ${dietitianName.isNotEmpty ? dietitianName : 'your dietitian'}. Reason: $declineReason',
        type: 'subscription',
      );

      // Optional: Send decline notification email
      try {
        await declinedEmail.sendDeclineNotification(
          recipientEmail: receipt['email'],
          clientName: "${receipt['firstname']} ${receipt['lastname']}",
          dietitianName: dietitianName.isNotEmpty ? dietitianName : 'Your Dietitian',
          planType: receipt['planType'],
          planPrice: receipt['planPrice'].toString(),
        );
      } catch (emailError) {
        debugPrint('Email notification failed: $emailError');
        // Continue even if email fails
      }

      if (mounted) Navigator.of(context).pop();

      CustomSnackBar.show(
        context,
        'Subscription declined and user notified.',
        backgroundColor: Colors.red,
        icon: Icons.cancel_outlined,
      );

      await _loadReceipts();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      debugPrint('Error declining subscription: $e');
      CustomSnackBar.show(
        context,
        'Error declining subscription: $e',
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
      case 'declined':
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
        // Export button for approved and declined tabs
        if (widget.status == 'approved' || widget.status == 'declined')
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
                                receipt['planPrice'].toString(),
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
                          child: Row(
                            children: [
                              Expanded(
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _declineSubscription(receipt),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    'Decline',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                  ),
                                ),
                              ),
                            ],
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



  Widget _buildCompactFilterChip(String filter) {
    final isSelected = _selectedNotificationFilter == filter;
    final chipColor = _getFilterChipColor(filter);
    final chipIcon = _getFilterChipIcon(filter);
    final chipLabel = _getFilterChipLabel(filter);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? chipColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? chipColor : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedNotificationFilter = filter;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              size: 14,
              color: isSelected ? chipColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              chipLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? chipColor : Colors.grey.shade600,
                fontFamily: _primaryFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
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

// --- NEW: Notification filter state ---
  String _selectedNotificationFilter = 'all'; // 'all', 'appointment', 'message',

  // --- UPDATED: Show confirmation dialog with premium design ---
  Future<void> _showClearAllDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardBgColor(dialogContext),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Icon Container ---
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // --- Title ---
                Text(
                  'Clear Notifications?',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(dialogContext),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Description ---
                Text(
                  'Are you sure you want to clear all notifications?)',
                  textAlign: TextAlign.center,
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 14,
                    color: _textColorSecondary(dialogContext),
                  ),
                ),
                const SizedBox(height: 32),

                // --- Cancel Button (Outlined) ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: _primaryColor, width: 1.5),
                      foregroundColor: _primaryColor,
                    ),
                    child: Text(
                      'Cancel',
                      style: _getTextStyle(
                        dialogContext,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Clear Button (Elevated) ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                    label: Text(
                      'Yes, Clear All',
                      style: _getTextStyle(
                        dialogContext,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      _clearAllNotifications();
    }
  }

  // --- UPDATED: Clear all notifications function ---
  Future<void> _clearAllNotifications() async {
    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.currentUserId)
          .collection("notifications")
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notificationsSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'All notifications cleared from view.',
          backgroundColor: _primaryColor,
          icon: Icons.done_all,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error clearing notifications: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
        );
      }
    }
  }

  // --- NEW: Get notification type for filtering ---
  String _getNotificationType(Map<String, dynamic> data) {
    final type = (data["type"] ?? '').toString().toLowerCase();
    if (type.contains('message')) return 'message';
    if (type.contains('appointment') || type.contains('appointment_update')) return 'appointment';
    return 'other';
  }

  // --- NEW: Get color for filter chip ---
  Color _getFilterChipColor(String filter) {
    switch (filter) {
      case 'appointment':
        return const Color(0xFFFF9800);
      case 'message':
        return const Color(0xFF2196F3);
      default:
        return _primaryColor;
    }
  }

  // --- NEW: Get icon for filter chip ---
  IconData _getFilterChipIcon(String filter) {
    switch (filter) {
      case 'appointment':
        return Icons.event_available_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  // --- NEW: Get label for filter chip ---
  String _getFilterChipLabel(String filter) {
    switch (filter) {
      case 'appointment':
        return 'Appointments';
      case 'message':
        return 'Messages';
      default:
        return 'All';
    }
  }

  // --- NEW: Filter notifications based on selected filter ---
  bool _shouldShowNotification(Map<String, dynamic> data) {
    if (_selectedNotificationFilter == 'all') return true;
    final notificationType = _getNotificationType(data);
    return notificationType == _selectedNotificationFilter;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentScaffoldBg =
    isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final Color currentAppBarBg =
    isDarkMode ? Colors.grey.shade800 : Colors.white;
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
                            .doc(widget.currentUserId)
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
            // CHATS TAB
            _buildChatsTab(),

            // NOTIFICATIONS TAB - With Filters
            // --- REPLACE THIS SECTION IN homePageDietitian.dart ---
// This replaces the entire NOTIFICATIONS TAB StreamBuilder in the UsersListPage build method

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

                final Map<String, DocumentSnapshot> groupedNotifications = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String groupingKey;
                  if (data['type'] == 'message' && data['senderId'] != null) {
                    groupingKey = data['senderId'];
                  } else {
                    groupingKey = doc.id;
                  }
                  if (!groupedNotifications.containsKey(groupingKey)) {
                    groupedNotifications[groupingKey] = doc;
                  }
                }
                var finalDocsToShow = groupedNotifications.values.toList();

                // Filter notifications based on selected filter
                finalDocsToShow = finalDocsToShow.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _shouldShowNotification(data);
                }).toList();

                return Column(
                  children: [
                    // --- COMPACT HEADER WITH FILTER CHIPS AND CLEAR BUTTON ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Filter chips in a horizontal scrollable row
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCompactFilterChip('all'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('appointment'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('message'),
                                ],
                              ),
                            ),
                          ),
                          // Clear All button as icon button
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showClearAllDialog,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.redAccent.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- NOTIFICATIONS LIST ---
                    Expanded(
                      child: finalDocsToShow.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: _primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No notifications",
                              style: _getTextStyle(
                                context,
                                fontSize: 16,
                                color: _textColorSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: finalDocsToShow.length,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        itemBuilder: (context, index) {
                          final doc = finalDocsToShow[index];
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
                          final notificationType = _getNotificationType(data);
                          final iconBgColor = _getFilterChipColor(notificationType);
                          final notificationIcon = _getFilterChipIcon(notificationType);

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
                                    ? BorderSide(color: Colors.grey.shade300, width: 0.5)
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
                                  } else if (data["type"] ==
                                      "appointmentRequest" ||
                                      data["type"] == "appointment" ||
                                      data["type"] == "appointment_update") {
                                    if (widget.onNavigateToSchedule != null) {
                                      widget.onNavigateToSchedule!();
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                          iconBgColor.withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                            iconBgColor.withOpacity(0.2),
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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    data["title"] ??
                                                        "Notification",
                                                    style: _getTextStyle(
                                                      context,
                                                      fontSize: 15,
                                                      fontWeight: isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                      color:
                                                      _textColorPrimary(
                                                          context),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                    const EdgeInsets.only(
                                                        left: 8.0),
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
                                                color:
                                                _textColorSecondary(context),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (formattedTime.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12.0),
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
                                                      ? _textColorSecondary(
                                                      context)
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
                      ),
                    ),
                  ],
                );
              },
            ),


          ],
        ),
      ),
    );
  }

  // --- NEW: Build chats tab ---
  Widget _buildChatsTab() {
    return FutureBuilder<List<String>>(
      future: getFollowerIds(),
      builder: (context, followerSnapshot) {
        if (followerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        final followerIds = followerSnapshot.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("Users").snapshots(),
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
            final filteredUsers = users.where((userDoc) {
              if (userDoc.id == currentUserId) return false;
              final data = userDoc.data() as Map<String, dynamic>;
              final role = data["role"]?.toString().toLowerCase() ?? "";
              if (role == "admin") return true;
              if (followerIds.contains(userDoc.id)) return true;
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
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final userDoc = filteredUsers[index];
                final data = userDoc.data() as Map<String, dynamic>;
                final senderName =
                "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
                final chatRoomId = getChatRoomId(currentUserId, userDoc.id);

                return FutureBuilder<Map<String, dynamic>>(
                  future: getLastMessage(context, chatRoomId, senderName),
                  builder: (context, snapshotMessage) {
                    String subtitleText = "No messages yet";
                    String timeText = "";

                    if (snapshotMessage.connectionState == ConnectionState.done &&
                        snapshotMessage.hasData) {
                      final lastMsg = snapshotMessage.data!;
                      final lastMessage = lastMsg["message"] ?? "";
                      final lastSenderName = lastMsg["senderName"] ?? "";
                      timeText = lastMsg["time"] ?? "";

                      if (lastMessage.isNotEmpty) {
                        if (lastMsg["isMe"] ?? false) {
                          subtitleText = "You: $lastMessage";
                        } else {
                          subtitleText = "$lastSenderName: $lastMessage";
                        }
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await markMessagesAsRead(chatRoomId, userDoc.id);
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessagesPageDietitian(
                                    currentUserId: currentUserId,
                                    receiverId: userDoc.id,
                                    receiverName: senderName,
                                    receiverProfile: data["profile"] ?? "",
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
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                      _primaryColor.withOpacity(0.2),
                                      backgroundImage: (data["profile"] != null &&
                                          data["profile"].toString().isNotEmpty)
                                          ? NetworkImage(data["profile"])
                                          : null,
                                      child: (data["profile"] == null ||
                                          data["profile"].toString().isEmpty)
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
                                            color: _cardBgColor(context),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
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
                                          color:
                                          _textColorSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (timeText.isNotEmpty)
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      timeText,
                                      style: _getTextStyle(
                                        context,
                                        fontSize: 12,
                                        color:
                                        _textColorSecondary(context),
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
    );
  }

  // --- NEW: Build filter chip widget ---
  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedNotificationFilter == filter;
    final chipColor = _getFilterChipColor(filter);
    final chipIcon = _getFilterChipIcon(filter);
    final chipLabel = _getFilterChipLabel(filter);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedNotificationFilter = filter;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: chipColor.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            size: 16,
            color: isSelected ? chipColor : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            chipLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? chipColor : Colors.grey.shade600,
              fontFamily: _primaryFontFamily,
            ),
          ),
        ],
      ),
    );
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

}

// --- REDESIGNED SCHEDULE CALENDAR PAGE WITH DASHBOARD CARD STYLES ---

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

    if (!normalizedDay.isBefore(normalizedToday)) {
      return false;
    }

    for (var event in events) {
      final status = (event['status'] ?? '').toString().toLowerCase().trim();
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

      if (status == 'completed' ||
          status == 'cancelled' ||
          status == 'cancel') {
        continue;
      }

      if (normalizedDay.isAfter(normalizedToday) ||
          isSameDay(normalizedDay, normalizedToday)) {
        return true;
      } else if (normalizedDay.isBefore(normalizedToday)) {
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
        icon: Icons.warning_outlined,
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
      CustomSnackBar.show(context, 'Error fetching clients: $e',
          backgroundColor: Colors.red, icon: Icons.error_outline);
      return;
    }

    if (clients.isEmpty && mounted) {
      CustomSnackBar.show(context,
          'No clients found with pending appointment requests.',
          backgroundColor: Colors.orange,
          icon: Icons.info_outline);
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: _cardBgColor(dialogContext),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -50,
                              left: -80,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.06),
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
                                  color: _primaryColor.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Schedule Appointment',
                            style: _getTextStyle(
                              dialogContext,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _textColorPrimary(dialogContext),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'For ${DateFormat.yMMMMd().format(selectedDate)}',
                            textAlign: TextAlign.center,
                            style: _getTextStyle(
                              dialogContext,
                              fontSize: 14,
                              color: _textColorSecondary(dialogContext),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                if (clients.isNotEmpty)
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Select Client',
                                      labelStyle: _getTextStyle(
                                        dialogContext,
                                        fontSize: 14,
                                        color: _textColorSecondary(
                                            dialogContext),
                                      ),
                                      prefixIcon: Icon(Icons.person_outline,
                                          color: _primaryColor),
                                      filled: true,
                                      fillColor: _scaffoldBgColor(dialogContext),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: _primaryColor, width: 2),
                                      ),
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      isDense: true,
                                    ),
                                    value: selectedClientId,
                                    hint: Text(
                                      selectedClientName,
                                      style: _getTextStyle(
                                        dialogContext,
                                        fontSize: 14,
                                        color: _textColorSecondary(
                                            dialogContext),
                                      ),
                                    ),
                                    dropdownColor: _cardBgColor(dialogContext),
                                    items: clients
                                        .map((DocumentSnapshot document) {
                                      Map<String, dynamic> data = document
                                          .data()! as Map<String, dynamic>;
                                      String name =
                                      "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
                                          .trim();
                                      if (name.isEmpty) {
                                        name =
                                        "Client ID: ${document.id.substring(0, 5)}";
                                      }
                                      return DropdownMenuItem<String>(
                                        value: document.id,
                                        child: Text(
                                          name,
                                          style: _getTextStyle(
                                            dialogContext,
                                            fontSize: 14,
                                          ),
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
                                          final clientData = clientDoc.data()
                                          as Map<String, dynamic>;
                                          selectedClientName =
                                              "${clientData['firstName'] ?? ''} ${clientData['lastName'] ?? ''}"
                                                  .trim();
                                          selectedClientEmail =
                                              clientData['email'] ?? '';
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
                                  )
                                else
                                  Text(
                                    "No clients available.",
                                    style: _getTextStyle(
                                      dialogContext,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () async {
                                    final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                      context: dialogContext,
                                      initialTime: selectedTime ?? TimeOfDay.now(),
                                    );
                                    if (pickedTime != null) {
                                      setStateDialog(() {
                                        selectedTime = pickedTime;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _scaffoldBgColor(dialogContext),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_filled_rounded,
                                          color: _primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Time: ${selectedTime?.format(dialogContext) ?? 'Select Time'}',
                                            style: _getTextStyle(
                                              dialogContext,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: notesController,
                                  style: _getTextStyle(dialogContext),
                                  decoration: InputDecoration(
                                    labelText: 'Notes (Optional)',
                                    labelStyle: _getTextStyle(
                                      dialogContext,
                                      fontSize: 14,
                                      color: _textColorSecondary(dialogContext),
                                    ),
                                    prefixIcon: Icon(Icons.note_outlined,
                                        color: _primaryColor),
                                    filled: true,
                                    fillColor: _scaffoldBgColor(dialogContext),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: _primaryColor, width: 2),
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    isDense: true,
                                  ),
                                  maxLines: 3,
                                  textCapitalization:
                                  TextCapitalization.sentences,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                        color: _primaryColor, width: 1.5),
                                    foregroundColor: _primaryColor,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: _getTextStyle(
                                      dialogContext,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (selectedClientId == null) {
                                      CustomSnackBar.show(
                                        dialogContext,
                                        'Please select a client.',
                                        backgroundColor: Colors.redAccent,
                                        icon: Icons.warning_outlined,
                                      );
                                      return;
                                    }
                                    if (selectedTime == null) {
                                      CustomSnackBar.show(dialogContext,
                                          'Please select an appointment time.',
                                          backgroundColor: Colors.redAccent,
                                          icon: Icons.schedule_outlined);
                                      return;
                                    }

                                    final DateTime finalAppointmentDateTime =
                                    DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      selectedTime!.hour,
                                      selectedTime!.minute,
                                    );

                                    String dietitianDisplayName;
                                    if (widget.isDietitianNameLoading) {
                                      dietitianDisplayName =
                                          currentDietitian.displayName ??
                                              "Dietitian";
                                    } else {
                                      dietitianDisplayName =
                                      (widget.dietitianFirstName.isNotEmpty ||
                                          widget.dietitianLastName
                                              .isNotEmpty)
                                          ? "${widget.dietitianFirstName} ${widget.dietitianLastName}"
                                          .trim()
                                          : currentDietitian.displayName ??
                                          "Dietitian";
                                    }

                                    _saveScheduleToFirestore(
                                      dietitianId: currentDietitian.uid,
                                      dietitianName: dietitianDisplayName,
                                      clientId: selectedClientId!,
                                      clientName: selectedClientName,
                                      clientEmail: selectedClientEmail ?? '',
                                      appointmentDateTime:
                                      finalAppointmentDateTime,
                                      notes: notesController.text.trim(),
                                      status: 'Waiting for client response.',
                                      contextForSnackBar: this.context,
                                    );
                                    Navigator.of(dialogContext).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: _textColorOnPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  icon: const Icon(Icons.send_rounded,
                                      size: 18),
                                  label: Text(
                                    'Schedule',
                                    style: _getTextStyle(
                                      dialogContext,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _textColorOnPrimary,
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
      final String appointmentDateStr =
      DateFormat('yyyy-MM-dd HH:mm').format(appointmentDateTime);
      final String createdAtStr =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

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
      backgroundColor: _scaffoldBgColor(context),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: _cardBgColor(context),
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
                  defaultTextStyle: _getTextStyle(context),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  titleTextStyle: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: _textColorPrimary(context),
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: _textColorPrimary(context),
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

                    if (_hasOverdueAppointment(date) && isPastDate) {
                      return Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 8,
                          ),
                        ),
                      );
                    } else if (_hasIncompleteAppointment(date)) {
                      return Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
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
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: _primaryColor,
                ),
              ),
            )
          else if (_selectedDay != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMMd().format(_selectedDay!),
                      style: _getTextStyle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appointments & Schedule',
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        color: _textColorSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildScheduledAppointmentsList(_selectedDay!),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: Text(
                          "Schedule New Appointment",
                          style: _getTextStyle(
                            context,
                            color: _textColorOnPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          if (_selectedDay != null) {
                            _showScheduleAppointmentDialog(_selectedDay!);
                          } else {
                            CustomSnackBar.show(
                              context,
                              'Please select a day on the calendar first!',
                              backgroundColor: Colors.redAccent,
                              icon: Icons.calendar_today_outlined,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
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
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        color: _textColorSecondary(context),
                      ),
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
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 48,
                color: _primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                "No appointments scheduled",
                style: _getTextStyle(
                  context,
                  fontSize: 14,
                  color: _textColorSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    dayEvents.sort((a, b) {
      try {
        final dateA = DateFormat('yyyy-MM-dd HH:mm').parse(a['appointmentDate']);
        final dateB = DateFormat('yyyy-MM-dd HH:mm').parse(b['appointmentDate']);
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
          appointmentDateTime =
              DateFormat('yyyy-MM-dd HH:mm').parse(data['appointmentDate']);
        } catch (e) {
          return const SizedBox.shrink();
        }
        final formattedTime = DateFormat.jm().format(appointmentDateTime);
        final status = data['status'] ?? 'pending';
        final statusColor = _getStatusColor(status);
        final isConfirmed = status.toLowerCase() == 'confirmed';
        final isCompleted = status.toLowerCase() == 'completed';

        final now = DateTime.now();
        final normalizedToday =
        DateTime.utc(now.year, now.month, now.day);
        final normalizedAppointmentDate = DateTime.utc(
          appointmentDateTime.year,
          appointmentDateTime.month,
          appointmentDateTime.day,
        );

        // --- START: CORRECTED LOGIC ---
        // Only mark as "overdue" if the date is in the past AND the status is "confirmed".
        final isOverdue =
            normalizedAppointmentDate.isBefore(normalizedToday) &&
                isConfirmed;
        // --- END: CORRECTED LOGIC ---

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardBgColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOverdue
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
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
                // Client Name Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: _primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data['clientName'] ?? 'Unknown Client',
                        style: _getTextStyle(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time and Status Layout
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time section
                    Row(
                      mainAxisSize: MainAxisSize.min, // Takes only needed space
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedTime,
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColorPrimary(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8.0), // Vertical space

                    // Status section
                    Row(
                      mainAxisSize: MainAxisSize.min, // Takes only needed space
                      children: [
                        Icon(
                          Icons.bookmark_outline_rounded,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status, // "Waiting for client response."
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if ((data['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: _textColorSecondary(context).withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['notes'],
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            color: _textColorSecondary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isOverdue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please mark as complete',
                            style: _getTextStyle(
                              context,
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // The "Mark as Complete" button will still only show if
                // it's "confirmed" but not "completed" (which is correct)
                if (isConfirmed && !isCompleted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _textColorOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        'Mark as Complete',
                        style: _getTextStyle(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textColorOnPrimary,
                        ),
                      ),
                      onPressed: () {
                        _completeAppointment(data['id']);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
