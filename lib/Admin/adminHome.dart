import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';
import 'package:rxdart/rxdart.dart';

const String _primaryFontFamily = 'PlusJakartaSans';


const Color _backgroundColor = Color(0xFF121212); // Deep charcoal background
const Color _surfaceColor = Color(0xFF1E1E1E); // Slightly lighter for cards
const Color _primaryColor = Color(0xFF0D63F5); // Professional vibrant blue (was green #4CAF50)
const Color _textColorOnPrimary = Colors.white;
const Color _hintColor = Color(0xFFAAAAAA); // Subtle grey for hints
const Color _errorColor = Color(0xFFCF6679); // Material Design error color for dark themes

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212) // Deep charcoal (was Colors.grey.shade900)
        : Colors.grey.shade100;

Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E) // Slightly lighter surface (was Colors.grey.shade800)
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

// REPLACE the logout code in _handleLogout() with this simpler version:

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
            child: const Text("Cancel", style: TextStyle(fontFamily: _primaryFontFamily)),
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
            child: const Text("Logout", style: TextStyle(fontFamily: _primaryFontFamily)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  _buildSidebarItem(Icons.home_outlined, Icons.home, "Home", isTablet),
                  _buildSidebarItem(Icons.settings_outlined, Icons.settings, "CRUD", isTablet),
                  _buildSidebarItem(Icons.check_circle_outlined, Icons.check_circle, "QR Approval", isTablet),
                  _buildSidebarItem(Icons.message_outlined, Icons.message, "Messages", isTablet),
                  const Spacer(),
                  const Divider(indent: 16, endIndent: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.transparent, width: 1),
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
                  )
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
                      Expanded(
                        child: _buildMainContent(),
                      ),
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
                  child: const Icon(Icons.admin_panel_settings, color: _textColorOnPrimary, size: 28,),
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
          _buildSidebarItem(Icons.settings_outlined, Icons.settings, "CRUD", false),
          _buildSidebarItem(Icons.check_circle_outlined, Icons.check_circle, "QR Approval", false),
          _buildSidebarItem(Icons.message_outlined, Icons.message, "Messages", false),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 22,
                      ),
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
          )
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
            SizedBox(
              height: 300,
              child: _buildUserCreationChart(),
            ),
            const SizedBox(height: 16),
            _buildAppointmentAnalytics(),
            const SizedBox(height: 16),
            _buildSectionHeader("Performance"),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _buildMealPlanPerformance(),
            ),
            const SizedBox(height: 16),
            _buildUserSubscriptionChurn(),
            const SizedBox(height: 16),
            _buildSectionHeader("Insights"),
            const SizedBox(height: 12),
            _buildHealthGoalsDistribution(),
            const SizedBox(height: 16),
            _buildUserDemographics(),
            const SizedBox(height: 16),
            _buildSectionHeader("Activity"),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _buildDietitianActivityHistory(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildMealPlansWithLikes(),
            ),
          ],
        ),
      );
    } else {
      return _buildMainContent();
    }
  }



  Widget _buildSidebarItem(IconData outlinedIcon, IconData filledIcon, String title, bool isCompact) {
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
              color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryColor.withOpacity(0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? filledIcon : outlinedIcon,
                  color: isSelected ? _primaryColor : _textColorSecondary(context),
                  size: 22,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: _getTextStyle(
                      context,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? _primaryColor : _textColorPrimary(context),
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
    } else if (selectedPage == "QR Approval") {
      return _buildQRApprovalPage();
    } else if (selectedPage == "Messages") {
      return _buildMessagesPage();
    }
    return Container();
  }

  Widget _buildHomeDashboard() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;

    return Container(
      color: _scaffoldBgColor(context),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: SingleChildScrollView(
        child: isMobile
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Key Metrics"),
            const SizedBox(height: 12),
            _buildUserCreationChart(),
            const SizedBox(height: 16),
            _buildAppointmentAnalytics(),
            const SizedBox(height: 16),

            _buildSectionHeader("Performance"),
            const SizedBox(height: 12),
            _buildMealPlanPerformance(),
            const SizedBox(height: 16),
            _buildUserSubscriptionChurn(),
            const SizedBox(height: 16),

            _buildSectionHeader("Insights"),
            const SizedBox(height: 12),
            _buildHealthGoalsDistribution(),
            const SizedBox(height: 16),
            _buildUserDemographics(),
            const SizedBox(height: 16),

            _buildSectionHeader("Activity"),
            const SizedBox(height: 12),
            _buildDietitianActivityHistory(),
            const SizedBox(height: 16),
            _buildMealPlansWithLikes(),
          ],
        )
            : Column(
          children: [
            // Key Metrics Section
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
                }

                final users = snapshot.data!.docs;
                final totalUsers = users.length;
                final chartData = _processUserCreationData(users, chartFilter);
                final newUsersThisPeriod = _calculateNewUsersPeriod(users, chartFilter);

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
                        Expanded(
                          child: _buildMetricCard(
                            "Growth Trend",
                            _calculateGrowthTrend(users, chartFilter),
                            Colors.green,
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Bar Chart
                    SizedBox(
                      height: 280,
                      child: _buildBarChart(chartData),
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

// Metric Card Widget
  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
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
  int _calculateNewUsersPeriod(List<QueryDocumentSnapshot> users, String period) {
    final now = DateTime.now();
    int count = 0;

    for (var doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp? ?? data['creationDate'] as Timestamp?;

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
  String _calculateGrowthTrend(List<QueryDocumentSnapshot> users, String period) {
    final now = DateTime.now();
    int currentCount = 0;
    int previousCount = 0;

    for (var doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp? ?? data['creationDate'] as Timestamp?;

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

    final trend = ((currentCount - previousCount) / previousCount * 100).toStringAsFixed(1);
    return "$trend%";
  }

// Updated data processing - excludes today for Week view
// REPLACE your _processUserCreationData method with this corrected version:

  Map<String, dynamic> _processUserCreationData(List<QueryDocumentSnapshot> users, String chartFilter) {
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
      final timestamp = data['createdAt'] as Timestamp? ?? data['creationDate'] as Timestamp?;

      if (timestamp != null) {
        final date = timestamp.toDate();

        String key;
        if (chartFilter == "Week") {
          key = DateFormat('yyyy-MM-dd').format(date);
        } else if (chartFilter == "Month") {
          // FIXED: Corrected DateTime constructor order
          key = DateFormat('yyyy-MM').format(DateTime(date.year, date.month, 1));
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
    final maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b).toDouble();

    return {
      'labels': labels,
      'values': values,
      'maxY': maxY,
    };
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
            color: isSelected ? _primaryColor : _textColorSecondary(context).withOpacity(0.3),
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? _textColorOnPrimary : _textColorPrimary(context),
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
                                    backgroundColor: _primaryColor.withOpacity(0.2),
                                    backgroundImage: profileUrl.isNotEmpty
                                        ? NetworkImage(profileUrl)
                                        : null,
                                    child: profileUrl.isEmpty
                                        ? const Icon(Icons.person, color: _primaryColor)
                                        : null,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "$firstName $lastName",
                                    style: _getTextStyle(context, fontWeight: FontWeight.w600),
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
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "QR Code Preview",
                                                  style: _getTextStyle(
                                                    context,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Image.network(
                                                  qrCodeUrl,
                                                  width: 300,
                                                  height: 300,
                                                  fit: BoxFit.contain,
                                                ),
                                                const SizedBox(height: 16),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text("Close"),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.visibility, size: 18),
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
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    "Confirm Approval",
                                                    style: TextStyle(fontFamily: _primaryFontFamily),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                "Approve QR code for $firstName $lastName?",
                                                style: const TextStyle(fontFamily: _primaryFontFamily),
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
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text(
                                                    "Approve",
                                                    style: TextStyle(fontFamily: _primaryFontFamily),
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
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.check_circle, color: Colors.white),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "$firstName $lastName approved!",
                                                        style: const TextStyle(fontFamily: _primaryFontFamily),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
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
                                                      color: Colors.red.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    "Confirm Rejection",
                                                    style: TextStyle(fontFamily: _primaryFontFamily),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                "Reject QR code for $firstName $lastName?",
                                                style: const TextStyle(fontFamily: _primaryFontFamily),
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
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text(
                                                    "Reject",
                                                    style: TextStyle(fontFamily: _primaryFontFamily),
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
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.cancel, color: Colors.white),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "$firstName $lastName rejected",
                                                        style: const TextStyle(fontFamily: _primaryFontFamily),
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
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
                    final mealPlan = mealPlans[index].data() as Map<String, dynamic>;
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
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
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
                                    ? const Icon(Icons.person, color: Colors.orange)
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
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

                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
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
                                    backgroundColor: Colors.purple.withOpacity(0.2),
                                    backgroundImage: profileUrl.isNotEmpty
                                        ? NetworkImage(profileUrl)
                                        : null,
                                    child: profileUrl.isEmpty
                                        ? const Icon(Icons.restaurant_menu, color: Colors.purple)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                Expanded(
                  flex: 1,
                  child: _buildUsersList(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildChatArea(),
                ),
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
                }

                final messages = snapshot.data!.docs;
                final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

                Map<String, Map<String, dynamic>> uniqueConversations = {};

                for (var doc in messages) {
                  final data = doc.data() as Map<String, dynamic>;
                  final senderId = data['senderID'] ?? '';
                  final receiverId = data['receiverID'] ?? '';

                  // Determine the "other user" (not the current admin)
                  final otherUserId = senderId == currentUserId ? receiverId : senderId;

                  // Only add if we haven't seen this user before (ensures no duplicates)
                  if (otherUserId.isNotEmpty && !uniqueConversations.containsKey(otherUserId)) {
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
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          profileUrl = userData?['profile'] ?? '';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: isSelected ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? _primaryColor : Colors.transparent,
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
                                  ? const Icon(Icons.person, color: _primaryColor)
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
                  backgroundImage: selectedChatUserProfile != null && selectedChatUserProfile!.isNotEmpty
                      ? NetworkImage(selectedChatUserProfile!)
                      : null,
                  child: selectedChatUserProfile == null || selectedChatUserProfile!.isEmpty
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
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
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message["senderID"] == currentUserId;
                    final messageText = message["message"] ?? "";
                    final timestamp = message["timestamp"] as Timestamp?;
                    final timeStr = timestamp != null
                        ? DateFormat('hh:mm a').format(timestamp.toDate())
                        : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                          color: isMe ? _primaryColor : _scaffoldBgColor(context),
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
                                color: isMe ? _textColorOnPrimary : _textColorPrimary(context),
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
    final adminName = "${adminData?['firstName'] ?? 'Admin'} ${adminData?['lastName'] ?? ''}".trim();

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
                      _buildFilterButton("Verifications"),
                      const SizedBox(width: 8),
                      _buildFilterButton("Meal Plans"),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  if (isMultiSelectMode && selectedUserIds.isNotEmpty)
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
                  if (isMultiSelectMode && selectedUserIds.isNotEmpty)
                    const SizedBox(width: 8),
                  if (crudFilter != "Meal Plans" && crudFilter != "Verifications")
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
                  if (crudFilter != "Meal Plans" && crudFilter != "Verifications")
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

  IconData _getEmptyIcon() {
    switch (crudFilter) {
      case "Meal Plans":
        return Icons.restaurant_menu_outlined;
      case "Verifications":
        return Icons.verified_user_outlined;
      default:
        return Icons.people_outline;
    }
  }

  Widget _buildUsersTable(List<QueryDocumentSnapshot> users) {
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
              dataRowHeight: 64,
              columns: [
                if (isMultiSelectMode)
                  DataColumn(
                    label: Checkbox(
                      value: selectedUserIds.length == users.length && users.isNotEmpty,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedUserIds = users.map((doc) => doc.id).toSet();
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
                      DataCell(Text(
                        firstName,
                        style: _getTextStyle(context),
                      )),
                      DataCell(Text(
                        lastName,
                        style: _getTextStyle(context),
                      )),
                      DataCell(Text(
                        email,
                        style: _getTextStyle(context, fontSize: 14),
                      )),
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
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showEditUserDialog(doc.id, user),
                              tooltip: "Edit user",
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(doc.id, firstName),
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
                          onPressed: () => _toggleUserRole(doc.id, role, firstName),
                          icon: Icon(
                            role == "dietitian" ? Icons.arrow_downward : Icons.arrow_upward,
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
                    ]);
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

                return DataRow(cells: [
                  DataCell(Text(
                    firstName,
                    style: _getTextStyle(context),
                  )),
                  DataCell(Text(
                    lastName,
                    style: _getTextStyle(context),
                  )),
                  DataCell(Text(
                    email,
                    style: _getTextStyle(context, fontSize: 14),
                  )),
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
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteVerificationConfirmation(doc.id, firstName),
                      tooltip: "Delete unverified user",
                    ),
                  ),
                ]);
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
                    "Date Created",
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
                final dateCreated = timestamp != null
                    ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                    : "Unknown";

                return DataRow(cells: [
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
                        final ownerData = snapshot.data!.data() as Map<String, dynamic>?;
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
                  DataCell(Text(
                    dateCreated,
                    style: _getTextStyle(context, fontSize: 14),
                  )),
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
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteMealPlanConfirmation(doc.id, planType),
                          tooltip: "Delete meal plan",
                        ),
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

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
      case "Verifications":
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
              color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.3),
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

  Stream<QuerySnapshot> _getFilteredStream() {
    if (crudFilter == "Verifications") {
      return FirebaseFirestore.instance
          .collection('notVerifiedUsers')
          .snapshots();
    } else if (crudFilter == "Meal Plans") {
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
    final amSnack = mealPlan['amSnack'] ?? "Not specified";
    final lunch = mealPlan['lunch'] ?? "Not specified";
    final pmSnack = mealPlan['pmSnack'] ?? "Not specified";
    final dinner = mealPlan['dinner'] ?? "Not specified";
    final midnightSnack = mealPlan['midnightSnack'] ?? "Not specified";

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
                      _buildMealSection("Breakfast", breakfast, Icons.wb_sunny),
                      const SizedBox(height: 16),
                      _buildMealSection("AM Snack", amSnack, Icons.fastfood),
                      const SizedBox(height: 16),
                      _buildMealSection("Lunch", lunch, Icons.lunch_dining),
                      const SizedBox(height: 16),
                      _buildMealSection("PM Snack", pmSnack, Icons.cookie),
                      const SizedBox(height: 16),
                      _buildMealSection("Dinner", dinner, Icons.dinner_dining),
                      const SizedBox(height: 16),
                      _buildMealSection("Midnight Snack", midnightSnack, Icons.nightlight),
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

  Widget _buildMealSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: _getTextStyle(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: _getTextStyle(context, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showDeleteVerificationConfirmation(String docId, String firstName) {
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
            child: const Text("Cancel", style: TextStyle(fontFamily: _primaryFontFamily)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Unverified user deleted successfully", style: TextStyle(fontFamily: _primaryFontFamily)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Failed to delete user", style: TextStyle(fontFamily: _primaryFontFamily)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(fontFamily: _primaryFontFamily)),
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
            child: const Text("Cancel", style: TextStyle(fontFamily: _primaryFontFamily)),
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
                        Text("Meal plan deleted successfully", style: TextStyle(fontFamily: _primaryFontFamily)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Failed to delete meal plan", style: TextStyle(fontFamily: _primaryFontFamily)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(fontFamily: _primaryFontFamily)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      DropdownMenuItem(value: "dietitian", child: Text("Dietitian")),
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
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
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
              child: const Text("Cancel", style: TextStyle(fontFamily: _primaryFontFamily)),
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
                          Text("Please fill all fields", style: TextStyle(fontFamily: _primaryFontFamily)),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  final docRef = FirebaseFirestore.instance.collection("Users").doc();
                  final userId = docRef.id; // Changed this to docId, assuming it's passed correctly

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
                            const Icon(Icons.check_circle, color: Colors.white, size: 24),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              style: const TextStyle(fontFamily: _primaryFontFamily),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text("Add", style: TextStyle(fontFamily: _primaryFontFamily)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(String docId, Map<String, dynamic> user) {
    final firstNameController = TextEditingController(text: user['firstName'] ?? '');
    final lastNameController = TextEditingController(text: user['lastName'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    String selectedRole = user['role'] ?? "user";
    String selectedStatus = user['status'] ?? "active";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      DropdownMenuItem(value: "dietitian", child: Text("Dietitian")),
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
                      DropdownMenuItem(value: "offline", child: Text("Offline")),
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
              child: const Text("Cancel", style: TextStyle(fontFamily: _primaryFontFamily)),
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
                  await FirebaseFirestore.instance.collection("Users").doc(docId).update({
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
                          Text("User updated successfully", style: TextStyle(fontFamily: _primaryFontFamily)),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text("Failed to update user", style: TextStyle(fontFamily: _primaryFontFamily)),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text("Update", style: TextStyle(fontFamily: _primaryFontFamily)),
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
            child: const Text("Cancel", style: TextStyle(fontFamily: _primaryFontFamily)),
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
                await FirebaseFirestore.instance.collection("Users").doc(docId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text("User deleted successfully", style: TextStyle(fontFamily: _primaryFontFamily)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Failed to delete user", style: TextStyle(fontFamily: _primaryFontFamily)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(fontFamily: _primaryFontFamily)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserRole(String docId, String currentRole, String firstName) async {
    final newRole = currentRole == "dietitian" ? "user" : "dietitian";
    final action = currentRole == "dietitian" ? "downgraded" : "upgraded";

    try {
      await FirebaseFirestore.instance.collection("Users").doc(docId).update({"role": newRole});

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
          backgroundColor: newRole == "dietitian" ? _primaryColor : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  Text("Failed to change role", style: TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Error: $e",
                style: const TextStyle(fontFamily: _primaryFontFamily, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        batch.delete(FirebaseFirestore.instance.collection("Users").doc(userId));
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  .collection('appointments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
                }

                final appointments = snapshot.data!.docs;
                int scheduled = 0, confirmed = 0, completed = 0, declined = 0;

                for (var doc in appointments) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();

                  if (status == 'scheduled') scheduled++;
                  else if (status == 'confirmed') confirmed++;
                  else if (status == 'completed') completed++;
                  else if (status == 'declined') declined++;
                }

                final total = appointments.length;
                final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Scheduled",
                            scheduled.toString(),
                            Colors.blue,
                            Icons.schedule,
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
                            "Declined",
                            declined.toString(),
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
                            style: _getTextStyle(context, fontWeight: FontWeight.w600),
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
                }

                final mealPlans = snapshot.data!.docs;
                Map<String, int> categoryCount = {};

                for (var doc in mealPlans) {
                  final data = doc.data() as Map<String, dynamic>;
                  final planType = data['planType'] ?? 'Unknown';
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
                                style: _getTextStyle(context, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                mealPlans.length.toString(),
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
                          ...categoryCount.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: _cardSubtitleStyle(context),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          )),
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
            StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _subscribersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.indigo));
                }

                final subscribers = snapshot.data!;
                int canceledSubscribers = 0;
                final now = DateTime.now();
                final monthAgo = now.subtract(const Duration(days: 30));

                // Count canceled subscribers in last 30 days
                // for (var subDoc in subscribers) {
                //   final cancelledAt = subDoc['cancelledAt'] as Timestamp?;
                //   if (cancelledAt != null && cancelledAt.toDate().isAfter(monthAgo)) {
                //     canceledSubscribers++;
                //   }
                // }

                final total = subscribers.length + canceledSubscribers;
                final subscriberRate = total > 0
                    ? ((subscribers.length / total) * 100).toStringAsFixed(1)
                    : '0.0';
                final canceledRate = total > 0
                    ? ((canceledSubscribers / total) * 100).toStringAsFixed(1)
                    : '0.0';

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Subscribers",
                            subscribers.length.toString(),
                            Colors.green,
                            Icons.person_add,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Canceled Subscribers (30d)",
                            canceledSubscribers.toString(),
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Subscriber Rate",
                                style: _getTextStyle(
                                    context, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "$subscriberRate%",
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
                                "Canceled Subscriber Rate",
                                style: _getTextStyle(
                                    context, fontWeight: FontWeight.w600),
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
      yield* StreamGroup.merge(streams).map((snapshot) => snapshot.docs).scan<List<QueryDocumentSnapshot>>(
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
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
                                style: _getTextStyle(context, fontWeight: FontWeight.w600),
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
                            value: users.isNotEmpty ? entry.value / users.length : 0,
                            backgroundColor: Colors.pink.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
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
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
                }

                final users = snapshot.data!.docs;
                int regularUsers = 0, dietitians = 0, admins = 0;
                int googleAuth = 0, emailAuth = 0;

                for (var doc in users) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] ?? 'user';
                  final authProvider = data['authProvider'] ?? 'email';

                  if (role == 'user') regularUsers++;
                  else if (role == 'dietitian') dietitians++;
                  else if (role == 'admin') admins++;

                  if (authProvider == 'google') googleAuth++;
                  else emailAuth++;
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
                          _buildDemographicRow("Users", regularUsers, Colors.blue),
                          const SizedBox(height: 8),
                          _buildDemographicRow("Dietitians", dietitians, Colors.green),
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

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: _getTextStyle(
                    context,
                    fontSize: 12,
                    color: _textColorSecondary(context),
                  ),
                ),
              ),
            ],
          ),
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
        ],
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
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: _getTextStyle(context),
            ),
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
}
