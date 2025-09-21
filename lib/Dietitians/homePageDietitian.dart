import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../pages/login.dart';
import '../pages/messages.dart';    // Assuming this is UsersListPage
import 'createMealPlan.dart';
import 'dietitianProfile.dart';  // <--- IMPORT DietitianProfile

// --- Style Definitions (Ensure these are consistent across your app or in a shared file) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);

Color _scaffoldBgColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100;
Color _cardBgColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white;
Color _textColorPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;
Color _textColorSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54;
const Color _textColorOnPrimary = Colors.white;

TextStyle _getTextStyle(BuildContext context, {
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
  String fontFamily = _primaryFontFamily,
  double? letterSpacing,
  FontStyle? fontStyle,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor = color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}
// --- End Style Definitions ---

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
    setState(() { _isUserNameLoading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        if (mounted) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            setState(() {
              firstName = data['firstName'] as String? ?? '';
              lastName = data['lastName'] as String? ?? '';
              _isUserNameLoading = false;
            });
          } else {
            setState(() { firstName = ""; lastName = ""; _isUserNameLoading = false; });
            debugPrint("User document does not exist for Dietitian UID: ${user.uid}");
          }
        }
      } catch (e) {
        debugPrint("Error loading dietitian user name: $e");
        if (mounted) { setState(() { firstName = ""; lastName = ""; _isUserNameLoading = false; }); }
      }
    } else {
      if (mounted) { setState(() { _isUserNameLoading = false; });}
    }
  }

  Future<void> _updateGooglePhotoURL() async {
    if (firebaseUser != null) {
      String? photoURL = firebaseUser!.photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection("Users").doc(firebaseUser!.uid)
              .set({"profile": photoURL}, SetOptions(merge: true));
        } catch (e) { debugPrint("Error updating G-Photo (Dietitian): $e"); }
      }
    }
  }

  Future<void> _setUserStatus(String status) async {
    if (firebaseUser != null) {
      try {
        await FirebaseFirestore.instance.collection("Users").doc(firebaseUser!.uid)
            .set({"status": status}, SetOptions(merge: true));
      } catch (e) { debugPrint("Error setting dietitian status: $e");}
    }
  }

  Future<bool> signOutFromGoogle() async {
    try {
      await _setUserStatus("offline");
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) { await googleSignIn.signOut(); }
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

  // Updated _pages list to include DietitianProfile
  List<Widget> get _pages => [
    // Page 0: Dietitian's Dashboard
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Dietitian Dashboard",
            style: _getTextStyle(context, fontSize: 24, fontWeight: FontWeight.bold, color: _textColorPrimary(context)),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateMealPlanPage()));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _textColorOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: _textColorOnPrimary)
            ),
            icon: const Icon(Icons.post_add_rounded, size: 22),
            label: Text("Create Meal Plan", style: _getTextStyle(context, color: _textColorOnPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
    // Page 1: Schedule/Clients Placeholder
    Scaffold( // This can remain a Scaffold if it needs its own AppBar for a specific title when active
        appBar: AppBar(
          title: Text("Schedule / Clients", style: _getTextStyle(context, fontSize: 20, fontWeight: FontWeight.bold, color: _textColorOnPrimary)),
          backgroundColor: _primaryColor,
          iconTheme: const IconThemeData(color: _textColorOnPrimary),
          automaticallyImplyLeading: false, // No back button if it's a main tab
        ),
        backgroundColor: _scaffoldBgColor(context),
        body: Center(child: Text("Dietitian Schedule/Clients Page", style: _getTextStyle(context, fontSize: 18, color: _textColorPrimary(context))))
    ),
    // Page 2: Messages
    if (firebaseUser != null) UsersListPage(currentUserId: firebaseUser!.uid), // Ensure UsersListPage does not have its own Scaffold if it's a full tab page
    // Page 3: Dietitian Profile
    const DietitianProfile(), // DietitianProfile widget itself
  ];

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Dietitian Dashboard";
      case 1:
        return "Schedule/Clients";
      case 2:
        return "Messages";
      case 3:
        return "My Profile"; // Title for DietitianProfile tab
      default:
        return "Dietitian App";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        body: Center(child: Text("No dietitian user logged in.", style: _getTextStyle(context, color: _textColorPrimary(context)))),
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
                    ? Shimmer.fromColors( /* ... Shimmer for name ... */
                  baseColor: Colors.white.withOpacity(0.3), highlightColor: Colors.white.withOpacity(0.6),
                  period: const Duration(milliseconds: 1500),
                  child: Container(width: 120.0, height: 18.0, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
                )
                    : Text(
                  (firstName.isNotEmpty || lastName.isNotEmpty) ? "$firstName $lastName".trim() : "Dietitian",
                  style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold, color: _textColorOnPrimary),
                ),
                accountEmail: _isUserNameLoading
                    ? Shimmer.fromColors( /* ... Shimmer for email ... */
                  baseColor: Colors.white.withOpacity(0.3), highlightColor: Colors.white.withOpacity(0.9),
                  period: const Duration(milliseconds: 1500),
                  child: Container(width: 150.0, height: 14.0, margin: const EdgeInsets.only(top: 4.0), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
                )
                    : (firebaseUser!.email != null && firebaseUser!.email!.isNotEmpty
                    ? Text(firebaseUser!.email!, style: _getTextStyle(context, fontSize: 14, color: _textColorOnPrimary))
                    : Text("No email set", style: _getTextStyle(context, fontSize: 14, color: _textColorOnPrimary.withOpacity(0.7)))),
                currentAccountPicture: CircleAvatar(
                  radius: 30, backgroundColor: Colors.white,
                  backgroundImage: (firebaseUser!.photoURL != null && firebaseUser!.photoURL!.isNotEmpty) ? NetworkImage(firebaseUser!.photoURL!) : null,
                  child: (firebaseUser!.photoURL == null || firebaseUser!.photoURL!.isEmpty) ? const Icon(Icons.health_and_safety_rounded, size: 30, color: _primaryColor) : null,
                ),
                decoration: const BoxDecoration(color: _primaryColor),
                otherAccountsPictures: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: _textColorOnPrimary.withOpacity(0.8)),
                    onPressed: () {
                      Navigator.pop(context); // Close drawer
                      // Navigate to the Profile tab
                      int profileIndex = _pages.indexWhere((page) => page is DietitianProfile);
                      if (profileIndex != -1) {
                        setState(() {
                          selectedIndex = profileIndex;
                        });
                      }
                    },
                    tooltip: "View/Edit Profile",
                  )
                ],
              ),
              buildMenuTile('My Meal Plans', Icons.list_alt_outlined, Icons.list_alt_rounded),
              buildMenuTile('Client Management', Icons.people_outline_rounded, Icons.people_rounded),
              buildMenuTile('Settings', Icons.settings_outlined, Icons.settings_rounded),
              const Divider(indent: 16, endIndent: 16),
              buildMenuTile('Logout', Icons.logout_outlined, Icons.logout_rounded),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 1, backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: _textColorOnPrimary, size: 28),
        title: Text(
          _getAppBarTitle(selectedIndex), // Dynamic title based on selected tab
          style: _getTextStyle(context, fontSize: 20, fontWeight: FontWeight.bold, color: _textColorOnPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to the Profile tab when AppBar icon is tapped
                int profileIndex = _pages.indexWhere((page) => page is DietitianProfile);
                if (profileIndex != -1) {
                  setState(() {
                    selectedIndex = profileIndex;
                  });
                }
              },
              child: CircleAvatar(
                radius: 18, backgroundColor: _textColorOnPrimary.withOpacity(0.2),
                backgroundImage: (firebaseUser!.photoURL != null && firebaseUser!.photoURL!.isNotEmpty) ? NetworkImage(firebaseUser!.photoURL!) : null,
                child: (firebaseUser!.photoURL == null || firebaseUser!.photoURL!.isEmpty) ? Icon(Icons.health_and_safety_outlined, size: 20, color: _textColorOnPrimary.withOpacity(0.8)) : null,
              ),
            ),
          ),
        ],
      ),
      body: PageStorage( // Using PageStorage to preserve state of pages in BottomNav
        bucket: PageStorageBucket(),
        child: (firebaseUser != null && selectedIndex >= 0 && selectedIndex < _pages.length)
            ? _pages[selectedIndex]
            : Center(child: Text("Page not found or user not logged in", style: _getTextStyle(context))),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _primaryColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) { setState(() => selectedIndex = index); },
            selectedItemColor: _textColorOnPrimary,
            unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
            backgroundColor: _primaryColor,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true, // Consistent with other pages
            showUnselectedLabels: false, // Consistent with other pages
            selectedLabelStyle: _getTextStyle(context, fontSize: 11, fontWeight: FontWeight.w600, color: _textColorOnPrimary),
            unselectedLabelStyle: _getTextStyle(context, fontSize: 11, color: _textColorOnPrimary.withOpacity(0.6)),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.edit_calendar_outlined), activeIcon: Icon(Icons.edit_calendar), label: 'Schedule'), // Matched to your example for UserProfile
              BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Messages'), // Matched
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'), // New Profile Tab
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuTile(String label, IconData icon, IconData activeIcon) {
    bool isSelected = selectedMenu == label;
    // For Drawer: if a menu item should also select a bottom nav tab
    int targetTabIndex = -1;
    if (label == 'My Meal Plans') targetTabIndex = 0; // Example: My Meal Plans could be Dashboard
    // Add more mappings if Drawer items correspond to BottomNav tabs

    final Color itemColor = isSelected ? _primaryColor : _textColorPrimary(context);
    final Color itemBgColor = isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: itemBgColor, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(isSelected ? activeIcon : icon, color: itemColor, size: 24),
        title: Text(
          label,
          style: _getTextStyle(context, color: itemColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 15),
        ),
        onTap: () async {
          Navigator.pop(context); // Close drawer
          if (label == 'Logout') {
            bool signedOut = await signOutFromGoogle();
            if (signedOut && mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPageMobile()), (Route<dynamic> route) => false);
            }
          } else if (targetTabIndex != -1) {
            setState(() {
              selectedIndex = targetTabIndex;
              selectedMenu = label; // Keep drawer item highlighted if needed
            });
          }
          else {
            setState(() { selectedMenu = label; });
            // Handle other drawer item taps that don't switch bottom nav tabs (e.g., push new page)
            // if (label == 'Settings') Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
      ),
    );
  }
}

