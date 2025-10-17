import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

import '../pages/login.dart';
import 'messagesDietitian.dart';
import 'createMealPlan.dart';
import 'dietitianProfile.dart';

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
      UsersListPage(currentUserId: firebaseUser!.uid),
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
            child: Text("No dietitian user logged in.", style: _getTextStyle(context))),
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
          style: _getTextStyle(context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColorOnPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DietitianProfile())),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _primaryColor.withOpacity(0.2),
                backgroundImage:
                (profileUrl.isNotEmpty) ? NetworkImage(profileUrl) : null,
                child: (profileUrl.isEmpty)
                    ? const Icon(Icons.person,
                    size: 20, color: _textColorOnPrimary)
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
            : Center(child: Text("Page not found", style: _getTextStyle(context))),
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
                    color: _textColorOnPrimary),
              ),
              accountEmail: _isUserNameLoading
                  ? _buildShimmerText(150, 14, topMargin: 4)
                  : Text(firebaseUser!.email ?? "",
                  style: const TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 14,
                      color: _textColorOnPrimary)),
              currentAccountPicture: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 30, color: Colors.green));
                  }
                  final profileUrl =
                      (snapshot.data!.data() as Map<String, dynamic>?)?['profile'] ?? '';
                  return CircleAvatar(
                    backgroundImage:
                    profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                    backgroundColor: Colors.white,
                    child: profileUrl.isEmpty
                        ? const Icon(Icons.person, size: 30, color: Colors.green)
                        : null,
                  );
                },
              ),
              decoration: const BoxDecoration(color: _primaryColor),
            ),
            _buildMenuTile('My Meal Plans', Icons.list_alt_outlined),
            _buildMenuTile('Client Management', Icons.people_outline_rounded),
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
              offset: const Offset(0, -2))
        ],
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => setState(() => selectedIndex = index),
          selectedItemColor: _textColorOnPrimary,
          unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
          backgroundColor: _primaryColor,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedLabelStyle: _getTextStyle(context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textColorOnPrimary),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.edit_calendar_outlined),
                activeIcon: Icon(Icons.edit_calendar),
                label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.mail_outline),
                activeIcon: Icon(Icons.mail),
                label: 'Messages'),
          ],
        ),
      ),
    );
  }

  // --- HELPER & LOGIC METHODS ---

  Widget _buildMenuTile(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _textColorPrimary(context), size: 24),
      title: Text(label,
          style: _getTextStyle(context,
              fontWeight: FontWeight.w500, fontSize: 15)),
      onTap: () async {
        Navigator.pop(context);
        if (label == 'Logout') {
          bool signedOut = await signOutFromGoogle();
          if (signedOut && mounted) {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPageMobile()),
                    (Route<dynamic> route) => false);
          }
        }
      },
      dense: true,
    );
  }

  Widget _buildShimmerText(double width, double height, {double topMargin = 0}) {
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
    setState(() { _isUserNameLoading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
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
      setState(() { _isUserNameLoading = false; });
    }
  }

  Future<void> _updateGooglePhotoURL() async {
    if (firebaseUser == null) return;
    final userDoc = FirebaseFirestore.instance.collection("Users").doc(firebaseUser!.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists || (snapshot.data()?['profile'] as String? ?? '').isEmpty) {
      if (firebaseUser!.photoURL != null) {
        await userDoc.set({"profile": firebaseUser!.photoURL}, SetOptions(merge: true));
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

  Future<Map<String, dynamic>> _fetchSubscriptionData(String dietitianId) async {
    final subscriberSnap = await FirebaseFirestore.instance
        .collection('Users')
        .doc(dietitianId)
        .collection('subscriber')
        .get();

    int activeSubscriptions = subscriberSnap.docs.length;
    int monthlySubs = 0;
    int yearlySubs = 0;
    int newClientsThisMonth = 0;
    double totalRevenue = 0.0;
    final now = DateTime.now();

    for (var doc in subscriberSnap.docs) {
      final data = doc.data();
      if (data['planType'] == 'Monthly') monthlySubs++;
      if (data['planType'] == 'Yearly') yearlySubs++;

      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        if (date.year == now.year && date.month == now.month) {
          newClientsThisMonth++;
        }
      }

      final priceString = data['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      if (priceString != null && priceString.isNotEmpty) {
        totalRevenue += double.tryParse(priceString) ?? 0.0;
      }
    }

    return {
      'activeSubscriptions': activeSubscriptions,
      'monthlySubs': monthlySubs,
      'yearlySubs': yearlySubs,
      'newClientsThisMonth': newClientsThisMonth,
      'totalRevenue': totalRevenue,
    };
  }

  Future<Map<String, dynamic>> _fetchMealPlanData(String dietitianId) async {
    final mealPlanSnap = await FirebaseFirestore.instance
        .collection('mealPlans')
        .where('dietitianId', isEqualTo: dietitianId)
        .get();

    String mostPopularPlan = 'N/A';
    int maxLikes = -1;

    for (var doc in mealPlanSnap.docs) {
      final data = doc.data();
      final likes = data['likes'] as int? ?? 0;
      if (likes > maxLikes) {
        maxLikes = likes;
        mostPopularPlan = data['planName'] ?? 'Unnamed Plan';
      }
    }

    return {
      'plansCreated': mealPlanSnap.docs.length,
      'mostPopularPlan': mostPopularPlan,
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
        } catch (e) { /* ignore parse error */ }
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
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
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
            _buildAnalyticsCard(
              context: context,
              title: "Client & Subscriptions",
              icon: Icons.group,
              children: [
                _buildStatItem(context, Icons.check, "Active Subscriptions",
                    subData['activeSubscriptions']?.toString() ?? '0'),
                _buildStatItem(context, Icons.pie_chart, "Subscription Breakdown",
                    "${subData['monthlySubs'] ?? 0} Monthly / ${subData['yearlySubs'] ?? 0} Yearly"),
                _buildStatItem(context, Icons.new_releases, "New Clients This Month",
                    subData['newClientsThisMonth']?.toString() ?? '0'),
                _buildStatItem(
                    context,
                    Icons.monetization_on,
                    "Total Revenue",
                    "\$${(subData['totalRevenue'] ?? 0.0).toStringAsFixed(2)}"),
              ],
            ),
            _buildAnalyticsCard(
              context: context,
              title: "Meal Plan Engagement",
              icon: Icons.restaurant_menu,
              children: [
                _buildStatItem(context, Icons.thumb_up, "Most Popular Meal Plan",
                    mealData['mostPopularPlan'] ?? 'N/A'),
                _buildStatItem(context, Icons.note_add, "Plans Created",
                    mealData['plansCreated']?.toString() ?? '0'),
              ],
            ),
            _buildAnalyticsCard(
              context: context,
              title: "Appointments & Schedule",
              icon: Icons.calendar_today,
              children: [
                _buildStatItem(context, Icons.event_available, "Appointments This Month",
                    apptData['appointmentsThisMonth']?.toString() ?? '0'),
                _buildStatItem(context, Icons.star, "Most Frequent Client",
                    apptData['mostFrequentClient'] ?? 'N/A'),
                _buildStatItem(context, Icons.work, "Busiest Day of the Week",
                    apptData['busiestDay'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),
            Text("Quick Actions",
                style: _getTextStyle(context,
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const PendingSubscriptionCard(),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateMealPlanPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _textColorOnPrimary,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.post_add_rounded, size: 20),
                label: Text("Create a New Meal Plan",
                    style: _getTextStyle(context,
                        color: _textColorOnPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: _getTextStyle(context,
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: _textColorSecondary(context), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: _getTextStyle(context,
                  fontSize: 14, color: _textColorSecondary(context)),
            ),
          ),
          Text(
            value,
            style: _getTextStyle(context,
                fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: _cardBgColor(context),
      highlightColor: _scaffoldBgColor(context),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLoadingCard(itemCount: 4),
          _buildLoadingCard(itemCount: 2),
          _buildLoadingCard(itemCount: 3),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({required int itemCount}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 200, height: 24, color: Colors.white),
            const SizedBox(height: 16),
            for (int i = 0; i < itemCount; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(width: 24, height: 24, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 24, color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
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
              Icon(
                Icons.group_add_outlined,
                color: _primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Subscription Requests",
                      style: _getTextStyle(context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColorPrimary(context)),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('receipts')
                          .where('dietitianID', isEqualTo: dietitianId)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text("Loading...",
                              style: _getTextStyle(context,
                                  fontSize: 13,
                                  color: _textColorSecondary(context)));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text("No pending requests.",
                              style: _getTextStyle(context,
                                  fontSize: 13,
                                  color: _textColorSecondary(context)));
                        }
                        final count = snapshot.data!.docs.length;
                        return Text(
                          "$count request${count == 1 ? '' : 's'} to review",
                          style: _getTextStyle(context,
                              fontSize: 13, color: _primaryColor, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: _textColorSecondary(context), size: 16),
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
        backgroundColor: _scaffoldBgColor(context),
        appBar: AppBar(
          elevation: 1,
          backgroundColor: _primaryColor,
          iconTheme: const IconThemeData(color: _textColorOnPrimary, size: 28),
          title: Text(
            "Manage Subscriptions",
            style: _getTextStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColorOnPrimary,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: _getTextStyle(
              context,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textColorOnPrimary,
            ),
            unselectedLabelStyle: _getTextStyle(
              context,
              fontSize: 14,
              color: _textColorOnPrimary.withOpacity(0.7),
            ),
            tabs: const [
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
  Future<List<Map<String, dynamic>>> _fetchReceiptsWithClients(String status) async {
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
      results.add({
        "docId": doc.id,
        "clientID": clientID,
        "dietitianID": data['dietitianID'],
        "firstname": clientData['firstname'] ?? clientData['firstName'] ?? 'N/A',
        "lastname": clientData['lastname'] ?? clientData['lastName'] ?? 'N/A',
        "planPrice": data['planPrice'] ?? '',
        "planType": data['planType'] ?? '',
        "status": data['status'] ?? '',
      });
    }

    return results;
  }

  Future<void> _approveSubscription(Map<String, dynamic> receipt) async {
    try {
      final currentDietitian = FirebaseAuth.instance.currentUser;
      if (currentDietitian == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in.")),
        );
        return;
      }

      final receiptId = receipt['docId'];
      final clientId = receipt['clientID'];
      final dietitianId = receipt['dietitianID'];
      final planType = receipt['planType'];
      final planPrice = receipt['planPrice'];

      DateTime now = DateTime.now();
      DateTime expirationDate;

      if (planType.toString().toLowerCase() == 'monthly') {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User subscription approved!")),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error approving user: $e")),
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
        return _primaryColor;
    }
  }

  Color _getPlanTypeColor(String planType) {
    switch (planType.toLowerCase()) {
      case 'monthly':
        return Colors.blue;
      case 'yearly':
        return Colors.purple;
      default:
        return _primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchReceiptsWithClients(widget.status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: _primaryColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "No ${widget.status} subscriptions found",
                  style: _getTextStyle(context, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final receipts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: receipts.length,
          itemBuilder: (context, index) {
            final receipt = receipts[index];
            final statusColor = _getStatusColor(receipt['status']);
            final planTypeColor = _getPlanTypeColor(receipt['planType']);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: _cardBgColor(context),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${receipt['firstname']} ${receipt['lastname']}",
                                style: _getTextStyle(context,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                receipt['planType'],
                                style: _getTextStyle(context,
                                    fontSize: 12,
                                    color: _textColorSecondary(context)),
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
                              fontFamily: _primaryFontFamily,
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
                              style: _getTextStyle(context,
                                  fontSize: 11,
                                  color: _textColorSecondary(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              receipt['planPrice'],
                              style: _getTextStyle(context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Plan Type",
                              style: _getTextStyle(context,
                                  fontSize: 11,
                                  color: _textColorSecondary(context)),
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
                                  fontFamily: _primaryFontFamily,
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
                            onPressed: () => _approveSubscription(receipt),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: _textColorOnPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Approve',
                              style: _getTextStyle(context,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textColorOnPrimary),
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
      },
    );
  }
}

class UsersListPage extends StatelessWidget {
  final String currentUserId;
  const UsersListPage({super.key, required this.currentUserId});

  String getChatRoomId(String userA, String userB) {
    if (userA.compareTo(userB) > 0) {
      return "$userB\_$userA";
    } else {
      return "$userA\_$userB";
    }
  }

  Future<Map<String, dynamic>> getLastMessage(
      BuildContext context, String chatRoomId, String otherUserName) async {
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

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentScaffoldBg =
    isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final Color currentTabLabel = _textColorPrimary(context);
    final Color currentIndicator = _primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: currentScaffoldBg,
        appBar: AppBar(
          backgroundColor: _cardBgColor(context),
          elevation: 1,
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
                      top: 8,
                      right: -2,
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
                          int unreadCount = snapshot.data!.docs.length;
                          return Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collection("Users").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No clients to chat with yet.",
                      style: _getTextStyle(context,
                          fontSize: 16, color: _textColorPrimary(context)),
                    ),
                  );
                }

                final users = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                  const Divider(height: 0.5, indent: 88, endIndent: 16),
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    if (userDoc.id == currentUserId) {
                      return const SizedBox.shrink();
                    }

                    final data = userDoc.data() as Map<String, dynamic>;
                    final senderName =
                    "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                        .trim();
                    final chatRoomId =
                    getChatRoomId(currentUserId, userDoc.id);

                    return FutureBuilder<Map<String, dynamic>>(
                      future: getLastMessage(context, chatRoomId, senderName),
                      builder: (context, snapshotMessage) {
                        String subtitleText = "No messages yet";
                        String timeText = "";

                        if (snapshotMessage.connectionState ==
                            ConnectionState.done &&
                            snapshotMessage.hasData) {
                          final lastMsg = snapshotMessage.data!;
                          final lastMessage = lastMsg["message"] ?? "";
                          timeText = lastMsg["time"] ?? "";

                          if (lastMessage.isNotEmpty) {
                            subtitleText = (lastMsg["isMe"] ?? false)
                                ? "You: $lastMessage"
                                : lastMessage;
                          }
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (data["profile"] != null &&
                                data["profile"].toString().isNotEmpty)
                                ? NetworkImage(data["profile"])
                                : null,
                            child: (data["profile"] == null ||
                                data["profile"].toString().isEmpty)
                                ? Icon(Icons.person_outline,
                                color: _primaryColor)
                                : null,
                          ),
                          title: Text(senderName, style: _getTextStyle(context)),
                          subtitle: Text(subtitleText,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: _getTextStyle(context, fontSize: 13, color: _textColorSecondary(context)),
                          ),
                          trailing: timeText.isNotEmpty
                              ? Text(timeText,
                              style: const TextStyle(fontSize: 12))
                              : null,
                          onTap: () {
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
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(currentUserId)
                  .collection("notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No notifications"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp? timestamp = data["timestamp"] as Timestamp?;
                    String formattedTime = "";

                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      final now = DateTime.now();
                      if (date.year == now.year && date.month == now.month && date.day == now.day) {
                        formattedTime = DateFormat.jm().format(date);
                      } else if (date.year == now.year && date.month == now.month && date.day == now.day -1) {
                        formattedTime = "Yesterday";
                      } else {
                        formattedTime = DateFormat('MMM d').format(date);
                      }
                    }

                    IconData notificationIcon = Icons.notifications_none;
                    Color iconColor = _primaryColor;

                    if (data["type"] == "message") {
                      notificationIcon = Icons.chat_bubble_outline_rounded;
                    } else if (data["type"] == "appointment" || data["type"] == "appointment_update") {
                      notificationIcon = Icons.event_available_outlined;
                    }

                    bool isRead = data["isRead"] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      elevation: 1.5,
                      color: _cardBgColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: () async {
                          if (!isRead) {
                            await FirebaseFirestore.instance
                                .collection("Users")
                                .doc(currentUserId)
                                .collection("notifications")
                                .doc(doc.id)
                                .update({"isRead": true});
                          }

                          if (data["type"] == "message" && data["senderId"] != null && data["senderName"] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessagesPageDietitian(
                                  receiverId: data["senderId"],
                                  receiverName: data["senderName"],
                                  currentUserId: currentUserId,
                                  receiverProfile: data["receiverProfile"] ?? "",
                                ),
                              ),
                            );
                          } else if (data["type"] == "appointment" || data["type"] == "appointment_update") {
                            // You can add navigation to the schedule page here
                            // For now, it just marks as read
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              if (!isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 12.0),
                                  decoration: const BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(width: 10 + 12.0),

                              Icon(
                                notificationIcon,
                                color: isRead ? _textColorSecondary(context).withOpacity(0.7) : iconColor,
                                size: 26.0,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data["title"] ?? "Notification",
                                      style: _getTextStyle(
                                        context,
                                        fontSize: 15.5,
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                        color: _textColorPrimary(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      data["message"] ?? "",
                                      style: _getTextStyle(
                                        context,
                                        fontSize: 13,
                                        color: _textColorSecondary(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (formattedTime.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    formattedTime,
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 11.5,
                                      color: _textColorSecondary(context).withOpacity(0.8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            )
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
            final appointmentDateTime =
            DateFormat('yyyy-MM-dd HH:mm').parse(appointmentDateStr);
            final dateOnly = DateTime.utc(
                appointmentDateTime.year,
                appointmentDateTime.month,
                appointmentDateTime.day);
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
    final normalizedDay =
    DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _showScheduleAppointmentDialog(DateTime selectedDate) async {
    final User? currentDietitian = FirebaseAuth.instance.currentUser;
    if (currentDietitian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in.')),
      );
      return;
    }

    TimeOfDay? selectedTime = TimeOfDay.now();
    String? selectedClientId;
    String selectedClientName = "Select Client";
    TextEditingController notesController = TextEditingController();
    List<DocumentSnapshot> clients = [];

    try {
      QuerySnapshot clientSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'user')
          .get();
      clients = clientSnapshot.docs;
    } catch (e) {
      print("Error fetching clients: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching clients: $e')),
      );
      return;
    }

    if (clients.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('No clients found to schedule an appointment with.')),
      );
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
                    style: _getTextStyle(dialogContext,
                        fontWeight: FontWeight.bold, fontSize: 18)),
                backgroundColor: _cardBgColor(dialogContext),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      if (clients.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Client',
                            labelStyle: _getTextStyle(dialogContext,
                                color: _textColorSecondary(dialogContext)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: _scaffoldBgColor(dialogContext),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          value: selectedClientId,
                          hint: Text(selectedClientName,
                              style: _getTextStyle(dialogContext,
                                  color: selectedClientId == null
                                      ? _textColorSecondary(dialogContext)
                                      : _textColorPrimary(dialogContext))),
                          dropdownColor: _cardBgColor(dialogContext),
                          items: clients.map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                            document.data()! as Map<String, dynamic>;
                            String name =
                            "${data['firstName'] ?? ''} ${data['lastName'] ??
                                ''}"
                                .trim();
                            if (name.isEmpty) {
                              name = "Client ID: ${document.id.substring(0, 5)}";
                            }
                            return DropdownMenuItem<String>(
                              value: document.id,
                              child: Text(name,
                                  style: _getTextStyle(dialogContext,
                                      color: _textColorPrimary(dialogContext))),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setStateDialog(() {
                              selectedClientId = newValue;
                              if (newValue != null) {
                                final clientDoc = clients
                                    .firstWhere((doc) => doc.id == newValue);
                                final clientData =
                                clientDoc.data() as Map<String, dynamic>;
                                selectedClientName =
                                    "${clientData['firstName'] ??
                                        ''} ${clientData['lastName'] ?? ''}"
                                        .trim();
                                if (selectedClientName.isEmpty) {
                                  selectedClientName = "Client ID: ${newValue.substring(0, 5)}";
                                }
                              } else {
                                selectedClientName = "Select Client";
                              }
                            });
                          },
                          validator: (value) =>
                          value == null ? 'Please select a client' : null,
                        )
                      else
                        Text("No clients available.",
                            style: _getTextStyle(dialogContext)),
                      const SizedBox(height: 15),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.access_time_filled_rounded,
                            color: _primaryColor),
                        title: Text(
                            'Time: ${selectedTime?.format(dialogContext) ??
                                'Tap to select'}',
                            style: _getTextStyle(dialogContext)),
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
                          labelStyle: _getTextStyle(dialogContext,
                              color: _textColorSecondary(dialogContext)),
                          hintText: 'Details for this appointment?',
                          hintStyle: _getTextStyle(dialogContext,
                              color: _textColorSecondary(dialogContext)
                                  .withOpacity(0.7)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: _scaffoldBgColor(dialogContext),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        style: _getTextStyle(dialogContext),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel',
                        style: _getTextStyle(dialogContext,
                            color: _textColorSecondary(dialogContext))),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _textColorOnPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text('Send Schedule',
                        style: _getTextStyle(dialogContext,
                            color: _textColorOnPrimary,
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (selectedClientId == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text(
                              'Please select a client.')),
                        );
                        return;
                      }
                      if (selectedTime == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please select an appointment time.')),
                        );
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
                        dietitianDisplayName = (widget.dietitianFirstName
                            .isNotEmpty ||
                            widget.dietitianLastName.isNotEmpty)
                            ? "${widget.dietitianFirstName} ${widget
                            .dietitianLastName}"
                            .trim()
                            : currentDietitian.displayName ?? "Dietitian";
                      }

                      _saveScheduleToFirestore(
                        dietitianId: currentDietitian.uid,
                        dietitianName: dietitianDisplayName,
                        clientId: selectedClientId!,
                        clientName: selectedClientName,
                        appointmentDateTime: finalAppointmentDateTime,
                        notes: notesController.text.trim(),
                        status: 'proposed_by_dietitian',
                        contextForSnackBar: this.context,
                      );
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            });
      },
    );
  }

  Future<void> _saveScheduleToFirestore({
    required String dietitianId,
    required String dietitianName,
    required String clientId,
    required String clientName,
    required DateTime appointmentDateTime,
    required String notes,
    required String status,
    required BuildContext contextForSnackBar, }) async {

    try {
      final String appointmentDateStr =
      DateFormat('yyyy-MM-dd HH:mm').format(appointmentDateTime);
      final String createdAtStr =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

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
        "title": "New Appointment",
        "message":
        "$dietitianName scheduled an appointment with you on ${DateFormat
            .yMMMMd().format(appointmentDateTime)} at ${DateFormat.jm().format(
            appointmentDateTime)}.",
        "type": "appointment",
        "receiverId": clientId,
        "receiverName": clientName,
        "senderId": dietitianId,
        "senderName": dietitianName,
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(contextForSnackBar).showSnackBar(
        SnackBar(
          content: Text('Schedule proposed to $clientName successfully!'),
          backgroundColor: _primaryColor,
        ),
      );
      _loadAppointmentsForCalendar();
    } catch (e) {
      print("Error saving schedule: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(contextForSnackBar).showSnackBar(
        SnackBar(
          content: Text('Error saving schedule: $e'),
          backgroundColor: Colors.redAccent,
        ),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        color: _primaryColor, shape: BoxShape.circle),
                    selectedTextStyle: _getTextStyle(context,
                        color: _textColorOnPrimary,
                        fontWeight: FontWeight.bold),
                    todayDecoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle),
                    todayTextStyle: _getTextStyle(context,
                        color: _textColorOnPrimary,
                        fontWeight: FontWeight.bold),
                    weekendTextStyle: _getTextStyle(context,
                        color: _primaryColor.withOpacity(0.8)),
                    defaultTextStyle: _getTextStyle(context,
                        color: _textColorPrimary(context)),
                    markersMaxCount: 1,
                    markerSize: 5,
                    markerDecoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  titleTextStyle: _getTextStyle(context,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColorPrimary(context)),
                  formatButtonTextStyle:
                  _getTextStyle(context, color: _textColorOnPrimary),
                  formatButtonDecoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(20.0)),
                  leftChevronIcon: Icon(Icons.chevron_left,
                      color: _textColorPrimary(context)),
                  rightChevronIcon: Icon(Icons.chevron_right,
                      color: _textColorPrimary(context)),
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
              ),
            ),
          ),
          if (_isLoadingEvents)
            const Expanded(
              child: Center(
                  child: CircularProgressIndicator(color: _primaryColor)),
            )
          else
            if (_selectedDay != null)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Details for ${DateFormat.yMMMMd().format(
                            _selectedDay!)}:",
                        style: _getTextStyle(context,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textColorPrimary(context)),
                      ),
                      const SizedBox(height: 10),
                      _buildScheduledAppointmentsList(_selectedDay!),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: _textColorOnPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              textStyle: _getTextStyle(context,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _textColorOnPrimary)),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text("Schedule New Appointment"),
                          onPressed: () {
                            if (_selectedDay != null) {
                              _showScheduleAppointmentDialog(_selectedDay!);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please select a day on the calendar first!')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              if (!_isLoadingEvents)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Select a day to see appointments.",
                        style: _getTextStyle(
                            context, color: _textColorSecondary(context)),
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
        color: _cardBgColor(context),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No appointments scheduled for this day yet.",
              style: _getTextStyle(
                  context, color: _textColorSecondary(context)),
            ),
          ),
        ),
      );
    }

    dayEvents.sort((a, b) {
      try {
        final dateA =
        DateFormat('yyyy-MM-dd HH:mm').parse(a['appointmentDate']);
        final dateB =
        DateFormat('yyyy-MM-dd HH:mm').parse(b['appointmentDate']);
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _cardBgColor(context),
          child: ListTile(
            title: Text("${data['clientName'] ?? 'Unknown Client'}",
                style: _getTextStyle(context, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Time: $formattedTime", style: _getTextStyle(context)),
                Text("Status: ${data['status'] ?? 'pending'}",
                    style: _getTextStyle(context)),
                if ((data['notes'] ?? '')
                    .toString()
                    .isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("Notes: ${data['notes']}", style: _getTextStyle(
                        context, fontSize: 13, color: _textColorSecondary(
                        context))),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}