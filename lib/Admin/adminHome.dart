import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String selectedPage = "Home"; // Track which sidebar item is selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // LEFT SIDEBAR
          Container(
            width: 200,
            color: Colors.blueGrey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                _buildSidebarItem(Icons.home, "Home"),
                _buildSidebarItem(Icons.settings, "CRUD"),
                _buildSidebarItem(Icons.bar_chart, "Sales"),
                const Spacer(),
                _buildSidebarItem(Icons.logout, "Logout"),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // TOP NAVBAR
                Container(
                  height: 60,
                  color: Colors.blueGrey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Admin Dashboard",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Admin User",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // BODY CONTENT
                Expanded(
                  child: Row(
                    children: [
                      // Center Activity Panel
                      Expanded(
                        child: _buildMainContent(),
                      ),

                      // Right side panels (only in Home)
                      if (selectedPage == "Home")
                        Container(
                          width: 300,
                          color: Colors.grey[100],
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

  // Sidebar Item
  Widget _buildSidebarItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        setState(() {
          selectedPage = title;
        });
      },
    );
  }

  // MAIN CONTENT SWITCHER
  Widget _buildMainContent() {
    if (selectedPage == "Home") {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            "Activity Panel (placeholder)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else if (selectedPage == "CRUD") {
      return _buildCrudTable();
    } else if (selectedPage == "Sales") {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            "Sales Panel (placeholder)",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    return Container();
  }

  // CRUD Table for Users (admins hidden)
  Widget _buildCrudTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('role', isNotEqualTo: 'admin') // exclude admins
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found."));
        }

        final users = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("First Name")),
              DataColumn(label: Text("Last Name")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Role")),
              DataColumn(label: Text("Actions")),
              DataColumn(label: Text("Upgrade")),
            ],
            rows: users.map((doc) {
              final user = doc.data() as Map<String, dynamic>;
              final firstName = user['firstName'] ?? "No first name";
              final lastName = user['lastName'] ?? "No last name";
              final email = user['email'] ?? "No email";
              final status = user['status'] ?? "No status";
              final role = user['role'] ?? "user";

              return DataRow(cells: [
                DataCell(Text(firstName)),
                DataCell(Text(lastName)),
                DataCell(Text(email)),
                DataCell(Text(status)),
                DataCell(Text(role)),

                // DELETE BUTTON
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("Users")
                          .doc(doc.id)
                          .delete();
                      setState(() {}); // ensure UI rebuild
                    },
                  ),
                ),

                // UPGRADE BUTTON
                DataCell(
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: role == "dietitian"
                        ? null
                        : () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection("Users")
                            .doc(doc.id)
                            .update({"role": "dietitian"});

                        setState(() {}); // force UI refresh

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "$firstName upgraded to Dietitian ✅"),
                          ),
                        );
                      } catch (e) {
                        print("Error upgrading user: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text("Failed to upgrade user ❌")),
                        );
                      }
                    },
                    child: const Text("Upgrade"),
                  ),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  // RIGHT PANEL: Dietitians
  Widget _buildDietitianPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.blueGrey[700],
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: const Text(
            "Dietitians",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No dietitians found."));
              }

              final dietitians = snapshot.data!.docs;

              return ListView.builder(
                itemCount: dietitians.length,
                itemBuilder: (context, index) {
                  final doc = dietitians[index];
                  final user = doc.data() as Map<String, dynamic>;
                  final firstName = user['firstName'] ?? '';
                  final lastName = user['lastName'] ?? '';
                  final email = user['email'] ?? 'No email';
                  final name = "$firstName $lastName".trim();

                  return ListTile(
                    key: ValueKey(doc.id),
                    leading:
                    const Icon(Icons.person, color: Colors.blueGrey),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(email),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // RIGHT PANEL: Users
  Widget _buildUsersPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.blueGrey[700],
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: const Text(
            "Users",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No users found."));
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final user = doc.data() as Map<String, dynamic>;
                  final firstName = user['firstName'] ?? '';
                  final lastName = user['lastName'] ?? '';
                  final email = user['email'] ?? 'No email';
                  final status = user['status'] ?? 'No status';
                  final name = "$firstName $lastName".trim();

                  return Padding(
                    key: ValueKey(doc.id),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueGrey[900],
                        elevation: 2,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () {
                        // Optional: add click action
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blueGrey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(email,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == "online"
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: status.toLowerCase() == "online"
                                    ? Colors.green[800]
                                    : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
