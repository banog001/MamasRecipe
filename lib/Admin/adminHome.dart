import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';
import 'package:rxdart/rxdart.dart';

import '../email/rejectPayment.dart';

const String _primaryFontFamily = 'PlusJakartaSans';

const Color _backgroundColor = Color(0xFF121212); // Deep charcoal background
const Color _surfaceColor = Color(0xFF1E1E1E); // Slightly lighter for cards
const Color _primaryColor = Color(
  0xFF0D63F5,
); // Professional vibrant blue (was green #4CAF50)
const Color _textColorOnPrimary = Colors.white;
const Color _hintColor = Color(0xFFAAAAAA); // Subtle grey for hints
const Color _errorColor = Color(
  0xFFCF6679,
); // Material Design error color for dark themes

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF121212) // Deep charcoal (was Colors.grey.shade900)
    : Colors.grey.shade100;

Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(
        0xFF1E1E1E,
      ) // Slightly lighter surface (was Colors.grey.shade800)
    : Colors.white;

Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.white
    : Colors.black87;

Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFAAAAAA) // Subtle grey (was Colors.white54)
    : Colors.black54;

TextStyle _getTextStyle(
  BuildContext context, {
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    fontFamily: _primaryFontFamily,
  );
}

TextStyle _cardTitleStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: _primaryColor,
);

