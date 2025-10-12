import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../pages/login.dart';
import 'messagesDietitian.dart'; // Assuming this is UsersListPage
import 'createMealPlan.dart';
import 'dietitianProfile.dart'; // <--- IMPORT DietitianProfile

// --- Style Definitions (Ensure these are consistent across your app or in a shared file) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);

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
const Color _textColorOnPrimary = Colors.white;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor =
      color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
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
  String selectedMenu = ''; // For Drawer item selection
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
        if (mounted) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            setState(() {
              firstName = data['firstName'] as String? ?? '';
              lastName = data['lastName'] as String? ?? '';
              profileUrl = data['profile'] as String? ?? ''; // <-- ADD THIS LINE
              _isUserNameLoading = false;
            });
          } else {
            // Handle case where user document doesn't exist
            setState(() {
              firstName = "";
              lastName = "";
              profileUrl = ""; // <-- ADD THIS LINE
              _isUserNameLoading = false;
            });
            debugPrint("User document does not exist for UID: ${user.uid}");
          }
        }
      } catch (e) {
        debugPrint("Error loading user name: $e");
        if (mounted) {
          setState(() {
            firstName = "";
            lastName = "";
            profileUrl = ""; // <-- ADD THIS LINE
            _isUserNameLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isUserNameLoading = false;
        });
      }
    }
  }

  Future<void> _updateGooglePhotoURL() async {
    if (firebaseUser == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection("Users")
        .doc(firebaseUser!.uid);

    final snapshot = await userDoc.get();

    // Only update if profile field is empty or missing
    if (!snapshot.exists ||
        !snapshot.data()!.containsKey('profile') ||
        (snapshot.data()!['profile'] as String).isEmpty) {
      String? photoURL = firebaseUser!.photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        try {
          await userDoc.set(
            {"profile": photoURL},
            SetOptions(merge: true),
          );
          debugPrint("Firestore profile set from Google photo (first time only).");
        } catch (e) {
          debugPrint("Error updating Google Photo URL in Firestore: $e");
        }
      }
    } else {
      debugPrint("Firestore profile already set, skipping Google photo overwrite.");
    }
  }

  Future<void> _setUserStatus(String status) async {
    if (firebaseUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(firebaseUser!.uid)
            .set({"status": status}, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error setting dietitian status: $e");
      }
    }
  }

  Future<bool> signOutFromGoogle() async {
    try {
      await _setUserStatus("offline");
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      debugPrint("Sign out error (Dietitian): $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchReceiptsWithClients() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final receiptsSnap = await FirebaseFirestore.instance
        .collection('receipts')
        .where('dietitianID', isEqualTo: currentUser.uid)
        .orderBy('timeStamp', descending: true)
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in receiptsSnap.docs) {
      final data = doc.data();
      final clientID = data['clientID'];
      print('🔎 Fetching user for clientID: $clientID');

      final clientDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(clientID)
          .get();

      if (!clientDoc.exists) {
        print('⚠️ No user found for clientID: $clientID');
        continue;
      }

      final clientData = clientDoc.data() ?? {};
      print('✅ Found user: ${clientData['firstname']} ${clientData['lastname']}');

      results.add({
        'firstname': clientData['firstname'] ?? clientData['firstName'] ?? 'N/A',
        'lastname': clientData['lastname'] ?? clientData['lastName'] ?? 'N/A',
        'planPrice': data['planPrice'] ?? '',
        'planType': data['planType'] ?? '',
        'status': data['status'] ?? '',
      });
    }

    return results;
  }


  @override
  void dispose() {
    _setUserStatus("offline");
    super.dispose();
  }

  List<Widget> get _pages => [

    //home dashboard
    Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Top-right button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateMealPlanPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _textColorOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: _getTextStyle(context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textColorOnPrimary),
                ),
                icon: const Icon(Icons.post_add_rounded, size: 18),
                label: Text(
                  "Create Meal Plan",
                  style: _getTextStyle(context,
                      color: _textColorOnPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Table of Receipts
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchReceiptsWithClients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No subscriptions found yet."));
                }

                final receipts = snapshot.data!;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // allow horizontal scroll if needed
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width), // try to fit screen
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical, // vertical scroll for long table
                      child: DataTable(
                        columnSpacing: 10,
                        horizontalMargin: 8,
                        headingRowHeight: 32,
                        dataRowHeight: 36,
                        columns: const [
                          DataColumn(
                              label: Text("Firstname",
                                  style: TextStyle(fontSize: 12))),
                          DataColumn(
                              label:
                              Text("Lastname", style: TextStyle(fontSize: 12))),
                          DataColumn(
                              label: Text("Price", style: TextStyle(fontSize: 12))),
                          DataColumn(
                              label:
                              Text("Plan Type", style: TextStyle(fontSize: 12))),
                          DataColumn(
                              label: Text("Status", style: TextStyle(fontSize: 12))),
                          DataColumn(
                              label: Text("Action", style: TextStyle(fontSize: 12))),
                        ],
                        rows: receipts.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(SizedBox(
                                  width: 80,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(r['firstname'],
                                          style:
                                          const TextStyle(fontSize: 12))))),
                              DataCell(SizedBox(
                                  width: 80,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(r['lastname'],
                                          style:
                                          const TextStyle(fontSize: 12))))),
                              DataCell(SizedBox(
                                  width: 50,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(r['planPrice'],
                                          style:
                                          const TextStyle(fontSize: 12))))),
                              DataCell(SizedBox(
                                  width: 70,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(r['planType'],
                                          style:
                                          const TextStyle(fontSize: 12))))),
                              DataCell(SizedBox(
                                  width: 60,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(r['status'],
                                          style:
                                          const TextStyle(fontSize: 12))))),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Handle approve action
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(60, 28),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text("Approved"),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),

    ScheduleCalendarPage(
      dietitianFirstName: firstName,
      dietitianLastName: lastName,
      isDietitianNameLoading: _isUserNameLoading,
    ),
    if (firebaseUser != null)
      UsersListPage(currentUserId: firebaseUser!.uid),
    const DietitianProfile(), // Added Profile page back to navigation
  ];

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Dietitian Dashboard";
      case 1:
        return "My Schedule";
      case 2:
        return "Messages";
      case 3: // Added case for Profile tab
        return "Profile";
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
            child: Text("No dietitian user logged in.",
                style: _getTextStyle(context,
                    color: _textColorPrimary(context)))),
      );
    }

    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Drawer(
          backgroundColor: _cardBgColor(context),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: _isUserNameLoading
                    ? Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.6),
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 120.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
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
                    ? Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.9),
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 150.0,
                    height: 14.0,
                    margin: const EdgeInsets.only(top: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
                    : (firebaseUser!.email != null &&
                    firebaseUser!.email!.isNotEmpty
                    ? Text(
                  firebaseUser!.email!,
                  style: const TextStyle(
                    fontFamily: _primaryFontFamily,
                    fontSize: 14,
                    color: _textColorOnPrimary,
                  ),
                )
                    : null),
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

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final profileUrl = data?['profile'] ?? '';

                    if (profileUrl.isNotEmpty) {
                      return CircleAvatar(
                        backgroundImage: NetworkImage(profileUrl),
                      );
                    } else {
                      return const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 30, color: Colors.green),
                      );
                    }
                  },
                ),
                decoration: const BoxDecoration(color: _primaryColor),
                otherAccountsPictures: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: _textColorOnPrimary.withOpacity(0.8),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DietitianProfile(),
                        ),
                      );
                    },
                    tooltip: "Edit Profile",
                  ),
                ],
              ),
              buildMenuTile('My Meal Plans', Icons.list_alt_outlined,
                  Icons.list_alt_rounded),
              buildMenuTile('Client Management', Icons.people_outline_rounded,
                  Icons.people_rounded),
              buildMenuTile(
                  'Settings', Icons.settings_outlined, Icons.settings_rounded),
              const Divider(indent: 16, endIndent: 16),
              buildMenuTile(
                  'Logout', Icons.logout_outlined, Icons.logout_rounded),
            ],
          ),
        ),
      ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DietitianProfile()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _primaryColor.withOpacity(0.2),
                backgroundImage:
                (profileUrl.isNotEmpty) ? NetworkImage(profileUrl) : null,
                child: (profileUrl.isEmpty)
                    ? const Icon(
                  Icons.person,
                  size: 20,
                  color: _primaryColor,
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: (firebaseUser != null &&
            selectedIndex >= 0 &&
            selectedIndex < _pages.length)
            ? _pages[selectedIndex]
            : Center(
            child: Text("Page not found or user not logged in",
                style: _getTextStyle(context))),
      ),
      bottomNavigationBar: Container(
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
            onTap: (index) {
              setState(() => selectedIndex = index);
            },
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
            unselectedLabelStyle: _getTextStyle(context,
                fontSize: 11, color: _textColorOnPrimary.withOpacity(0.6)),
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
      ),
    );
  }

  Widget buildMenuTile(String label, IconData icon, IconData activeIcon) {
    bool isSelected = selectedMenu == label;
    int targetTabIndex = -1;
    if (label == 'My Meal Plans') targetTabIndex = 0;

    final Color itemColor =
    isSelected ? _primaryColor : _textColorPrimary(context);
    final Color itemBgColor =
    isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration:
      BoxDecoration(color: itemBgColor, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(isSelected ? activeIcon : icon, color: itemColor, size: 24),
        title: Text(
          label,
          style: _getTextStyle(context,
              color: itemColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15),
        ),
        onTap: () async {
          Navigator.pop(context); // Close drawer
          if (label == 'Logout') {
            bool signedOut = await signOutFromGoogle();
            if (signedOut && mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const LoginPageMobile()),
                      (Route<dynamic> route) => false);
            }
          } else if (targetTabIndex != -1) {
            setState(() {
              selectedIndex = targetTabIndex;
              selectedMenu = label;
            });
          } else {
            setState(() {
              selectedMenu = label;
            });
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
      ),
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
    final Color currentAppBarBg =
    isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color currentTabLabel = _textColorPrimary(context);
    final Color currentIndicator = _primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: currentScaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
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
                      "No dietitians to chat with yet.",
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
                          final lastSenderName = lastMsg["senderName"] ?? "";
                          timeText = lastMsg["time"] ?? "";

                          if (lastMessage.isNotEmpty) {
                            if (lastMsg["isMe"] ?? false) {
                              subtitleText = "Me: $lastMessage";
                            } else {
                              subtitleText = "$lastSenderName: $lastMessage";
                            }
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
                          title: Text(senderName),
                          subtitle: Text(subtitleText,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    String formattedTime = ""; // Changed from formattedDate for simplicity here

                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      final now = DateTime.now();
                      if (date.year == now.year && date.month == now.month && date.day == now.day) {
                        formattedTime = DateFormat.jm().format(date); // Just time for today
                      } else if (date.year == now.year && date.month == now.month && date.day == now.day -1) {
                        formattedTime = "Yesterday"; // Simpler "Yesterday"
                      } else {
                        formattedTime = DateFormat('MMM d').format(date); // Short date for older
                      }
                    }

                    IconData notificationIcon = Icons.notifications_none; // Simpler default icon
                    Color iconColor = _primaryColor; // Your primary color for active/unread

                    if (data["type"] == "message") {
                      notificationIcon = Icons.chat_bubble_outline_rounded;
                    } else if (data["type"] == "appointment" || data["type"] == "appointment_update") {
                      notificationIcon = Icons.event_available_outlined; // Alt calendar icon
                    }

                    bool isRead = data["isRead"] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      elevation: 1.5,
                      color: _cardBgColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        // No explicit border, rely on elevation and unread indicator
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
                            print("Appointment/Update notification tapped. Consider navigation.");
                            // Potentially navigate to the schedule page
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Livelier Unread Indicator using a colored CircleAvatar or Container
                              if (!isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 12.0), // Margin for the dot container
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                              // Placeholder for alignment when read:
                              // This SizedBox takes the width of the dot (10) PLUS the margin (12)
                              // to push the subsequent Icon to the same starting position.
                                SizedBox(width: 10 + 12.0), // Corrected: width is 22

                              Icon(
                                notificationIcon,
                                color: isRead ? _textColorSecondary(context).withOpacity(0.7) : iconColor,
                                size: 26.0,
                              ),
                              const SizedBox(width: 14), // Space between Icon and Text
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
                                      maxLines: 1, // Keep message concise in the list
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

  // --- MODIFICATION START: Added state variables for events ---
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoadingEvents = true;

  // --- MODIFICATION END ---

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // --- MODIFICATION START: Load appointments on init ---
    _loadAppointmentsForCalendar();
    // --- MODIFICATION END ---
  }

  // --- MODIFICATION START: New method to load appointments ---
  // Inside class _ScheduleCalendarPageState

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
      for (var doc in snapshot.docs) { // doc is a QueryDocumentSnapshot
        final data = doc.data();
        // --- THIS IS THE LINE TO ADD ---
        data['id'] = doc.id; // Store document ID
        // --- END OF LINE TO ADD ---
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

  // --- MODIFICATION END ---

  // --- MODIFICATION START: New method for TableCalendar eventLoader ---
  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay =
    DateTime.utc(day.year, day.month, day.day); // Normalize to UTC midnight
    return _events[normalizedDay] ?? [];
  }

  // --- MODIFICATION END ---

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
                            if (name.isEmpty)
                              name =
                              "Client ID: ${document.id.substring(0, 5)}";
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
                                if (selectedClientName.isEmpty)
                                  selectedClientName =
                                  "Client ID: ${newValue.substring(0, 5)}";
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
      // --- MODIFICATION START: Refresh calendar events after saving ---
      _loadAppointmentsForCalendar();
      // --- MODIFICATION END ---
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
                // --- MODIFICATION START: Added eventLoader and updated calendarStyle ---
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
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
                  markerSize: 0, // Hide default markers
                ),
                // --- MODIFICATION END ---
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
                  // --- MODIFICATION START: Update focusedDay on page change ---
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  // --- MODIFICATION END ---
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        top: 1,
                        child: Container(
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
                            '${events.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
          // --- MODIFICATION START: Conditional UI based on event loading state ---
          if (_isLoadingEvents)
            const Padding(
              padding: EdgeInsets.all(16.0),
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
                      // Using new method
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
              if (!_isLoadingEvents) // Shown if no day is selected and not loading
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
          // --- MODIFICATION END ---
        ],
      ),
    );
  }

  // --- MODIFICATION START: New widget method to display appointments for a selected day ---
  Widget _buildScheduledAppointmentsList(DateTime selectedDate) {
    final normalizedSelectedDate = DateTime.utc(
        selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEvents = _events[normalizedSelectedDate] ?? [];

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
          print(
              "Error parsing date in _buildScheduledAppointmentsList: ${data['appointmentDate']}");
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
// --- MODIFICATION END ---