// UsersListPage definition (ensure it doesn't have its own Scaffold if it's a full tab page)
class UsersListPage extends StatelessWidget {
  final String currentUserId;
  const UsersListPage({super.key, required this.currentUserId});

  Future<Map<String, dynamic>> getLastMessage(BuildContext context, String otherUserId) async {
    // ... (your existing getLastMessage logic)
    final query = await FirebaseFirestore.instance.collection("messages")
        .where("senderId", whereIn: [currentUserId, otherUserId])
        .where("receiverId", whereIn: [currentUserId, otherUserId])
        .orderBy("timestamp", descending: true).limit(1).get();
    if (query.docs.isEmpty) return {"message": "", "isMe": false, "time": ""};

    final data = query.docs.first.data();
    String formattedTime = "";
    final timestamp = data["timestamp"];
    if (timestamp is Timestamp) {
      DateTime messageDate = timestamp.toDate();
      DateTime nowDate = DateTime.now();
      if (messageDate.year == nowDate.year && messageDate.month == nowDate.month && messageDate.day == nowDate.day) {
        formattedTime = TimeOfDay.fromDateTime(messageDate).format(context);
      } else {
        formattedTime = DateFormat('MMM d').format(messageDate);
      }
    }
    return {"message": data["message"] ?? "", "isMe": data["senderId"] == currentUserId, "time": formattedTime};
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentScaffoldBg = _scaffoldBgColor(context);
    final Color currentAppBarBg = _cardBgColor(context);
    final Color currentTabLabel = _textColorPrimary(context);
    final Color currentIndicator = _primaryColor;

    // UsersListPage content is now the body of a tab, so it doesn't need its own Scaffold or top AppBar.
    // The TabBar for "CLIENT CHATS" and "NOTIFICATIONS" will be part of its own content.
    return DefaultTabController(
      length: 2,
      child: Column( // Use Column if it needs its own TabBar at the top of its content area
        children: [
          Container( // Container for the TabBar
            color: currentAppBarBg, // Background for the TabBar area
            child: TabBar(
              labelColor: currentTabLabel,
              unselectedLabelColor: currentTabLabel.withOpacity(0.6),
              indicatorColor: currentIndicator,
              indicatorWeight: 2.5,
              labelStyle: _getTextStyle(context, fontWeight: FontWeight.bold, fontSize: 14, color: currentTabLabel),
              unselectedLabelStyle: _getTextStyle(context, fontWeight: FontWeight.w500, fontSize: 14, color: currentTabLabel.withOpacity(0.6)),
              tabs: const [
                Tab(text: "CLIENT CHATS"),
                Tab(text: "NOTIFICATIONS"),
              ],
            ),
          ),
          Expanded( // TabBarView needs to be Expanded if inside a Column
            child: TabBarView(
              children: [
                // MESSAGES LIST
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection("Users").where("role", isEqualTo: "user").snapshots(),
                  builder: (context, snapshot) {
                    // ... (your existing StreamBuilder logic for messages)
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _primaryColor));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No clients to chat with yet.", style: _getTextStyle(context, color: _textColorPrimary(context))));
                    }
                    var users = snapshot.data!.docs;
                    return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          var userDoc = users[index];
                          var data = userDoc.data() as Map<String, dynamic>;
                          return FutureBuilder<Map<String, dynamic>>(
                            future: getLastMessage(context, userDoc.id),
                            builder: (context, snapshotMessage) {
                              String subtitleText = "Loading chat...";
                              String timeText = "";
                              FontWeight subtitleFontWeight = FontWeight.normal;
                              Color subtitleColor = _textColorSecondary(context);

                              if (snapshotMessage.connectionState == ConnectionState.done) {
                                if (snapshotMessage.hasData && snapshotMessage.data != null) {
                                  final lastMsg = snapshotMessage.data!;
                                  subtitleText = lastMsg["message"].toString().isNotEmpty
                                      ? "${lastMsg["isMe"] ? "You: " : ""}${lastMsg["message"]}"
                                      : "Start a conversation";
                                  timeText = lastMsg["time"] ?? "";
                                } else { subtitleText = "Start a conversation"; }
                              } else if (snapshotMessage.hasError) { subtitleText = "Error loading chat"; }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 28, backgroundColor: _primaryColor.withOpacity(0.1),
                                      backgroundImage: (data["profile"] != null && data["profile"].toString().isNotEmpty) ? NetworkImage(data["profile"]) : null,
                                      child: (data["profile"] == null || data["profile"].toString().isEmpty) ? Icon(Icons.person_outline, size: 28, color: _primaryColor.withOpacity(0.8)) : null,
                                    ),
                                    if (data["status"] == "online")
                                      Container(
                                        width: 12, height: 12,
                                        decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: _cardBgColor(context), width: 2)),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  "${data["firstName"] ?? "Client"} ${data["lastName"] ?? ""}".trim(),
                                  style: _getTextStyle(context, fontWeight: FontWeight.bold, fontSize: 16, color: _textColorPrimary(context)),
                                ),
                                subtitle: Text(
                                  subtitleText,
                                  style: _getTextStyle(context, fontSize: 14, fontWeight: subtitleFontWeight, color: subtitleColor),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                trailing: timeText.isNotEmpty ? Text(timeText, style: _getTextStyle(context, fontSize: 12, color: _textColorSecondary(context))) : null,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesPage(
                                    currentUserId: currentUserId, receiverId: userDoc.id,
                                    receiverName: "${data["firstName"] ?? "Client"} ${data["lastName"] ?? ""}".trim(),
                                    receiverProfile: data["profile"] ?? "",
                                  ),),);
                                },
                              );
                            },
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 88, endIndent: 16, thickness: 0.5)
                    );
                  },
                ),
                // NOTIFICATIONS TAB
                Center(child: Text("No new notifications.", style: _getTextStyle(context, color: _textColorPrimary(context)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