TextStyle _cardSubtitleStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 12,
  color: _textColorSecondary(context),
);

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String selectedPage = "Home";
  String crudFilter = "All";
  Set<String> selectedUserIds = {};
  bool isMultiSelectMode = false;
  String chartFilter = "Week";

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  // Add this method inside the _AdminHomeState class

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text(
              "Confirm Logout",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(fontFamily: _primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          // Pop all routes and return to the first screen (your login screen)
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/', // Replace with your LOGIN screen's route name
            (route) => false,
          );

          // Alternative: If the above doesn't work, try this instead:
          // Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Error: $e",
                      style: const TextStyle(fontFamily: _primaryFontFamily),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: isTablet ? 200 : 240,
              decoration: BoxDecoration(
                color: _cardBgColor(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: _textColorOnPrimary,
                            size: 28,
                          ),
                        ),
                        if (!isTablet) ...[
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Papa's Panel",
                              style: TextStyle(
                                color: _textColorOnPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: _primaryFontFamily,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSidebarItem(
                    Icons.home_outlined,
                    Icons.home,
                    "Home",
                    isTablet,
                  ),
                  _buildSidebarItem(
                    Icons.settings_outlined,
                    Icons.settings,
                    "CRUD",
                    isTablet,
                  ),
                  _buildSidebarItem(
                    Icons.check_circle_outlined,
                    Icons.check_circle,
                    "QR Approval",
                    isTablet,
                  ),
                  _buildSidebarItem(
                    Icons.account_balance_wallet_outlined, // outline version
                    Icons.account_balance_wallet,          // filled version
                    "Dietitian Payment",
                    isTablet,
                  ),
                  _buildSidebarItem(
                    Icons.message_outlined,
                    Icons.message,
                    "Messages",
                    isTablet,
                  ),
                  const Spacer(),
                  const Divider(indent: 16, endIndent: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 22,
                            ),
                            if (!isTablet) ...[
                              const SizedBox(width: 12),
                              const Text(
                                "Logout",
                                style: TextStyle(
                                  fontFamily: _primaryFontFamily,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: _cardBgColor(context),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            ),
                          if (isMobile) const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dashboard",
                                style: _getTextStyle(
                                  context,
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: _primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: _textColorOnPrimary,
                                size: 18,
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 10),
                              Text(
                                "PAPA",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isMobile
                      ? _buildMobileLayout()
                      : Row(
                          children: [
                            Expanded(child: _buildMainContent()),
                            if (selectedPage == "Home" && isDesktop)
                              Container(
                                width: 280,
                                color: _scaffoldBgColor(context),
                                child: Column(
                                  children: [
                                    Expanded(child: _buildDietitianPanel()),
                                    Expanded(child: _buildUsersPanel()),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _cardBgColor(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: _textColorOnPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Papa's Panel",
                    style: TextStyle(
                      color: _textColorOnPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: _primaryFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(Icons.home_outlined, Icons.home, "Home", false),
          _buildSidebarItem(
            Icons.settings_outlined,
            Icons.settings,
            "CRUD",
            false,
          ),
          _buildSidebarItem(
            Icons.check_circle_outlined,
            Icons.check_circle,
            "QR Approval",
            false,
          ),
          _buildSidebarItem(
            Icons.message_outlined,
            Icons.message,
            "Messages",
            false,
          ),
          const Spacer(),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleLogout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red, size: 22),
                      const SizedBox(width: 12),
                      const Text(
                        "Logout",
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.normal,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (selectedPage == "Home") {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionHeader("Key Metrics"),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: _buildUserCreationChart()),
            const SizedBox(height: 16),
            _buildAppointmentAnalytics(),
            const SizedBox(height: 16),
            // ============ NEW: Revenue & Commissions Section ============
            _buildSectionHeader("Revenue & Commissions"),
            const SizedBox(height: 12),
            SizedBox(height: 400, child: _buildDietitianRevenueAnalytics()),
            const SizedBox(height: 16),
            // ============ NEW: Revenue Trends Section ============
            _buildSectionHeader("Revenue Trends"),
            const SizedBox(height: 12),
            SizedBox(height: 400, child: _buildRevenueTrendChart()),
            const SizedBox(height: 16),
            // ============ NEW: Subscription Status Section ============
            // ============ NEW: Top Performers Section ============
            _buildSectionHeader("Top Performers"),
            const SizedBox(height: 12),
            _buildTopPerformingDietitians(),
            const SizedBox(height: 16),
            // ============ EXISTING: Performance Section ============
            _buildSectionHeader("Performance"),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: _buildMealPlanPerformance()),
            const SizedBox(height: 16),
            _buildUserSubscriptionChurn(),
            const SizedBox(height: 16),
            // ============ EXISTING: Insights Section ============
            _buildSectionHeader("Insights"),
            const SizedBox(height: 12),
            _buildHealthGoalsDistribution(),
            const SizedBox(height: 16),
            _buildUserDemographics(),
            const SizedBox(height: 16),
            // ============ EXISTING: Activity Section ============
            _buildSectionHeader("Activity"),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: _buildDietitianActivityHistory()),
            const SizedBox(height: 16),
            SizedBox(height: 300, child: _buildMealPlansWithLikes()),
          ],
        ),
      );
    } else {
      return _buildMainContent();
    }
  }

  Widget _buildSidebarItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String title,
    bool isCompact,
  ) {
    final isSelected = selectedPage == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedPage = title;
              if (MediaQuery.of(context).size.width < 768) {
                Navigator.pop(context);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _primaryColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? filledIcon : outlinedIcon,
                  color: isSelected
                      ? _primaryColor
                      : _textColorSecondary(context),
                  size: 22,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: _getTextStyle(
                      context,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? _primaryColor
                          : _textColorPrimary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (selectedPage == "Home") {
      return _buildHomeDashboard();
    } else if (selectedPage == "CRUD") {
      return _buildCrudTable();
    } else if (selectedPage == "User Verification") {
      return _buildUserVerificationPage();
    } else if (selectedPage == "Dietitian Verification") {
      return _buildDietitianVerificationPage();
    } else if (selectedPage == "QR Approval") {
      return _buildQRApprovalPage();
    } else if (selectedPage == "Dietitian Payment"){
      return _buildDietitianPaymentPage();
    } else if (selectedPage == "Messages") {
      return _buildMessagesPage();
    }
    return Container();
  }

  Widget _buildHomeDashboard() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet =
        MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;

    return Container(
      color: _scaffoldBgColor(context),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: SingleChildScrollView(
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============ EXISTING: Key Metrics Section ============
                  _buildSectionHeader("Key Metrics"),
                  const SizedBox(height: 12),
                  _buildUserCreationChart(),
                  const SizedBox(height: 16),
                  _buildAppointmentAnalytics(),
                  const SizedBox(height: 16),

                  // ============ NEW: Revenue & Commissions Section ============
                  _buildSectionHeader("Revenue & Commissions"),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: _buildDietitianRevenueAnalytics(),
                  ),
                  const SizedBox(height: 16),

                  // ============ NEW: Revenue Trends Section ============
                  _buildSectionHeader("Revenue Trends"),
                  const SizedBox(height: 12),
                  SizedBox(height: 400, child: _buildRevenueTrendChart()),
                  const SizedBox(height: 16),

                  // ============ NEW: Subscription Status Section ============

                  // ============ NEW: Top Performers Section ============
                  _buildSectionHeader("Top Performers"),
                  const SizedBox(height: 12),
                  _buildTopPerformingDietitians(),
                  const SizedBox(height: 16),

                  // ============ EXISTING: Performance Section ============
                  _buildSectionHeader("Performance"),
                  const SizedBox(height: 12),
                  _buildMealPlanPerformance(),
                  const SizedBox(height: 16),
                  _buildUserSubscriptionChurn(),
                  const SizedBox(height: 16),

                  // ============ EXISTING: Insights Section ============
                  _buildSectionHeader("Insights"),
                  const SizedBox(height: 12),
                  _buildHealthGoalsDistribution(),
                  const SizedBox(height: 16),
                  _buildUserDemographics(),
                  const SizedBox(height: 16),

                  // ============ EXISTING: Activity Section ============
                  _buildSectionHeader("Activity"),
                  const SizedBox(height: 12),
                  _buildDietitianActivityHistory(),
                  const SizedBox(height: 16),
                  _buildMealPlansWithLikes(),
                ],
              )
            : Column(
                children: [
                  // ============ EXISTING: Key Metrics Section ============
                  _buildSectionHeader("Key Metrics"),
                  const SizedBox(height: 12),
                  _buildUserCreationChart(),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isTablet ? 1 : 1,
                        child: _buildAppointmentAnalytics(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: isTablet ? 1 : 1,
                        child: _buildMealPlanPerformance(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildUserSubscriptionChurn()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildHealthGoalsDistribution()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildUserDemographics(),
                  const SizedBox(height: 16),

                  // ============ NEW: Revenue & Commissions Section ============
                  _buildSectionHeader("Revenue & Commissions"),
                  const SizedBox(height: 12),
                  _buildDietitianRevenueAnalytics(),
                  const SizedBox(height: 16),

                  // ============ NEW: Top Performers Section ============
                  _buildSectionHeader("Top Performers"),
                  const SizedBox(height: 12),
                  _buildTopPerformingDietitians(),
                  const SizedBox(height: 16),

                  // ============ EXISTING: Activity Section ============
                  _buildSectionHeader("Activity"),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDietitianActivityHistory()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMealPlansWithLikes()),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // Replace the _buildUserCreationChart() and _buildAreaChart() methods with this code

  Widget _buildUserCreationChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bar_chart, color: _primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "User Growth Analytics",
                      style: _getTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildChartFilterButton("Week"),
                    const SizedBox(width: 8),
                    _buildChartFilterButton("Month"),
                    const SizedBox(width: 8),
                    _buildChartFilterButton("Year"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('role', whereIn: ['user', 'dietitian'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final users = snapshot.data!.docs;
                final totalUsers = users.length;
                final chartData = _processUserCreationData(users, chartFilter);
                final newUsersThisPeriod = _calculateNewUsersPeriod(
                  users,
                  chartFilter,
                );

                return Column(
                  children: [
                    // Summary Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            "Total Users",
                            totalUsers.toString(),
                            _primaryColor,
                            Icons.people,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            "New Users (${chartFilter})",
                            newUsersThisPeriod.toString(),
                            Colors.blue,
                            Icons.person_add,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Bar Chart
                    SizedBox(height: 280, child: _buildBarChart(chartData)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Metric Card Widget
  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: _getTextStyle(
                    context,
                    fontSize: 12,
                    color: _textColorSecondary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: _getTextStyle(
              context,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Bar Chart using fl_chart
  // REPLACE your _buildBarChart method with this fixed version:

  Widget _buildBarChart(Map<String, dynamic> chartData) {
    final labels = chartData['labels'] as List<String>;
    final values = chartData['values'] as List<int>;
    final maxY = chartData['maxY'] as double;

    // Calculate interval ensuring it's never zero or too small
    final interval = (maxY / 5).ceil().toDouble();
    final safeInterval = interval < 1.0 ? 1.0 : interval;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < values.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i].toDouble(),
              color: _primaryColor,
              width: 74,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: safeInterval, // Use the safe interval here
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: _textColorSecondary(context).withOpacity(0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: _textColorSecondary(context).withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: safeInterval, // Use the safe interval here too
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: _getTextStyle(context, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: _getTextStyle(context, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: _textColorSecondary(context).withOpacity(0.2),
          ),
        ),
        maxY: maxY + 1,
        minY: 0,
        barTouchData: BarTouchData(enabled: false),
        groupsSpace: 8,
      ),
    );
  }

  // Calculate new users in the current period
  int _calculateNewUsersPeriod(
    List<QueryDocumentSnapshot> users,
    String period,
  ) {
    final now = DateTime.now();
    int count = 0;

    for (var doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp =
          data['createdAt'] as Timestamp? ?? data['creationDate'] as Timestamp?;

      if (timestamp != null) {
        final date = timestamp.toDate();

        if (period == "Week") {
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          if (date.isAfter(sevenDaysAgo)) count++;
        } else if (period == "Month") {
          final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
          if (date.isAfter(oneMonthAgo)) count++;
        } else if (period == "Year") {
          final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
          if (date.isAfter(oneYearAgo)) count++;
        }
      }
    }

    return count;
  }

  // Calculate growth trend percentage
  String _calculateGrowthTrend(
    List<QueryDocumentSnapshot> users,
    String period,
  ) {
    final now = DateTime.now();
    int currentCount = 0;
    int previousCount = 0;

    for (var doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp =
          data['createdAt'] as Timestamp? ?? data['creationDate'] as Timestamp?;

      if (timestamp != null) {
        final date = timestamp.toDate();

        if (period == "Week") {
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          final fourteenDaysAgo = now.subtract(const Duration(days: 14));

          if (date.isAfter(sevenDaysAgo)) {
            currentCount++;
          } else if (date.isAfter(fourteenDaysAgo)) {
            previousCount++;
          }
        } else if (period == "Month") {
          final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
          final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);

          if (date.isAfter(oneMonthAgo)) {
            currentCount++;
          } else if (date.isAfter(twoMonthsAgo)) {
            previousCount++;
          }
        } else if (period == "Year") {
          final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
          final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);

          if (date.isAfter(oneYearAgo)) {
            currentCount++;
          } else if (date.isAfter(twoYearsAgo)) {
            previousCount++;
          }
        }
      }
    }

    if (previousCount == 0) return "New";

    final trend = ((currentCount - previousCount) / previousCount * 100)
        .toStringAsFixed(1);
    return "$trend%";
  }

  // Updated data processing - excludes today for Week view
  // REPLACE your _processUserCreationData method with this corrected version:

  Map<String, dynamic> _processUserCreationData(
    List<QueryDocumentSnapshot> users,
    String chartFilter,
  ) {
    final now = DateTime.now();
    Map<String, int> dateCounts = {};
    List<String> dateKeys = [];
    List<String> labels = [];

    // Generate keys and labels
    if (chartFilter == "Week") {
      // Week: last 7 complete days (excluding today)
      for (int i = 7; i >= 1; i--) {
        final date = now.subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(date);
        dateCounts[key] = 0;
        dateKeys.add(key);
        labels.add(DateFormat('EEE').format(date)); // Mon, Tue, etc
      }
    } else if (chartFilter == "Month") {
      // Month: last 12 complete months
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('yyyy-MM').format(date);
        dateCounts[key] = 0;
        dateKeys.add(key);
        labels.add(DateFormat('MMM').format(date)); // Jan, Feb, etc
      }
    } else {
      // Year: last 7 years - FIXED to use current year as reference
      final currentYear = now.year;
      for (int i = 6; i >= 0; i--) {
        final year = currentYear - i;
        final key = year.toString();
        dateCounts[key] = 0;
        dateKeys.add(key);
        labels.add(year.toString());
      }
    }

    // Count user creations
    for (var doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp =
          data['createdAt'] as Timestamp? ?? data['creationDate'] as Timestamp?;

      if (timestamp != null) {
        final date = timestamp.toDate();

        String key;
        if (chartFilter == "Week") {
          key = DateFormat('yyyy-MM-dd').format(date);
        } else if (chartFilter == "Month") {
          // FIXED: Corrected DateTime constructor order
          key = DateFormat(
            'yyyy-MM',
          ).format(DateTime(date.year, date.month, 1));
        } else {
          key = date.year.toString();
        }

        if (dateCounts.containsKey(key)) {
          dateCounts[key] = dateCounts[key]! + 1;
        }
      }
    }

    // Map values in correct order
    final values = dateKeys.map((k) => dateCounts[k]!).toList();
    final maxY = values.isEmpty
        ? 10.0
        : values.reduce((a, b) => a > b ? a : b).toDouble();

    return {'labels': labels, 'values': values, 'maxY': maxY};
  }

  Widget _buildChartFilterButton(String filter) {
    final isSelected = chartFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          chartFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? _primaryColor
                : _textColorSecondary(context).withOpacity(0.3),
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? _textColorOnPrimary
                : _textColorPrimary(context),
            fontFamily: _primaryFontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildQRApprovalPage() {
    return Container(
      color: _scaffoldBgColor(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "QR Code Approval",
            style: _getTextStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Review and approve dietitian QR codes",
            style: _cardSubtitleStyle(context),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('role', isEqualTo: 'dietitian')
                  .where('qrstatus', isEqualTo: 'pending')
                  .where('qrapproved', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: _primaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No pending QR requests",
                          style: _getTextStyle(context, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: _cardBgColor(context),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            _primaryColor.withOpacity(0.1),
                          ),
                          headingRowHeight: 56,
                          dataRowHeight: 72,
                          columns: [
                            DataColumn(
                              label: Text(
                                "Profile",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Name",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Email",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Status",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "QR Code",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Actions",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ],
                          rows: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final docId = doc.id;
                            final firstName = data['firstName'] ?? '';
                            final lastName = data['lastName'] ?? '';
                            final email = data['email'] ?? '';
                            final qrstatus = data['qrstatus'] ?? 'pending';
                            final profileUrl = data['profile'] ?? '';
                            final qrCodeUrl = data['qrCode'] ?? '';

                            return DataRow(
                              cells: [
                                DataCell(
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _primaryColor.withOpacity(
                                      0.2,
                                    ),
                                    backgroundImage: profileUrl.isNotEmpty
                                        ? NetworkImage(profileUrl)
                                        : null,
                                    child: profileUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: _primaryColor,
                                          )
                                        : null,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "$firstName $lastName",
                                    style: _getTextStyle(
                                      context,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    email,
                                    style: _getTextStyle(context, fontSize: 14),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      qrstatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[700],
                                        fontFamily: _primaryFontFamily,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  qrCodeUrl.isNotEmpty
                                      ? ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor:
                                                _textColorOnPrimary,
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        "QR Code Preview",
                                                        style: _getTextStyle(
                                                          context,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Image.network(
                                                        qrCodeUrl,
                                                        width: 300,
                                                        height: 300,
                                                        fit: BoxFit.contain,
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Close",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.visibility,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            "View",
                                            style: TextStyle(
                                              fontFamily: _primaryFontFamily,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          "No QR Code",
                                          style: _cardSubtitleStyle(context),
                                        ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: _textColorOnPrimary,
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    "Confirm Approval",
                                                    style: TextStyle(
                                                      fontFamily:
                                                          _primaryFontFamily,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                "Approve QR code for $firstName $lastName?",
                                                style: const TextStyle(
                                                  fontFamily:
                                                      _primaryFontFamily,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      fontFamily:
                                                          _primaryFontFamily,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    "Approve",
                                                    style: TextStyle(
                                                      fontFamily:
                                                          _primaryFontFamily,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(docId)
                                                .update({
                                                  'qrstatus': 'approved',
                                                  'qrapproved': true,
                                                });

                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "$firstName $lastName approved!",
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              _primaryFontFamily,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text(
                                          "Approve",
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: _textColorOnPrimary,
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    "Confirm Rejection",
                                                    style: TextStyle(
                                                      fontFamily:
                                                          _primaryFontFamily,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                "Reject QR code for $firstName $lastName?",
                                                style: const TextStyle(
                                                  fontFamily:
                                                      _primaryFontFamily,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      fontFamily:
                                                          _primaryFontFamily,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    "Reject",
                                                    style: TextStyle(
                                                      fontFamily:
                                                          _primaryFontFamily,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(docId)
                                                .update({
                                                  'qrstatus': 'rejected',
                                                  'qrapproved': false,
                                                });

                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.cancel,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "$firstName $lastName rejected",
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              _primaryFontFamily,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text(
                                          "Reject",
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietitianPaymentPage() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payment, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Commission Payment Verification",
                    style: _getTextStyle(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('commissionPayments')
                    .orderBy('submittedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  }

                  final payments = snapshot.data!.docs;

                  if (payments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No payment submissions yet",
                              style: _cardSubtitleStyle(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Separate payments by status
                  final pendingPayments = payments.where((doc) =>
                  (doc.data() as Map<String, dynamic>)['status'] == 'pending'
                  ).toList();

                  final verifiedPayments = payments.where((doc) =>
                  (doc.data() as Map<String, dynamic>)['status'] == 'verified'
                  ).toList();

                  final rejectedPayments = payments.where((doc) =>
                  (doc.data() as Map<String, dynamic>)['status'] == 'rejected'
                  ).toList();

                  return Column(
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaymentStatusCard(
                              "Pending",
                              pendingPayments.length.toString(),
                              Colors.orange,
                              Icons.hourglass_empty,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPaymentStatusCard(
                              "Verified",
                              verifiedPayments.length.toString(),
                              Colors.green,
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPaymentStatusCard(
                              "Rejected",
                              rejectedPayments.length.toString(),
                              Colors.red,
                              Icons.cancel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Payment List
                      _buildPaymentList(payments),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCard(
      String label,
      String count,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: _getTextStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: _getTextStyle(
              context,
              fontSize: 12,
              color: _textColorSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(List<QueryDocumentSnapshot> payments) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _scaffoldBgColor(context),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600), // Add max height
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          itemCount: payments.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final paymentData = payments[index].data() as Map<String, dynamic>;
            final paymentId = payments[index].id;

            return _buildPaymentCard(paymentId, paymentData);
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(String paymentId, Map<String, dynamic> data) {
    final dietitianName = data['dietitianName'] ?? 'Unknown';
    final dietitianEmail = data['dietitianEmail'] ?? '';
    final amount = data['amount'] ?? 0.0;
    final status = data['status'] ?? 'pending';
    final receiptImageUrl = data['receiptImageUrl'] ?? '';
    final paymentMethod = data['paymentMethod'] ?? 'N/A';
    final submittedAt = data['submittedAt'] as Timestamp?;
    final verifiedAt = data['verifiedAt'] as Timestamp?;
    final verifiedBy = data['verifiedBy'] ?? '';
    final notes = data['notes'] ?? '';
    final receiptIds = data['receiptIds'] as List<dynamic>? ?? [];

    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'verified'
        ? Colors.green
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    status == 'pending'
                        ? Icons.hourglass_empty
                        : status == 'verified'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dietitianName,
                        style: _getTextStyle(
                          context,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (dietitianEmail.isNotEmpty)
                        Text(
                          dietitianEmail,
                          style: _cardSubtitleStyle(context).copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFamily: _primaryFontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Payment Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount",
                      style: _cardSubtitleStyle(context),
                    ),
                    Text(
                      "₱${amount.toStringAsFixed(2)}",
                      style: _getTextStyle(
                        context,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Method",
                      style: _cardSubtitleStyle(context),
                    ),
                    Text(
                      paymentMethod,
                      style: _getTextStyle(
                        context,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Receipts Covered",
                      style: _cardSubtitleStyle(context),
                    ),
                    Text(
                      receiptIds.length.toString(),
                      style: _getTextStyle(
                        context,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Timestamps
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  "Submitted: ${submittedAt != null ? DateFormat('MMM dd, yyyy hh:mm a').format(submittedAt.toDate()) : 'N/A'}",
                  style: _cardSubtitleStyle(context).copyWith(fontSize: 12),
                ),
              ],
            ),
            if (verifiedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.verified, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    "${status == 'verified' ? 'Verified' : 'Rejected'}: ${DateFormat('MMM dd, yyyy hh:mm a').format(verifiedAt.toDate())}",
                    style: _cardSubtitleStyle(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],

            // Notes
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: _cardSubtitleStyle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceiptImage(receiptImageUrl),
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text(
                      "View Receipt",
                      style: TextStyle(fontFamily: _primaryFontFamily),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (status == 'pending') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyPayment(paymentId, data),
                      icon: const Icon(Icons.check, size: 18, color: Colors.white),
                      label: const Text(
                        "Verify",
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectPayment(paymentId, data),
                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
                      label: const Text(
                        "Reject",
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Payment Receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: _primaryFontFamily,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyPayment(String paymentId, Map<String, dynamic> data) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text(
              "Verify Payment",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dietitian: ${data['dietitianName']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: _primaryFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Amount: ₱${(data['amount'] as double).toStringAsFixed(2)}",
              style: const TextStyle(fontFamily: _primaryFontFamily),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: "Notes (optional)",
                hintText: "Add verification notes...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final adminId = FirebaseAuth.instance.currentUser!.uid;

                await FirebaseFirestore.instance
                    .collection('commissionPayments')
                    .doc(paymentId)
                    .update({
                  'status': 'verified',
                  'verifiedAt': FieldValue.serverTimestamp(),
                  'verifiedBy': adminId,
                  'notes': notesController.text.trim(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment verified successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              "Verify",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _rejectPayment(String paymentId, Map<String, dynamic> data) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 12),
            Text(
              "Reject Payment",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dietitian: ${data['dietitianName']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: _primaryFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Amount: ₱${(data['amount'] as double).toStringAsFixed(2)}",
              style: const TextStyle(fontFamily: _primaryFontFamily),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: "Reason for rejection *",
                hintText: "Explain why payment is rejected...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final adminId = FirebaseAuth.instance.currentUser!.uid;
                final adminDoc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(adminId)
                    .get();
                final adminName = adminDoc.data()?['name'] ?? 'Admin';

                // Get dietitian ID - try multiple possible field names
                String? dietitianId = data['dietitianID'] as String?;

                // If dietitianId is null, try to get it from dietitianEmail by querying Users
                if (dietitianId == null || dietitianId.isEmpty) {
                  final dietitianEmail = data['dietitianEmail'] as String?;
                  if (dietitianEmail != null && dietitianEmail.isNotEmpty) {
                    final dietitianQuery = await FirebaseFirestore.instance
                        .collection('Users')
                        .where('email', isEqualTo: dietitianEmail)
                        .limit(1)
                        .get();

                    if (dietitianQuery.docs.isNotEmpty) {
                      dietitianId = dietitianQuery.docs.first.id;
                    }
                  }
                }

                // If still no dietitianId, show error
                if (dietitianId == null || dietitianId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Could not find dietitian ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final dietitianEmail = data['dietitianEmail'] as String? ?? '';
                final dietitianName = data['dietitianName'] as String? ?? 'Unknown';
                final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                final rejectionReason = notesController.text.trim();
                final receiptIds = data['receiptIds'] as List<dynamic>? ?? [];

                // Get backup values for restoration
                final backupTotalRevenue = (data['backupTotalRevenue'] as num?)?.toDouble() ?? 0.0;
                final backupTotalCommission = (data['backupTotalCommission'] as num?)?.toDouble() ?? 0.0;
                final backupTotalEarnings = (data['backupTotalEarnings'] as num?)?.toDouble() ?? 0.0;
                final backupWeeklyCommission = (data['backupWeeklyCommission'] as num?)?.toDouble() ?? 0.0;
                final backupMonthlyCommission = (data['backupMonthlyCommission'] as num?)?.toDouble() ?? 0.0;
                final backupYearlyCommission = (data['backupYearlyCommission'] as num?)?.toDouble() ?? 0.0;

                // Get current overallEarnings to subtract the rejected payment earnings
                final dietitianDoc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(dietitianId)
                    .get();
                final currentOverallEarnings = (dietitianDoc.data()?['overallEarnings'] as num?)?.toDouble() ?? 0.0;
                final rejectedEarnings = backupTotalRevenue - backupTotalCommission;

                // Reset commission paid status on receipts and restore backup values
                final batch = FirebaseFirestore.instance.batch();

                for (var receiptId in receiptIds) {
                  final receiptRef = FirebaseFirestore.instance
                      .collection('receipts')
                      .doc(receiptId.toString());
                  batch.update(receiptRef, {
                    'commissionPaid': false,
                    'commissionPaymentId': FieldValue.delete(),
                    'commissionPaidAt': FieldValue.delete(),
                  });
                }

                // Update payment status
                final paymentRef = FirebaseFirestore.instance
                    .collection('commissionPayments')
                    .doc(paymentId);
                batch.update(paymentRef, {
                  'status': 'rejected',
                  'verifiedAt': FieldValue.serverTimestamp(),
                  'verifiedBy': adminId,
                  'notes': rejectionReason,
                });

                // RESTORE backup values to Users collection
                final userRef = FirebaseFirestore.instance
                    .collection('Users')
                    .doc(dietitianId);
                batch.set(userRef, {
                  'totalRevenue': backupTotalRevenue,
                  'totalCommission': backupTotalCommission,
                  'totalEarnings': backupTotalEarnings,
                  'weeklyCommission': backupWeeklyCommission,
                  'monthlyCommission': backupMonthlyCommission,
                  'yearlyCommission': backupYearlyCommission,
                }, SetOptions(merge: true));

                // Add notification to dietitian's subcollection
                final notificationRef = FirebaseFirestore.instance
                    .collection('Users')
                    .doc(dietitianId)
                    .collection('notifications')
                    .doc();

                batch.set(notificationRef, {
                  'isRead': false,
                  'message': rejectionReason,
                  'senderId': adminId,
                  'senderName': adminName,
                  'timestamp': FieldValue.serverTimestamp(),
                  'title': 'Payment Rejected',
                  'type': 'rejectedPayment',
                  'paymentId': paymentId,
                  'amount': amount,
                });

                await batch.commit();

                // Send email notification (only if email exists)
                if (dietitianEmail.isNotEmpty) {
                  try {
                    await rejectPayment.sendPaymentRejectionEmail(
                      dietitianEmail: dietitianEmail,
                      dietitianName: dietitianName,
                      amount: amount,
                      rejectionReason: rejectionReason,
                      adminName: adminName,
                    );
                  } catch (emailError) {
                    print('Email sending failed: $emailError');
                    // Continue even if email fails
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment rejected. Values restored to dietitian account.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                print('Error rejecting payment: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              "Reject",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietitianActivityHistory() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Text(
                  "Dietitian Activity History",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mealPlans')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final mealPlans = snapshot.data!.docs;

                if (mealPlans.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        "No meal plans uploaded yet",
                        style: _cardSubtitleStyle(context),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mealPlans.length,
                  itemBuilder: (context, index) {
                    final mealPlan =
                        mealPlans[index].data() as Map<String, dynamic>;
                    final ownerId = mealPlan['owner'] ?? '';
                    final planType = mealPlan['planType'] ?? 'Unknown';
                    final timestamp = mealPlan['timestamp'] as Timestamp?;
                    final timeAgo = timestamp != null
                        ? _getTimeAgo(timestamp.toDate())
                        : 'Unknown time';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Users')
                          .doc(ownerId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String dietitianName = 'Unknown Dietitian';
                        String profileUrl = '';

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData =
                              userSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                          final firstName = userData?['firstName'] ?? '';
                          final lastName = userData?['lastName'] ?? '';
                          dietitianName = "$firstName $lastName".trim();
                          profileUrl = userData?['profile'] ?? '';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _scaffoldBgColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange.withOpacity(0.2),
                                backgroundImage: profileUrl.isNotEmpty
                                    ? NetworkImage(profileUrl)
                                    : null,
                                child: profileUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.orange,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dietitianName,
                                      style: _getTextStyle(
                                        context,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Uploaded $planType meal plan",
                                      style: _cardSubtitleStyle(context),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                timeAgo,
                                style: _getTextStyle(
                                  context,
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildMealPlansWithLikes() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Text(
                  "Popular Meal Plans",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mealPlans')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final mealPlans = snapshot.data!.docs;

                if (mealPlans.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        "No meal plans available",
                        style: _cardSubtitleStyle(context),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mealPlans.length,
                  itemBuilder: (context, index) {
                    final mealPlanDoc = mealPlans[index];
                    final mealPlan = mealPlanDoc.data() as Map<String, dynamic>;
                    final ownerId = mealPlan['owner'] ?? '';
                    final planType = mealPlan['planType'] ?? 'Unknown';

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('mealPlans')
                          .doc(mealPlanDoc.id)
                          .collection('likes')
                          .get(),
                      builder: (context, likesSnapshot) {
                        final likesCount = likesSnapshot.hasData
                            ? likesSnapshot.data!.docs.length
                            : 0;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(ownerId)
                              .get(),
                          builder: (context, userSnapshot) {
                            String dietitianName = 'Unknown Dietitian';
                            String profileUrl = '';

                            if (userSnapshot.hasData &&
                                userSnapshot.data!.exists) {
                              final userData =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>?;
                              final firstName = userData?['firstName'] ?? '';
                              final lastName = userData?['lastName'] ?? '';
                              dietitianName = "$firstName $lastName".trim();
                              profileUrl = userData?['profile'] ?? '';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _scaffoldBgColor(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.purple.withOpacity(
                                      0.2,
                                    ),
                                    backgroundImage: profileUrl.isNotEmpty
                                        ? NetworkImage(profileUrl)
                                        : null,
                                    child: profileUrl.isEmpty
                                        ? const Icon(
                                            Icons.restaurant_menu,
                                            color: Colors.purple,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          planType,
                                          style: _getTextStyle(
                                            context,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "by $dietitianName",
                                          style: _cardSubtitleStyle(context),
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
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Colors.purple,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          likesCount.toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.purple,
                                            fontFamily: _primaryFontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesPage() {
    return Container(
      color: _scaffoldBgColor(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Messages",
            style: _getTextStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select a user or dietitian to start chatting",
            style: _cardSubtitleStyle(context),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildUsersList()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildChatArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? selectedChatUserId;
  String? selectedChatUserName;
  String? selectedChatUserProfile;

  Widget _buildUsersList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.message, color: _primaryColor),
                const SizedBox(width: 12),
                Text(
                  "Conversations",
                  style: _getTextStyle(
                    context,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final messages = snapshot.data!.docs;
                final currentUserId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';

                Map<String, Map<String, dynamic>> uniqueConversations = {};

                for (var doc in messages) {
                  final data = doc.data() as Map<String, dynamic>;
                  final senderId = data['senderID'] ?? '';
                  final receiverId = data['receiverID'] ?? '';

                  // Determine the "other user" (not the current admin)
                  final otherUserId = senderId == currentUserId
                      ? receiverId
                      : senderId;

                  // Only add if we haven't seen this user before (ensures no duplicates)
                  if (otherUserId.isNotEmpty &&
                      !uniqueConversations.containsKey(otherUserId)) {
                    uniqueConversations[otherUserId] = {
                      ...data,
                      'otherUserId': otherUserId,
                      'docId': doc.id,
                    };
                  }
                }

                final sortedChats = uniqueConversations.values.toList()
                  ..sort((a, b) {
                    final aTime = a['timestamp'] as Timestamp?;
                    final bTime = b['timestamp'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });

                if (sortedChats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        "No conversations yet",
                        style: _cardSubtitleStyle(context),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: sortedChats.length,
                  itemBuilder: (context, index) {
                    final messageData = sortedChats[index];
                    final senderId = messageData['senderID'] ?? '';
                    final senderName = messageData['senderName'] ?? 'Unknown';
                    final message = messageData['message'] ?? '';
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    final otherUserId = messageData['otherUserId'] ?? '';

                    final displayName = senderId == currentUserId
                        ? messageData['receiverName'] ?? 'Unknown'
                        : senderName;

                    final timeAgo = timestamp != null
                        ? _getTimeAgo(timestamp.toDate())
                        : 'Unknown';

                    final isSelected = selectedChatUserId == otherUserId;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String profileUrl = '';

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData =
                              userSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                          profileUrl = userData?['profile'] ?? '';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: isSelected ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: _primaryColor.withOpacity(0.2),
                              backgroundImage: profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: _primaryColor,
                                    )
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              style: _getTextStyle(
                                context,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  "${senderId == currentUserId ? 'You' : senderName}: \"$message\"",
                                  style: _cardSubtitleStyle(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeAgo,
                                  style: _getTextStyle(
                                    context,
                                    fontSize: 11,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectedChatUserId = otherUserId;
                                selectedChatUserName = displayName;
                                selectedChatUserProfile = profileUrl;
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (selectedChatUserId == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _cardBgColor(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: _primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "Select a user to start chatting",
                style: _getTextStyle(context, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatRoomId = _getChatRoomId(currentUserId, selectedChatUserId!);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _textColorOnPrimary.withOpacity(0.2),
                  backgroundImage:
                      selectedChatUserProfile != null &&
                          selectedChatUserProfile!.isNotEmpty
                      ? NetworkImage(selectedChatUserProfile!)
                      : null,
                  child:
                      selectedChatUserProfile == null ||
                          selectedChatUserProfile!.isEmpty
                      ? const Icon(Icons.person, color: _textColorOnPrimary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedChatUserName ?? "User",
                    style: const TextStyle(
                      color: _textColorOnPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: _primaryFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .where("chatRoomID", isEqualTo: chatRoomId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet. Say hi!",
                      style: _cardSubtitleStyle(context),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = message["senderID"] == currentUserId;
                    final messageText = message["message"] ?? "";
                    final timestamp = message["timestamp"] as Timestamp?;
                    final timeStr = timestamp != null
                        ? DateFormat('hh:mm a').format(timestamp.toDate())
                        : '';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? _primaryColor
                              : _scaffoldBgColor(context),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isMe ? 16 : 4),
                            topRight: Radius.circular(isMe ? 4 : 16),
                            bottomLeft: const Radius.circular(16),
                            bottomRight: const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: TextStyle(
                                fontSize: 14,
                                color: isMe
                                    ? _textColorOnPrimary
                                    : _textColorPrimary(context),
                                fontFamily: _primaryFontFamily,
                              ),
                            ),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? _textColorOnPrimary.withOpacity(0.7)
                                      : _textColorSecondary(context),
                                  fontFamily: _primaryFontFamily,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _scaffoldBgColor(context),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: _cardSubtitleStyle(context),
                      filled: true,
                      fillColor: _cardBgColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(currentUserId),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => _sendMessage(currentUserId),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.send_rounded,
                        color: _textColorOnPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChatRoomId(String userA, String userB) {
    return userA.compareTo(userB) <= 0 ? '$userA\_$userB' : '$userB\_$userA';
  }

  Future<void> _sendMessage(String currentUserId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || selectedChatUserId == null) return;

    _messageController.clear();
    final chatRoomId = _getChatRoomId(currentUserId, selectedChatUserId!);

    final adminDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .get();
    final adminData = adminDoc.data() as Map<String, dynamic>?;
    final adminName =
        "${adminData?['firstName'] ?? 'Admin'} ${adminData?['lastName'] ?? ''}"
            .trim();

    await FirebaseFirestore.instance.collection("messages").add({
      "senderID": currentUserId,
      "senderName": adminName,
      "receiverID": selectedChatUserId!,
      "receiverName": selectedChatUserName ?? "User",
      "message": text,
      "timestamp": FieldValue.serverTimestamp(),
      "chatRoomID": chatRoomId,
      "read": "false",
    });

    await FirebaseFirestore.instance
        .collection("Users")
        .doc(selectedChatUserId!)
        .collection("notifications")
        .add({
          "title": "New Message from Admin",
          "message": "$adminName: $text",
          "senderId": currentUserId,
          "senderName": adminName,
          "receiverId": selectedChatUserId!,
          "receiverName": selectedChatUserName ?? "User",
          "receiverProfile": selectedChatUserProfile ?? "",
          "type": "message",
          "isRead": false,
          "timestamp": FieldValue.serverTimestamp(),
        });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Replace your _buildCrudTable() method with this updated version that includes Verification tabs

  Widget _buildCrudTable() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _scaffoldBgColor(context),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton("All"),
                      const SizedBox(width: 8),
                      _buildFilterButton("Users"),
                      const SizedBox(width: 8),
                      _buildFilterButton("Dietitians"),
                      const SizedBox(width: 8),
                      _buildFilterButton("Meal Plans"),
                      // Removed "User Verification" and "Dietitian Verification" from here
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  // Button to navigate to User Verification page
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: _textColorOnPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () =>
                        setState(() => selectedPage = "User Verification"),
                    icon: const Icon(Icons.verified_user, size: 18),
                    label: Text(
                      isMobile ? "User Ver." : "User Verification",
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Button to navigate to Dietitian Verification page
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: _textColorOnPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () =>
                        setState(() => selectedPage = "Dietitian Verification"),
                    icon: const Icon(Icons.health_and_safety, size: 18),
                    label: Text(
                      isMobile ? "Diet. Ver." : "Dietitian Verification",
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isMultiSelectMode && selectedUserIds.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: _textColorOnPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () => _showMultiDeleteConfirmation(),
                      icon: const Icon(Icons.delete_sweep, size: 20),
                      label: Text(
                        "Delete (${selectedUserIds.length})",
                        style: const TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                  if (isMultiSelectMode && selectedUserIds.isNotEmpty)
                    const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isMultiSelectMode ? Icons.close : Icons.checklist,
                      color: isMultiSelectMode ? Colors.red : _primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        isMultiSelectMode = !isMultiSelectMode;
                        if (!isMultiSelectMode) {
                          selectedUserIds.clear();
                        }
                      });
                    },
                    tooltip: isMultiSelectMode ? "Cancel" : "Multi-select",
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColorOnPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => _showAddUserDialog(),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: Text(
                      isMobile ? "Add" : "Add User",
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getEmptyIcon(),
                          size: 80,
                          color: _primaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No ${crudFilter.toLowerCase()} found",
                          style: _getTextStyle(context, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data!.docs;

                if (crudFilter == "Meal Plans") {
                  return _buildMealPlansTable(items);
                } else if (crudFilter == "Verifications") {
                  return _buildVerificationsTable(items);
                } else {
                  return _buildUsersTable(items);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // REPLACE your _buildUserVerificationPage() with this:

  Widget _buildUserVerificationPage() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _scaffoldBgColor(context),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "User Verification",
                style: _getTextStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _textColorOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() => selectedPage = "CRUD"),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text("Back to CRUD"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Review and verify pending user accounts from notVerifiedUsers",
              style: _cardSubtitleStyle(context),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notVerifiedUsers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 80,
                          color: _primaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No unverified users pending",
                          style: _getTextStyle(context, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return _buildUserVerificationsTable(snapshot.data!.docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  // REPLACE your _buildDietitianVerificationPage() with this:

  Widget _buildDietitianVerificationPage() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _scaffoldBgColor(context),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Dietitian Verification",
                style: _getTextStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _textColorOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() => selectedPage = "CRUD"),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text("Back to CRUD"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Review and verify pending dietitian accounts",
              style: _cardSubtitleStyle(context),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('dietitianApproval')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 80,
                          color: Colors.orange.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No unverified dietitians pending",
                          style: _getTextStyle(context, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return _buildDietitianVerificationsTable(snapshot.data!.docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fixed: Dietitian Verification Table with Move Logic
  Widget _buildDietitianVerificationsTable(
    List<QueryDocumentSnapshot> dietitians,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                Colors.orange.withOpacity(0.1),
              ),
              headingRowHeight: 56,
              dataRowHeight: 64,
              columns: [
                DataColumn(
                  label: Text(
                    "First Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Last Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Email",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "License Number",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Actions",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
              rows: dietitians.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final firstName = data['firstName'] ?? "No first name";
                final lastName = data['lastName'] ?? "No last name";
                final email = data['email'] ?? "No email";
                final licenseNum = (data['licenseNum'] ?? "N/A").toString();
                final profileUrl = data['prcImageUrl'] ?? data['profile'] ?? '';

                return DataRow(
                  cells: [
                    DataCell(Text(firstName, style: _getTextStyle(context))),
                    DataCell(Text(lastName, style: _getTextStyle(context))),
                    DataCell(
                      Text(email, style: _getTextStyle(context, fontSize: 14)),
                    ),
                    DataCell(
                      Text(
                        licenseNum,
                        style: _getTextStyle(context, fontSize: 14),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: _textColorOnPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Verify Dietitian",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Verify $firstName $lastName as a dietitian?",
                                    style: const TextStyle(
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        "Verify",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  // Prepare the data to move to Users collection
                                  final newDietitianData = {
                                    'uid': docId,
                                    'firstName': firstName,
                                    'lastName': lastName,
                                    'email': email,
                                    'role': 'dietitian',
                                    'status': 'offline',
                                    'profile': profileUrl,
                                    'licenseNum': licenseNum,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };

                                  // Step 1: Add to Users collection
                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(docId)
                                      .set(newDietitianData);

                                  // Step 2: Delete from dietitianApproval collection
                                  await FirebaseFirestore.instance
                                      .collection('dietitianApproval')
                                      .doc(docId)
                                      .delete();

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "$firstName $lastName verified as dietitian!",
                                              style: const TextStyle(
                                                fontFamily: _primaryFontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print(
                                    "Error during dietitian verification: $e",
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Error: $e",
                                                style: const TextStyle(
                                                  fontFamily:
                                                      _primaryFontFamily,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text(
                              "Accept",
                              style: TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _showDeleteDietitianVerificationConfirmation(
                                  docId,
                                  firstName,
                                ),
                            tooltip: "Delete unverified dietitian",
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Delete Dietitian Verification Confirmation
  void _showDeleteDietitianVerificationConfirmation(
    String docId,
    String firstName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              "Confirm Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete $firstName from unverified dietitians? This action cannot be undone.",
          style: const TextStyle(fontFamily: _primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection("dietitianApproval")
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Unverified dietitian deleted successfully",
                          style: TextStyle(fontFamily: _primaryFontFamily),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Failed to delete dietitian",
                          style: TextStyle(fontFamily: _primaryFontFamily),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  // NEW METHOD: User Verifications Table
  Widget _buildUserVerificationsTable(List<QueryDocumentSnapshot> users) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                _primaryColor.withOpacity(0.1),
              ),
              headingRowHeight: 56,
              dataRowHeight: 64,
              columns: [
                DataColumn(
                  label: Text(
                    "First Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Last Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Email",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Actions",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
              rows: users.map((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final firstName = user['firstName'] ?? "No first name";
                final lastName = user['lastName'] ?? "No last name";
                final email = user['email'] ?? "No email";

                return DataRow(
                  cells: [
                    DataCell(Text(firstName, style: _getTextStyle(context))),
                    DataCell(Text(lastName, style: _getTextStyle(context))),
                    DataCell(
                      Text(email, style: _getTextStyle(context, fontSize: 14)),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: _textColorOnPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Verify User",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Verify $firstName $lastName as a user?",
                                    style: const TextStyle(
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        "Verify",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  // Move user from notVerifiedUsers to Users
                                  final newUserData = {
                                    ...user,
                                    'uid': docId,
                                    'role': 'user',
                                    'status': 'offline',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };

                                  // Add to Users collection
                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(docId)
                                      .set(newUserData);

                                  // Delete from notVerifiedUsers
                                  await FirebaseFirestore.instance
                                      .collection('notVerifiedUsers')
                                      .doc(docId)
                                      .delete();

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "$firstName $lastName verified!",
                                              style: const TextStyle(
                                                fontFamily: _primaryFontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print("Error verifying user: $e");
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Error: $e",
                                                style: const TextStyle(
                                                  fontFamily:
                                                      _primaryFontFamily,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text(
                              "Accept",
                              style: TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _showDeleteUserVerificationConfirmation(
                                  docId,
                                  firstName,
                                ),
                            tooltip: "Delete unverified user",
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Dietitian Verification Tab
  Widget _buildDietitianVerificationTab(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dietitianApproval')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 80,
                  color: Colors.orange.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "No unverified dietitians pending",
                  style: _getTextStyle(context, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return _buildDietitianVerificationsTable(snapshot.data!.docs);
      },
    );
  }

  IconData _getEmptyIcon() {
    switch (crudFilter) {
      case "Meal Plans":
        return Icons.restaurant_menu_outlined;
      case "User Verification":
        return Icons.person_outline;
      case "Dietitian Verification":
        return Icons.health_and_safety;
      default:
        return Icons.people_outline;
    }
  }

  Widget _buildUsersTable(List<QueryDocumentSnapshot> users) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                _primaryColor.withOpacity(0.1),
              ),
              headingRowHeight: 56,
              dataRowHeight: 64,
              columns: [
                if (isMultiSelectMode)
                  DataColumn(
                    label: Checkbox(
                      value:
                          selectedUserIds.length == users.length &&
                          users.isNotEmpty,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedUserIds = users
                                .map((doc) => doc.id)
                                .toSet();
                          } else {
                            selectedUserIds.clear();
                          }
                        });
                      },
                      activeColor: _primaryColor,
                    ),
                  ),
                DataColumn(
                  label: Text(
                    "First Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Last Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Email",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Status",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Role",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Actions",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Role Change",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
              rows: users.map((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final firstName = user['firstName'] ?? "No first name";
                final lastName = user['lastName'] ?? "No last name";
                final email = user['email'] ?? "No email";
                final status = user['status'] ?? "No status";
                final role = user['role'] ?? "user";

                return DataRow(
                  selected: selectedUserIds.contains(doc.id),
                  onSelectChanged: isMultiSelectMode
                      ? (selected) {
                          setState(() {
                            if (selected == true) {
                              selectedUserIds.add(doc.id);
                            } else {
                              selectedUserIds.remove(doc.id);
                            }
                          });
                        }
                      : null,
                  cells: [
                    if (isMultiSelectMode)
                      DataCell(
                        Checkbox(
                          value: selectedUserIds.contains(doc.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedUserIds.add(doc.id);
                              } else {
                                selectedUserIds.remove(doc.id);
                              }
                            });
                          },
                          activeColor: _primaryColor,
                        ),
                      ),
                    DataCell(Text(firstName, style: _getTextStyle(context))),
                    DataCell(Text(lastName, style: _getTextStyle(context))),
                    DataCell(
                      Text(email, style: _getTextStyle(context, fontSize: 14)),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == "online"
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: status.toLowerCase() == "online"
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontFamily: _primaryFontFamily,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: role == "dietitian"
                              ? _primaryColor.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: role == "dietitian"
                                ? _primaryColor
                                : Colors.blue[700],
                            fontFamily: _primaryFontFamily,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                            ),
                            onPressed: () => _showEditUserDialog(doc.id, user),
                            tooltip: "Edit user",
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _showDeleteConfirmation(doc.id, firstName),
                            tooltip: "Delete user",
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: role == "dietitian"
                              ? Colors.orange
                              : _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () =>
                            _toggleUserRole(doc.id, role, firstName),
                        icon: Icon(
                          role == "dietitian"
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 18,
                        ),
                        label: Text(
                          role == "dietitian" ? "Downgrade" : "Upgrade",
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationsTable(List<QueryDocumentSnapshot> users) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                Colors.orange.withOpacity(0.1),
              ),
              headingRowHeight: 56,
              dataRowHeight: 64,
              columns: [
                DataColumn(
                  label: Text(
                    "First Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Last Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Email",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Role",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Actions",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
              rows: users.map((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final firstName = user['firstName'] ?? "No first name";
                final lastName = user['lastName'] ?? "No last name";
                final email = user['email'] ?? "No email";
                final role = user['role'] ?? "user";

                return DataRow(
                  cells: [
                    DataCell(Text(firstName, style: _getTextStyle(context))),
                    DataCell(Text(lastName, style: _getTextStyle(context))),
                    DataCell(
                      Text(email, style: _getTextStyle(context, fontSize: 14)),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                            fontFamily: _primaryFontFamily,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: _textColorOnPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Confirm Verification",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Accept and move $firstName $lastName to verified users?",
                                    style: const TextStyle(
                                      fontFamily: _primaryFontFamily,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        "Accept",
                                        style: TextStyle(
                                          fontFamily: _primaryFontFamily,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  // Prepare user data with all required fields
                                  final newUserData = {
                                    ...user,
                                    'role': role.isNotEmpty
                                        ? role
                                        : 'user', // Ensure role exists
                                    'status': user['status'] ?? 'offline',
                                    'profile': user['profile'] ?? '',
                                    'email': email,
                                    'firstName': firstName,
                                    'lastName': lastName,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'uid': doc.id,
                                  };

                                  // Add user to Users collection
                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(doc.id)
                                      .set(newUserData);

                                  // Remove from notVerifiedUsers collection
                                  await FirebaseFirestore.instance
                                      .collection('notVerifiedUsers')
                                      .doc(doc.id)
                                      .delete();

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "$firstName $lastName verified!",
                                              style: const TextStyle(
                                                fontFamily: _primaryFontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Error: $e",
                                                style: const TextStyle(
                                                  fontFamily:
                                                      _primaryFontFamily,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text(
                              "Accept",
                              style: TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _showDeleteUserVerificationConfirmation(
                                  doc.id,
                                  firstName,
                                ),
                            tooltip: "Delete unverified user",
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealPlansTable(List<QueryDocumentSnapshot> mealPlans) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                Colors.purple.withOpacity(0.1),
              ),
              headingRowHeight: 56,
              dataRowHeight: 64,
              columns: [
                DataColumn(
                  label: Text(
                    "Plan Type",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Created By",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Date & Time Created",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Actions",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
              rows: mealPlans.map((doc) {
                final mealPlan = doc.data() as Map<String, dynamic>;
                final planType = mealPlan['planType'] ?? "Unknown";
                final ownerId = mealPlan['owner'] ?? "";
                final timestamp = mealPlan['timestamp'] as Timestamp?;
                final dateTimeCreated = timestamp != null
                    ? DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format(timestamp.toDate())
                    : "Unknown";

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          planType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[700],
                            fontFamily: _primaryFontFamily,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(ownerId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "Loading...",
                              style: _getTextStyle(context, fontSize: 14),
                            );
                          }
                          final ownerData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final firstName = ownerData?['firstName'] ?? '';
                          final lastName = ownerData?['lastName'] ?? '';
                          final name = "$firstName $lastName".trim();
                          return Text(
                            name.isEmpty ? "Unknown" : name,
                            style: _getTextStyle(context, fontSize: 14),
                          );
                        },
                      ),
                    ),
                    DataCell(
                      Text(
                        dateTimeCreated,
                        style: _getTextStyle(context, fontSize: 14),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: _textColorOnPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () => _showMealPlanDetails(mealPlan),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text(
                              "View",
                              style: TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _showDeleteMealPlanConfirmation(
                              doc.id,
                              planType,
                            ),
                            tooltip: "Delete meal plan",
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Update your _buildFilterButton to handle new verification pages
  Widget _buildFilterButton(String filter) {
    final isSelected = crudFilter == filter;
    IconData icon;

    switch (filter) {
      case "All":
        icon = Icons.people;
        break;
      case "Users":
        icon = Icons.person;
        break;
      case "Dietitians":
        icon = Icons.health_and_safety;
        break;
      case "User Verification":
        icon = Icons.verified_user;
        break;
      case "Dietitian Verification":
        icon = Icons.verified_user;
        break;
      case "Meal Plans":
        icon = Icons.restaurant_menu;
        break;
      default:
        icon = Icons.people;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            crudFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : _cardBgColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _primaryColor
                  : _primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? _textColorOnPrimary : _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                filter,
                style: TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isSelected ? _textColorOnPrimary : _primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method: Show verification menu
  void _showVerificationMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => Container(
        color: _cardBgColor(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Verification Type",
                style: _getTextStyle(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.person_add_outlined,
                  color: Colors.blue,
                ),
                title: Text(
                  "User Verification",
                  style: _getTextStyle(context, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Verify pending user accounts",
                  style: _cardSubtitleStyle(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selectedPage = "User Verification");
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.health_and_safety,
                  color: Colors.orange,
                ),
                title: Text(
                  "Dietitian Verification",
                  style: _getTextStyle(context, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Verify pending dietitian accounts",
                  style: _cardSubtitleStyle(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selectedPage = "Dietitian Verification");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REPLACE your _getFilteredStream() method with this corrected version:

  Stream<QuerySnapshot> _getFilteredStream() {
    if (crudFilter == "Meal Plans") {
      return FirebaseFirestore.instance
          .collection('mealPlans')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      final baseQuery = FirebaseFirestore.instance
          .collection('Users')
          .where('role', isNotEqualTo: 'admin');

      if (crudFilter == "Users") {
        return baseQuery.where('role', isEqualTo: 'user').snapshots();
      } else if (crudFilter == "Dietitians") {
        return baseQuery.where('role', isEqualTo: 'dietitian').snapshots();
      } else {
        return baseQuery.snapshots();
      }
    }
  }

  void _showMealPlanDetails(Map<String, dynamic> mealPlan) {
    final planType = mealPlan['planType'] ?? "Unknown";
    final breakfast = mealPlan['breakfast'] ?? "Not specified";
    final breakfastTime = mealPlan['breakfastTime'] ?? "";
    final amSnack = mealPlan['amSnack'] ?? "Not specified";
    final amSnackTime = mealPlan['amSnackTime'] ?? "";
    final lunch = mealPlan['lunch'] ?? "Not specified";
    final lunchTime = mealPlan['lunchTime'] ?? "";
    final pmSnack = mealPlan['pmSnack'] ?? "Not specified";
    final pmSnackTime = mealPlan['pmSnackTime'] ?? "";
    final dinner = mealPlan['dinner'] ?? "Not specified";
    final dinnerTime = mealPlan['dinnerTime'] ?? "";
    final midnightSnack = mealPlan['midnightSnack'] ?? "Not specified";
    final midnightSnackTime = mealPlan['midnightSnackTime'] ?? "";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: _textColorOnPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Meal Plan Details",
                            style: TextStyle(
                              color: _textColorOnPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            planType,
                            style: TextStyle(
                              color: _textColorOnPrimary.withOpacity(0.9),
                              fontSize: 14,
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _textColorOnPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMealSection("Breakfast", breakfast, Icons.wb_sunny, breakfastTime),
                      const SizedBox(height: 16),
                      _buildMealSection("AM Snack", amSnack, Icons.fastfood, amSnackTime),
                      const SizedBox(height: 16),
                      _buildMealSection("Lunch", lunch, Icons.lunch_dining, lunchTime),
                      const SizedBox(height: 16),
                      _buildMealSection("PM Snack", pmSnack, Icons.cookie, pmSnackTime),
                      const SizedBox(height: 16),
                      _buildMealSection("Dinner", dinner, Icons.dinner_dining, dinnerTime),
                      const SizedBox(height: 16),
                      _buildMealSection(
                        "Midnight Snack",
                        midnightSnack,
                        Icons.nightlight,
                        midnightSnackTime,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealSection(String title, String meal, IconData icon, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _scaffoldBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.purple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: _getTextStyle(
                        context,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (time.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: _getTextStyle(
                                context,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  meal,
                  style: _cardSubtitleStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW METHOD: Delete confirmation for user verification
  void _showDeleteUserVerificationConfirmation(String docId, String firstName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              "Confirm Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete $firstName from unverified users? This action cannot be undone.",
          style: const TextStyle(fontFamily: _primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection("notVerifiedUsers")
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Unverified user deleted successfully",
                            style: TextStyle(fontFamily: _primaryFontFamily),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Failed to delete user",
                            style: TextStyle(fontFamily: _primaryFontFamily),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteMealPlanConfirmation(String docId, String planType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              "Confirm Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this $planType meal plan? This action cannot be undone.",
          style: const TextStyle(fontFamily: _primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection("mealPlans")
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Meal plan deleted successfully",
                          style: TextStyle(fontFamily: _primaryFontFamily),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Failed to delete meal plan",
                          style: TextStyle(fontFamily: _primaryFontFamily),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = "user";

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add, color: _primaryColor),
              ),
              const SizedBox(width: 12),
              const Text(
                "Add New User",
                style: TextStyle(fontFamily: _primaryFontFamily),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: "First Name",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: "Last Name",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Role",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "user", child: Text("User")),
                      DropdownMenuItem(
                        value: "dietitian",
                        child: Text("Dietitian"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                      });
                    },
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
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "User will need to complete signup with this email",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(fontFamily: _primaryFontFamily),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _textColorOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (firstNameController.text.isEmpty ||
                    lastNameController.text.isEmpty ||
                    emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Please fill all fields",
                            style: TextStyle(fontFamily: _primaryFontFamily),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  return;
                }

                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                );

                try {
                  final docRef = FirebaseFirestore.instance
                      .collection("Users")
                      .doc();
                  final userId = docRef
                      .id; // Changed this to docId, assuming it's passed correctly

                  await docRef.set({
                    "uid": userId,
                    "firstName": firstNameController.text.trim(),
                    "lastName": lastNameController.text.trim(),
                    "email": emailController.text.trim(),
                    "role": selectedRole,
                    "status": "pending",
                    "profile": "",
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  Navigator.of(dialogContext).pop();
                  Navigator.of(dialogContext).pop();

                  await Future.delayed(const Duration(milliseconds: 100));

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Success!",
                                    style: TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${firstNameController.text} ${lastNameController.text} has been added",
                                    style: const TextStyle(
                                      fontFamily: _primaryFontFamily,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: "OK",
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(dialogContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Error: ${e.toString()}",
                              style: const TextStyle(
                                fontFamily: _primaryFontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text(
                "Add",
                style: TextStyle(fontFamily: _primaryFontFamily),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(String docId, Map<String, dynamic> user) {
    final firstNameController = TextEditingController(
      text: user['firstName'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: user['lastName'] ?? '',
    );
    final emailController = TextEditingController(text: user['email'] ?? '');
    String selectedRole = user['role'] ?? "user";
    String selectedStatus = user['status'] ?? "active";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text(
                "Edit User",
                style: TextStyle(fontFamily: _primaryFontFamily),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: "First Name",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: "Last Name",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Role",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "user", child: Text("User")),
                      DropdownMenuItem(
                        value: "dietitian",
                        child: Text("Dietitian"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: "Status",
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "online", child: Text("Online")),
                      DropdownMenuItem(
                        value: "offline",
                        child: Text("Offline"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(fontFamily: _primaryFontFamily),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection("Users")
                      .doc(docId)
                      .update({
                        "firstName": firstNameController.text,
                        "lastName": lastNameController.text,
                        "email": emailController.text,
                        "role": selectedRole,
                        "status": selectedStatus,
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "User updated successfully",
                            style: TextStyle(fontFamily: _primaryFontFamily),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Failed to update user",
                            style: TextStyle(fontFamily: _primaryFontFamily),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "Update",
                style: TextStyle(fontFamily: _primaryFontFamily),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String docId, String firstName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              "Confirm Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete $firstName? This action cannot be undone.",
          style: const TextStyle(fontFamily: _primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection("Users")
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "User deleted successfully",
                          style: TextStyle(fontFamily: _primaryFontFamily),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Failed to delete user",
                          style: TextStyle(fontFamily: _primaryFontFamily),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserRole(
    String docId,
    String currentRole,
    String firstName,
  ) async {
    final newRole = currentRole == "dietitian" ? "user" : "dietitian";
    final action = currentRole == "dietitian" ? "downgraded" : "upgraded";

    try {
      await FirebaseFirestore.instance.collection("Users").doc(docId).update({
        "role": newRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "$firstName $action to ${newRole == 'dietitian' ? 'Dietitian' : 'User'}",
                style: const TextStyle(fontFamily: _primaryFontFamily),
              ),
            ],
          ),
          backgroundColor: newRole == "dietitian"
              ? _primaryColor
              : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Failed to change role",
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Error: $e",
                style: const TextStyle(
                  fontFamily: _primaryFontFamily,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildDietitianPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: _textColorOnPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Dietitians",
                  style: _getTextStyle(
                    context,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _primaryColor,
                  ),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .where('role', isEqualTo: 'dietitian')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: _textColorOnPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: _primaryFontFamily,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('role', isEqualTo: 'dietitian')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No dietitians found",
                        style: _cardSubtitleStyle(context),
                      ),
                    ),
                  );
                }

                final dietitians = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: dietitians.length,
                  itemBuilder: (context, index) {
                    final doc = dietitians[index];
                    final user = doc.data() as Map<String, dynamic>;
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final email = user['email'] ?? 'No email';
                    final profileUrl = user['profile'] ?? '';
                    final status = user['status'] ?? 'offline';
                    final name = "$firstName $lastName".trim();

                    return Card(
                      key: ValueKey(doc.id),
                      margin: const EdgeInsets.only(bottom: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _primaryColor.withOpacity(0.2),
                              backgroundImage: profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: _primaryColor,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: status.toLowerCase() == "online"
                                      ? Colors.green
                                      : Colors.grey,
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
                        title: Text(
                          name.isEmpty ? "Dietitian" : name,
                          style: _getTextStyle(
                            context,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: _cardSubtitleStyle(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: status.toLowerCase() == "online"
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: status.toLowerCase() == "online"
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: _textColorOnPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Users",
                  style: _getTextStyle(
                    context,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _primaryColor,
                  ),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .where('role', isEqualTo: 'user')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: _textColorOnPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: _primaryFontFamily,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('role', isEqualTo: 'user')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No users found",
                        style: _cardSubtitleStyle(context),
                      ),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final user = doc.data() as Map<String, dynamic>;
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final email = user['email'] ?? 'No email';
                    final status = user['status'] ?? 'offline';
                    final profileUrl = user['profile'] ?? '';
                    final name = "$firstName $lastName".trim();

                    return Card(
                      key: ValueKey(doc.id),
                      margin: const EdgeInsets.only(bottom: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _primaryColor.withOpacity(0.2),
                              backgroundImage: profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: _primaryColor,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: status.toLowerCase() == "online"
                                      ? Colors.green
                                      : Colors.grey,
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
                        title: Text(
                          name.isEmpty ? "User" : name,
                          style: _getTextStyle(
                            context,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: _cardSubtitleStyle(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: status.toLowerCase() == "online"
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: status.toLowerCase() == "online"
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(
              "Delete ${selectedUserIds.length} Users?",
              style: _getTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete ${selectedUserIds.length} selected users? This action cannot be undone.",
          style: _getTextStyle(context, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: _getTextStyle(context, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMultipleUsers();
            },
            child: const Text("Delete All"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMultipleUsers() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String userId in selectedUserIds) {
        batch.delete(
          FirebaseFirestore.instance.collection("Users").doc(userId),
        );
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Successfully deleted ${selectedUserIds.length} users",
              style: const TextStyle(fontFamily: _primaryFontFamily),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        setState(() {
          selectedUserIds.clear();
          isMultiSelectMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to delete users: $e",
              style: const TextStyle(fontFamily: _primaryFontFamily),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildAppointmentAnalytics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Text(
                  "Appointment Analytics",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules') // ✅ Listen to ALL schedules
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final schedules = snapshot.data!.docs;
                int confirmed = 0, completed = 0, cancelled = 0;
                int total = 0;

                for (var doc in schedules) {
                  final data = doc.data() as Map<String, dynamic>;

                  // ✅ Skip documents with all fields empty/null
                  if (data.isEmpty ||
                      data.values.every((v) =>
                      v == null ||
                          (v is String && v.trim().isEmpty))) {
                    continue;
                  }

                  total++; // ✅ Only count valid documents

                  final status =
                  (data['status'] ?? '').toString().toLowerCase().trim();

                  if (status == 'confirmed') {
                    confirmed++;
                  } else if (status == 'completed') {
                    completed++;
                  } else if (status == 'cancelled' || status == 'cancel') {
                    cancelled++;
                  }
                }

                final completionRate = total > 0
                    ? (completed / total * 100).toStringAsFixed(1)
                    : '0.0';

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Total",
                            total.toString(),
                            Colors.blue,
                            Icons.event,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Confirmed",
                            confirmed.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Completed",
                            completed.toString(),
                            Colors.purple,
                            Icons.done_all,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Cancelled",
                            cancelled.toString(),
                            Colors.red,
                            Icons.cancel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Completion Rate",
                            style: _getTextStyle(
                              context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "$completionRate%",
                            style: _getTextStyle(
                              context,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
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


  // Helper method for stat cards
  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: _getTextStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: _getTextStyle(
              context,
              fontSize: 12,
              color: _textColorSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanPerformance() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Text(
                  "Meal Plan Performance",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mealPlans')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final allMealPlans = snapshot.data!.docs;

                // ✅ Filter out documents with all empty or null fields, and check creator is not blank
                final validMealPlans = allMealPlans.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final creator = (data['owner'] ?? '').toString().trim();

                  return !(data.isEmpty ||
                      data.values.every((v) =>
                      v == null ||
                          (v is String && v.trim().isEmpty))) &&
                      creator.isNotEmpty;
                }).toList();

                Map<String, int> categoryCount = {};

                for (var doc in validMealPlans) {
                  final data = doc.data() as Map<String, dynamic>;
                  final planType = (data['planType'] ?? 'Unknown').toString().trim();
                  categoryCount[planType] = (categoryCount[planType] ?? 0) + 1;
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Meal Plans",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                validMealPlans.length.toString(),
                                style: _getTextStyle(
                                  context,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...categoryCount.entries.map(
                                (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: _cardSubtitleStyle(context),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber[700],
                                        fontFamily: _primaryFontFamily,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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


  // add async package to pubspec.yaml

  Widget _buildUserSubscriptionChurn() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.subscriptions, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Text(
                  "Subscription Stats",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _getSubscriptionStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  );
                }

                final stats = snapshot.data!;
                final approvedSubscribers = stats['approved'] ?? 0;
                final canceledSubscribers = stats['cancelled'] ?? 0;
                final expiredSubscribers = stats['expired'] ?? 0;

                final total = approvedSubscribers + canceledSubscribers + expiredSubscribers;
                final approvedRate = total > 0
                    ? ((approvedSubscribers / total) * 100).toStringAsFixed(1)
                    : '0.0';
                final canceledRate = total > 0
                    ? ((canceledSubscribers / total) * 100).toStringAsFixed(1)
                    : '0.0';
                final expiredRate = total > 0
                    ? ((expiredSubscribers / total) * 100).toStringAsFixed(1)
                    : '0.0';

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Active",
                            approvedSubscribers.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Cancelled",
                            canceledSubscribers.toString(),
                            Colors.red,
                            Icons.cancel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Expired",
                            expiredSubscribers.toString(),
                            Colors.orange,
                            Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Active Rate",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "$approvedRate%",
                                style: _getTextStyle(
                                  context,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Cancelled Rate",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "$canceledRate%",
                                style: _getTextStyle(
                                  context,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Expired Rate",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "$expiredRate%",
                                style: _getTextStyle(
                                  context,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
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

// Get subscription statistics from different sources
  Future<Map<String, int>> _getSubscriptionStats() async {
    int approvedCount = 0;
    int canceledCount = 0;
    int expiredCount = 0;

    try {
      // Get all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', whereIn: ['user', 'dietitian'])
          .get();

      // 1. Count APPROVED and EXPIRED from subscribeTo subcollection only
      for (var userDoc in usersSnapshot.docs) {
        final subscribeToSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userDoc.id)
            .collection('subscribeTo')
            .get();

        for (var subDoc in subscribeToSnapshot.docs) {
          final data = subDoc.data();
          final status = data['status'] as String?;

          if (status == 'approved') {
            approvedCount++;
          } else if (status == 'expired') {
            expiredCount++;
          }
        }
      }

      // 2. Count CANCELLED from receipts collection
      final receiptsSnapshot = await FirebaseFirestore.instance
          .collection('receipts')
          .where('status', isEqualTo: 'cancelled')
          .get();

      canceledCount = receiptsSnapshot.docs.length;

    } catch (e) {
      print("❌ Error fetching subscription stats: $e");
    }

    return {
      'approved': approvedCount,
      'cancelled': canceledCount,
      'expired': expiredCount,
    };
  }

  // Stream of all subscriber docs from each user's subscribeTo subcollection
  Stream<List<QueryDocumentSnapshot>> _subscribersStream() async* {
    final usersStream = FirebaseFirestore.instance
        .collection('Users')
        .where('role', whereIn: ['user', 'dietitian'])
        .snapshots();

    await for (final usersSnapshot in usersStream) {
      final streams = usersSnapshot.docs.map((userDoc) {
        return FirebaseFirestore.instance
            .collection('Users')
            .doc(userDoc.id)
            .collection('subscribeTo')
            .snapshots();
      }).toList();

      // Combine multiple subcollection streams into one
      yield* StreamGroup.merge(streams)
          .map((snapshot) => snapshot.docs)
          .scan<List<QueryDocumentSnapshot>>(
            (accumulated, current, index) => [...accumulated, ...current],
        [],
      );
    }
  }

  Widget _buildHealthGoalsDistribution() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.pink),
                ),
                const SizedBox(width: 12),
                Text(
                  "Health Goals Distribution",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('role', isEqualTo: 'user')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final users = snapshot.data!.docs;
                Map<String, int> goalCounts = {};

                for (var doc in users) {
                  final data = doc.data() as Map<String, dynamic>;
                  final goal = data['goals'] ?? 'Not Set';
                  goalCounts[goal] = (goalCounts[goal] ?? 0) + 1;
                }

                final sortedGoals = goalCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  children: sortedGoals.map((entry) {
                    final percentage = users.isNotEmpty
                        ? (entry.value / users.length * 100).toStringAsFixed(1)
                        : '0.0';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "${entry.value} users ($percentage%)",
                                style: _getTextStyle(
                                  context,
                                  fontSize: 14,
                                  color: Colors.pink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: users.isNotEmpty
                                ? entry.value / users.length
                                : 0,
                            backgroundColor: Colors.pink.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.pink,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDemographics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.deepOrange),
                ),
                const SizedBox(width: 12),
                Text(
                  "User Demographics & Behavior",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final users = snapshot.data!.docs;
                int regularUsers = 0, dietitians = 0, admins = 0;
                int googleAuth = 0, emailAuth = 0;

                for (var doc in users) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] ?? 'user';
                  final authProvider = data['authProvider'] ?? 'email';

                  if (role == 'user')
                    regularUsers++;
                  else if (role == 'dietitian')
                    dietitians++;
                  else if (role == 'admin')
                    admins++;

                  if (authProvider == 'google')
                    googleAuth++;
                  else
                    emailAuth++;
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Role Distribution",
                            style: _getTextStyle(
                              context,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDemographicRow(
                            "Users",
                            regularUsers,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildDemographicRow(
                            "Dietitians",
                            dietitians,
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildDemographicRow("Admins", admins, Colors.orange),
                        ],
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

  Widget _buildDemographicRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: _getTextStyle(context)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: _primaryFontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: _getTextStyle(
          context,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  // Add this widget to your adminHome.dart file

  Widget _buildDietitianRevenueAnalytics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Text(
                  "Dietitian Revenue & Commissions",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('role', isEqualTo: 'dietitian')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final dietitians = snapshot.data!.docs;

                return Column(
                  children: [
                    // Summary Cards
                    FutureBuilder<Map<String, dynamic>>(
                      future: _calculateTotalRevenueFromReceipts(dietitians),
                      builder: (context, summarySnapshot) {
                        if (!summarySnapshot.hasData) {
                          return const CircularProgressIndicator(
                            color: _primaryColor,
                          );
                        }

                        final summary = summarySnapshot.data!;
                        final totalRevenue = summary['totalRevenue'] as double;
                        final totalCommission =
                        summary['totalCommission'] as double;
                        final totalSubscriptions =
                        summary['totalSubscriptions'] as int;

                        return Column(
                          children: [
                            // Summary Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRevenueMetricCard(
                                    "Total Revenue",
                                    "₱${totalRevenue.toStringAsFixed(2)}",
                                    Colors.blue,
                                    Icons.trending_up,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildRevenueMetricCard(
                                    "Your Commission",
                                    "₱${totalCommission.toStringAsFixed(2)}",
                                    Colors.green,
                                    Icons.account_balance_wallet,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildRevenueMetricCard(
                                    "Total Receipts",
                                    totalSubscriptions.toString(),
                                    Colors.purple,
                                    Icons.receipt_long,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Dietitian Details Table
                            _buildDietitianRevenueTable(dietitians),
                          ],
                        );
                      },
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

  Widget _buildRevenueMetricCard(
      String label,
      String value,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: _getTextStyle(
                    context,
                    fontSize: 12,
                    color: _textColorSecondary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: _getTextStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietitianRevenueTable(List<QueryDocumentSnapshot> dietitians) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _scaffoldBgColor(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                Colors.green.withOpacity(0.1),
              ),
              headingRowHeight: 56,
              dataRowHeight: 64,
              columns: [
                DataColumn(
                  label: Text(
                    "Dietitian Name",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Total Receipts",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Weekly",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Monthly",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Yearly",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Total Revenue",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Your Commission",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Details",
                    style: _getTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              rows: dietitians.map((dietitianDoc) {
                final dietitian = dietitianDoc.data() as Map<String, dynamic>;
                final firstName = dietitian['firstName'] ?? '';
                final lastName = dietitian['lastName'] ?? '';
                final dietitianId = dietitianDoc.id;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        "$firstName $lastName",
                        style: _getTextStyle(
                          context,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Total Receipts Count
                    DataCell(
                      FutureBuilder<int>(
                        future: _getTotalReceiptCount(dietitianId),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.hasData ? snapshot.data.toString() : '0',
                            style: _getTextStyle(context),
                          );
                        },
                      ),
                    ),
                    // Weekly Count
                    DataCell(
                      FutureBuilder<int>(
                        future: _getReceiptCountByType(
                          dietitianId,
                          'weekly',
                        ),
                        builder: (context, snapshot) {
                          return _buildSubscriptionTypeCell(
                            snapshot.hasData ? snapshot.data.toString() : '0',
                            Colors.blue,
                          );
                        },
                      ),
                    ),
                    // Monthly Count
                    DataCell(
                      FutureBuilder<int>(
                        future: _getReceiptCountByType(
                          dietitianId,
                          'monthly',
                        ),
                        builder: (context, snapshot) {
                          return _buildSubscriptionTypeCell(
                            snapshot.hasData ? snapshot.data.toString() : '0',
                            Colors.amber,
                          );
                        },
                      ),
                    ),
                    // Yearly Count
                    DataCell(
                      FutureBuilder<int>(
                        future: _getReceiptCountByType(
                          dietitianId,
                          'yearly',
                        ),
                        builder: (context, snapshot) {
                          return _buildSubscriptionTypeCell(
                            snapshot.hasData ? snapshot.data.toString() : '0',
                            Colors.purple,
                          );
                        },
                      ),
                    ),
                    // Total Revenue
                    DataCell(
                      FutureBuilder<Map<String, double>>(
                        future: _getDietitianRevenueAndCommissionFromReceipts(dietitianId),
                        builder: (context, snapshot) {
                          final revenue = snapshot.hasData
                              ? snapshot.data!['revenue']!
                              : 0.0;
                          return Text(
                            "₱${revenue.toStringAsFixed(2)}",
                            style: _getTextStyle(
                              context,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                    // Your Commission
                    DataCell(
                      FutureBuilder<Map<String, double>>(
                        future: _getDietitianRevenueAndCommissionFromReceipts(dietitianId),
                        builder: (context, snapshot) {
                          final commission = snapshot.hasData
                              ? snapshot.data!['commission']!
                              : 0.0;
                          return Text(
                            "₱${commission.toStringAsFixed(2)}",
                            style: _getTextStyle(
                              context,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                    // View Details Button
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _showDietitianReceiptDetails(
                          dietitianId,
                          "$firstName $lastName",
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text(
                          "View",
                          style: TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionTypeCell(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 13,
          fontFamily: _primaryFontFamily,
        ),
      ),
    );
  }

// Helper method to parse price string to double
  double _parsePriceString(String priceStr) {
    // Remove currency symbol and commas, then parse
    // "₱ 1,199.00" -> "1199.00" -> 1199.00
    final cleanPrice = priceStr.replaceAll(RegExp(r'[₱\s,]'), '');
    return double.tryParse(cleanPrice) ?? 0.0;
  }

// Helper Methods - Updated to use receipts collection

  // Updated helper methods to exclude 'pending' and 'declined' status receipts

  // Updated helper methods to only count UNPAID commissions

  Future<Map<String, dynamic>> _calculateTotalRevenueFromReceipts(
      List<QueryDocumentSnapshot> dietitians,
      ) async {
    double totalRevenue = 0;
    double totalCommission = 0;
    int totalReceipts = 0;

    for (var dietitianDoc in dietitians) {
      final dietitianId = dietitianDoc.id;

      // Get UNPAID receipts only (exclude pending and declined)
      final receipts = await FirebaseFirestore.instance
          .collection('receipts')
          .where('dietitianID', isEqualTo: dietitianId)
          .where('status', whereNotIn: ['pending', 'declined'])
          .where('commissionPaid', isEqualTo: false)
          .get();

      for (var receipt in receipts.docs) {
        final data = receipt.data();
        totalReceipts++;

        final planType = (data['planType'] as String?)?.toLowerCase() ?? '';
        final priceStr = data['planPrice'] as String? ?? '₱ 0.00';
        final price = _parsePriceString(priceStr);

        // Add to total revenue
        totalRevenue += price;

        // Calculate commission
        double commission = 0;
        if (planType == 'weekly') {
          commission = price * 0.15; // 15%
        } else if (planType == 'monthly') {
          commission = price * 0.10; // 10%
        } else if (planType == 'yearly') {
          commission = price * 0.08; // 8%
        }
        totalCommission += commission;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalCommission': totalCommission,
      'totalSubscriptions': totalReceipts,
    };
  }

  Future<int> _getTotalReceiptCount(String dietitianId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('receipts')
        .where('dietitianID', isEqualTo: dietitianId)
        .where('status', whereNotIn: ['pending', 'declined'])
        .where('commissionPaid', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  Future<int> _getReceiptCountByType(
      String dietitianId,
      String planType,
      ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('receipts')
        .where('dietitianID', isEqualTo: dietitianId)
        .where('planType', isEqualTo: planType)
        .where('status', whereNotIn: ['pending', 'declined'])
        .where('commissionPaid', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  Future<Map<String, double>> _getDietitianRevenueAndCommissionFromReceipts(
      String dietitianId,
      ) async {
    // Get UNPAID receipts only (exclude pending and declined)
    final snapshot = await FirebaseFirestore.instance
        .collection('receipts')
        .where('dietitianID', isEqualTo: dietitianId)
        .where('status', whereNotIn: ['pending', 'declined'])
        .where('commissionPaid', isEqualTo: false)
        .get();

    double totalRevenue = 0;
    double totalCommission = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final planType = (data['planType'] as String?)?.toLowerCase() ?? '';
      final priceStr = data['planPrice'] as String? ?? '₱ 0.00';
      final price = _parsePriceString(priceStr);

      // Add to total revenue
      totalRevenue += price;

      // Calculate commission
      if (planType == 'weekly') {
        totalCommission += price * 0.15; // 15%
      } else if (planType == 'monthly') {
        totalCommission += price * 0.10; // 10%
      } else if (planType == 'yearly') {
        totalCommission += price * 0.08; // 8%
      }
    }

    return {
      'revenue': totalRevenue,
      'commission': totalCommission,
    };
  }

  void _showDietitianReceiptDetails(
      String dietitianId,
      String dietitianName,
      )
  {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: _textColorOnPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Receipt Details",
                            style: TextStyle(
                              color: _textColorOnPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                          Text(
                            dietitianName,
                            style: TextStyle(
                              color: _textColorOnPrimary.withOpacity(0.9),
                              fontSize: 14,
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _textColorOnPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('receipts')
                      .where('dietitianID', isEqualTo: dietitianId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    final receipts = snapshot.data!.docs;

                    if (receipts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No receipts found",
                              style: _cardSubtitleStyle(context),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: receipts.length,
                      itemBuilder: (context, index) {
                        final receiptData =
                        receipts[index].data() as Map<String, dynamic>;
                        final clientId = receiptData['clientID'] ?? '';
                        final planType =
                            (receiptData['planType'] as String?)?.toLowerCase() ?? '';
                        final priceStr = receiptData['planPrice'] as String? ?? '₱ 0.00';
                        final price = _parsePriceString(priceStr);
                        final timestamp = receiptData['timeStamp'] as Timestamp?;
                        final status = (receiptData['status'] as String?)?.toLowerCase() ?? '';
                        final receiptImg = receiptData['receiptImg'] as String? ?? '';

                        // Calculate commission for this receipt
                        double commission = 0;
                        String commissionRate = '0%';
                        if (planType == 'weekly') {
                          commission = price * 0.15;
                          commissionRate = '15%';
                        } else if (planType == 'monthly') {
                          commission = price * 0.10;
                          commissionRate = '10%';
                        } else if (planType == 'yearly') {
                          commission = price * 0.08;
                          commissionRate = '8%';
                        }

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(clientId)
                              .get(),
                          builder: (context, userSnapshot) {
                            String userName = 'Loading...';
                            String userEmail = '';

                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>?;
                              final firstName = userData?['firstName'] ?? '';
                              final lastName = userData?['lastName'] ?? '';
                              userName = '$firstName $lastName'.trim();
                              if (userName.isEmpty) userName = 'Unknown User';
                              userEmail = userData?['email'] ?? '';
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.green.withOpacity(0.1),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: _getTextStyle(
                                                  context,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (userEmail.isNotEmpty)
                                                Text(
                                                  userEmail,
                                                  style: _cardSubtitleStyle(context)
                                                      .copyWith(fontSize: 12),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getPlanColor(planType)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                planType.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getPlanColor(planType),
                                                  fontFamily: _primaryFontFamily,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusColor(status),
                                                  fontFamily: _primaryFontFamily,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Price",
                                              style: _cardSubtitleStyle(context),
                                            ),
                                            Text(
                                              priceStr,
                                              style: _getTextStyle(
                                                context,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Commission",
                                              style: _cardSubtitleStyle(context),
                                            ),
                                            Text(
                                              "₱${commission.toStringAsFixed(2)}",
                                              style: _getTextStyle(
                                                context,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Rate",
                                              style: _cardSubtitleStyle(context),
                                            ),
                                            Text(
                                              commissionRate,
                                              style: _getTextStyle(
                                                context,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Date Submitted",
                                                style: _cardSubtitleStyle(context),
                                              ),
                                              Text(
                                                timestamp != null
                                                    ? DateFormat('MMM dd, yyyy hh:mm a')
                                                    .format(timestamp.toDate())
                                                    : 'N/A',
                                                style: _getTextStyle(context),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (receiptImg.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () {
                                          // Show image in a constrained dialog
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Container(
                                                constraints: const BoxConstraints(
                                                  maxWidth: 500,
                                                  maxHeight: 600,
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius: const BorderRadius.only(
                                                          topLeft: Radius.circular(16),
                                                          topRight: Radius.circular(16),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.receipt_long,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(width: 12),
                                                          const Expanded(
                                                            child: Text(
                                                              'Receipt Image',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
                                                                fontFamily: _primaryFontFamily,
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.close,
                                                              color: Colors.white,
                                                            ),
                                                            onPressed: () => Navigator.pop(context),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: SingleChildScrollView(
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(16),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(8),
                                                            child: Image.network(
                                                              receiptImg,
                                                              fit: BoxFit.contain,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                return Center(
                                                                  child: Column(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.broken_image,
                                                                        size: 64,
                                                                        color: Colors.grey[400],
                                                                      ),
                                                                      const SizedBox(height: 8),
                                                                      Text(
                                                                        'Failed to load image',
                                                                        style: TextStyle(
                                                                          color: Colors.grey[600],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 150,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(0.3),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              receiptImg,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey[400],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPlanColor(String planType) {
    switch (planType.toLowerCase()) {
      case 'weekly':
        return Colors.blue;
      case 'monthly':
        return Colors.amber;
      case 'yearly':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'cancelled':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ADVANCED ANALYTICS FEATURES - Add these methods to _AdminHomeState

  // Feature 1: Revenue Trend Over Time
  Widget _buildRevenueTrendChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Text(
                  "Revenue Trend (Last 30 Days)",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getRevenueTrendData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final trendData = snapshot.data!;

                return Column(
                  children: [
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTrendStat(
                            "Avg Daily Revenue",
                            "\$${_calculateAverageDailyRevenue(trendData).toStringAsFixed(2)}",
                            Colors.green,
                          ),
                          _buildTrendStat(
                            "Peak Day Revenue",
                            "\$${_findPeakDayRevenue(trendData).toStringAsFixed(2)}",
                            Colors.blue,
                          ),
                          _buildTrendStat(
                            "Lowest Day Revenue",
                            "\$${_findLowestDayRevenue(trendData).toStringAsFixed(2)}",
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Detailed breakdown
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Colors.teal.withOpacity(0.1),
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              "Date",
                              style: _getTextStyle(
                                context,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Revenue",
                              style: _getTextStyle(
                                context,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Commission (10%)",
                              style: _getTextStyle(
                                context,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "New Subs",
                              style: _getTextStyle(
                                context,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                        ],
                        rows: trendData.map((day) {
                          return DataRow(
                            cells: [
                              DataCell(Text(day['date'] as String)),
                              DataCell(
                                Text(
                                  "\$${(day['revenue'] as double).toStringAsFixed(2)}",
                                  style: _getTextStyle(
                                    context,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  "\$${((day['revenue'] as double) * 0.10).toStringAsFixed(2)}",
                                  style: _getTextStyle(
                                    context,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  (day['newSubscriptions'] as int).toString(),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
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

  // Feature 2: Subscription Status Overview

  Widget _buildStatusCard(
    String label,
    String count,
    Color color,
    String percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _getTextStyle(
              context,
              fontSize: 12,
              color: _textColorSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: _getTextStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$percentage% of total",
            style: _getTextStyle(
              context,
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: _getTextStyle(
            context,
            fontSize: 12,
            color: _textColorSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: _getTextStyle(
            context,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Feature 3: Top Performing Dietitians
  Widget _buildTopPerformingDietitians() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Text(
                  "Top 5 Dietitians (By Revenue)",
                  style: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getTopPerformingDietitians(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final topDietitians = snapshot.data!;

                if (topDietitians.isEmpty) {
                  return Center(
                    child: Text(
                      "No subscription data yet",
                      style: _cardSubtitleStyle(context),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topDietitians.length,
                  itemBuilder: (context, index) {
                    final dietitian = topDietitians[index];
                    final rank = index + 1;
                    final revenue = dietitian['revenue'] as double;
                    final commission = dietitian['commission'] as double; // Get actual commission

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank Badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getRankColor(rank),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "#$rank",
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dietitian Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dietitian['name'] as String,
                                  style: _getTextStyle(
                                    context,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${dietitian['subscriberCount']} subscriber",
                                  style: _cardSubtitleStyle(context),
                                ),
                              ],
                            ),
                          ),
                          // Revenue Info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₱${revenue.toStringAsFixed(2)}", // Changed to ₱
                                style: _getTextStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Commission: ₱${commission.toStringAsFixed(2)}", // Changed to ₱
                                style: _getTextStyle(
                                  context,
                                  fontSize: 11,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.blue;
    }
  }

  // Helper Methods - Backend Queries

  Future<List<Map<String, dynamic>>> _getRevenueTrendData() async {
    List<Map<String, dynamic>> trendData = [];

    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .where('createdAt', isLessThan: Timestamp.fromDate(nextDate))
          .get();

      double dailyRevenue = 0;
      int newSubscriptions = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'active') {
          dailyRevenue += (data['price'] as num?)?.toDouble() ?? 0.0;
          newSubscriptions++;
        }
      }

      trendData.add({
        'date': DateFormat('MMM dd').format(date),
        'revenue': dailyRevenue,
        'newSubscriptions': newSubscriptions,
      });
    }

    return trendData;
  }

  double _calculateAverageDailyRevenue(List<Map<String, dynamic>> data) {
    double total = 0;
    for (var day in data) {
      total += day['revenue'] as double;
    }
    return data.isNotEmpty ? total / data.length : 0;
  }

  double _findPeakDayRevenue(List<Map<String, dynamic>> data) {
    return data.isEmpty
        ? 0
        : data
              .map((d) => d['revenue'] as double)
              .reduce((a, b) => a > b ? a : b);
  }

  double _findLowestDayRevenue(List<Map<String, dynamic>> data) {
    return data.isEmpty
        ? 0
        : data
              .map((d) => d['revenue'] as double)
              .reduce((a, b) => a < b ? a : b);
  }

  Future<List<Map<String, dynamic>>> _getTopPerformingDietitians() async {
    try {
      // Fetch all receipts from Firestore
      final receiptsSnapshot = await FirebaseFirestore.instance
          .collection('receipts')
          .get();

      if (receiptsSnapshot.docs.isEmpty) {
        return [];
      }

      // Map to store dietitian revenue and commission
      Map<String, Map<String, dynamic>> dietitianRevenueMap = {};

      for (var receiptDoc in receiptsSnapshot.docs) {
        final data = receiptDoc.data();
        final dietitianID = data['dietitianID'] as String?;
        final planPriceStr = data['planPrice'] as String?;
        final planType = data['planType'] as String?;

        if (dietitianID == null || planPriceStr == null || planType == null) continue;

        // Parse the price (remove ₱ symbol and convert to double)
        final priceStr = planPriceStr.replaceAll('₱', '').replaceAll(',', '').trim();
        final price = double.tryParse(priceStr) ?? 0.0;

        // Calculate commission based on plan type
        double commissionRate = 0.0;
        switch (planType.toLowerCase()) {
          case 'weekly':
            commissionRate = 0.15; // 15%
            break;
          case 'monthly':
            commissionRate = 0.10; // 10%
            break;
          case 'yearly':
            commissionRate = 0.08; // 8%
            break;
          default:
            commissionRate = 0.10; // Default to 10%
        }

        final commission = price * commissionRate;

        if (dietitianRevenueMap.containsKey(dietitianID)) {
          dietitianRevenueMap[dietitianID]!['revenue'] += price;
          dietitianRevenueMap[dietitianID]!['commission'] += commission;
          dietitianRevenueMap[dietitianID]!['subscriberCount'] += 1;
        } else {
          dietitianRevenueMap[dietitianID] = {
            'dietitianID': dietitianID,
            'revenue': price,
            'commission': commission,
            'subscriberCount': 1,
          };
        }
      }

      // Fetch dietitian names
      for (var dietitianID in dietitianRevenueMap.keys) {
        try {
          final dietitianDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(dietitianID)
              .get();

          if (dietitianDoc.exists) {
            final dietitianData = dietitianDoc.data();
            final firstName = dietitianData?['firstName'] ?? '';
            final lastName = dietitianData?['lastName'] ?? '';
            dietitianRevenueMap[dietitianID]!['name'] = '$firstName $lastName'.trim();
          } else {
            dietitianRevenueMap[dietitianID]!['name'] = 'Unknown Dietitian';
          }
        } catch (e) {
          dietitianRevenueMap[dietitianID]!['name'] = 'Unknown Dietitian';
        }
      }

      // Convert map to list and sort by revenue (descending)
      List<Map<String, dynamic>> dietitiansList = dietitianRevenueMap.values.toList();
      dietitiansList.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      // Return top 5
      return dietitiansList.take(5).toList();

    } catch (e) {
      print('Error fetching top performing dietitians: $e');
      return [];
    }
  }
}
