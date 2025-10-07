import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      body: Row(
        children: [
          Container(
            width: 240,
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
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Admin Panel",
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
                _buildSidebarItem(Icons.home_outlined, Icons.home, "Home"),
                _buildSidebarItem(Icons.settings_outlined, Icons.settings, "CRUD"),
                _buildSidebarItem(Icons.bar_chart_outlined, Icons.bar_chart, "Sales"),
                const Spacer(),
                const Divider(indent: 16, endIndent: 16),
                _buildSidebarItem(Icons.logout_outlined, Icons.logout, "Logout"),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // MAIN CONTENT AREA
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dashboard",
                            style: _getTextStyle(
                              context,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getPageSubtitle(),
                            style: _cardSubtitleStyle(context),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            const SizedBox(width: 10),
                            Text(
                              "Admin User",
                              style: _getTextStyle(
                                context,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // BODY CONTENT
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMainContent(),
                      ),
                      if (selectedPage == "Home")
                        Container(
                          width: 320,
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

  String _getPageSubtitle() {
    switch (selectedPage) {
      case "Home":
        return "Overview and statistics";
      case "CRUD":
        return "Manage users and data";
      case "Sales":
        return "Sales analytics";
      default:
        return "";
    }
  }

  Widget _buildSidebarItem(IconData outlinedIcon, IconData filledIcon, String title) {
    final isSelected = selectedPage == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedPage = title;
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (selectedPage == "Home") {
      return Container(
        color: _scaffoldBgColor(context),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 80,
                color: _primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "Activity Panel",
                style: _getTextStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Dashboard content coming soon",
                style: _cardSubtitleStyle(context),
              ),
            ],
          ),
        ),
      );
    } else if (selectedPage == "CRUD") {
      return _buildCrudTable();
    } else if (selectedPage == "Sales") {
      return Container(
        color: _scaffoldBgColor(context),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: _primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "Sales Analytics",
                style: _getTextStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sales data coming soon",
                style: _cardSubtitleStyle(context),
              ),
            ],
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildCrudTable() {
    return Container(
      color: _scaffoldBgColor(context),
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .where('role', isNotEqualTo: 'admin')
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
                    Icons.people_outline,
                    size: 80,
                    color: _primaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No users found",
                    style: _getTextStyle(context, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

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
                          "Upgrade",
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
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("Users")
                                  .doc(doc.id)
                                  .delete();
                              setState(() {});
                            },
                            tooltip: "Delete user",
                          ),
                        ),
                        DataCell(
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: role == "dietitian"
                                  ? Colors.grey[300]
                                  : _primaryColor,
                              foregroundColor: role == "dietitian"
                                  ? Colors.grey[600]
                                  : _textColorOnPrimary,
                              elevation: role == "dietitian" ? 0 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onPressed: role == "dietitian"
                                ? null
                                : () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(doc.id)
                                    .update({"role": "dietitian"});

                                setState(() {});

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          "$firstName upgraded to Dietitian",
                                          style: const TextStyle(
                                            fontFamily: _primaryFontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: _primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print("Error upgrading user: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.error_outline,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          "Failed to upgrade user",
                                          style: TextStyle(
                                            fontFamily: _primaryFontFamily,
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
                            },
                            icon: Icon(
                              role == "dietitian"
                                  ? Icons.check_circle
                                  : Icons.upgrade,
                              size: 18,
                            ),
                            label: Text(
                              role == "dietitian" ? "Upgraded" : "Upgrade",
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
        },
      ),
    );
  }

  Widget _buildDietitianPanel() {
    return Container(
      margin: const EdgeInsets.all(12),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: _textColorOnPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Dietitians",
                  style: _getTextStyle(
                    context,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _primaryColor,
                  ),
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
                  padding: const EdgeInsets.all(12),
                  itemCount: dietitians.length,
                  itemBuilder: (context, index) {
                    final doc = dietitians[index];
                    final user = doc.data() as Map<String, dynamic>;
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final email = user['email'] ?? 'No email';
                    final profileUrl = user['profile'] ?? '';
                    final name = "$firstName $lastName".trim();

                    return Card(
                      key: ValueKey(doc.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            size: 24,
                          )
                              : null,
                        ),
                        title: Text(
                          name.isEmpty ? "Dietitian" : name,
                          style: _getTextStyle(
                            context,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: _cardSubtitleStyle(context),
                          overflow: TextOverflow.ellipsis,
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
      margin: const EdgeInsets.all(12),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: _textColorOnPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Users",
                  style: _getTextStyle(
                    context,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _primaryColor,
                  ),
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
                  padding: const EdgeInsets.all(12),
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
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: _primaryColor.withOpacity(0.2),
                              backgroundImage: profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl.isEmpty
                                  ? const Icon(
                                Icons.person,
                                color: _primaryColor,
                                size: 24,
                              )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
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
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: _cardSubtitleStyle(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                              fontSize: 11,
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
}
