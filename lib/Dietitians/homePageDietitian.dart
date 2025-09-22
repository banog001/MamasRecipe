import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../pages/login.dart';
import 'messagesDietitian.dart';    // Assuming this is UsersListPage
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
TextStyle _cardBodyTextStyle(BuildContext context) => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    color: _textColorPrimary(context));
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
  // Inside _HomePageDietitianState

  List<Widget> get _pages => [
    // Page 0: Dietitian's Dashboard (Unchanged)
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
    // Page 1: My Schedule (Calendar) - MODIFIED to pass data
    ScheduleCalendarPage(
      dietitianFirstName: firstName,
      dietitianLastName: lastName,
      isDietitianNameLoading: _isUserNameLoading,
    ),
    // Page 2: Messages (Unchanged)
    if (firebaseUser != null) UsersListPage(currentUserId: firebaseUser!.uid),
    // Page 3: Profile (Unchanged)
    const DietitianProfile(),
  ];


  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Dietitian Dashboard";
      case 1:
        return "My Schedule";
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
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
            // Chats tab
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

            // Notifications tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(currentUserId) // 👈 notifications inside this user
                  .collection("notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No notifications"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data["title"] ?? "Notification"),
                      subtitle: Text(data["message"] ?? ""),
                      trailing: data["isRead"] == false
                          ? const Icon(Icons.circle, color: Colors.red, size: 10)
                          : null,
                      onTap: () async {
                        // ✅ 1. Mark notification as read
                        await FirebaseFirestore.instance
                            .collection("Users")
                            .doc(currentUserId)
                            .collection("notifications")
                            .doc(doc.id)
                            .update({"isRead": true});

                        // ✅ 2. Navigate based on type
                        if (data["type"] == "message") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MessagesPageDietitian(
                                receiverId: data["senderId"],       // chat with sender
                                receiverName: data["senderName"],
                                currentUserId: currentUserId,
                                receiverProfile: data["receiverProfile"] ?? "",
                              ),
                            ),
                          );
                        }
                      },
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
// At the top of HomePageDietitian.dart, where ScheduleCalendarPage is defined

class ScheduleCalendarPage extends StatefulWidget {
  final String dietitianFirstName;
  final String dietitianLastName;
  final bool isDietitianNameLoading; // To handle loading state for dietitian name

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

  // No need to have separate firstName, lastName, _isUserNameLoading here anymore
  // We will use widget.dietitianFirstName, etc.

  // ... (initState, _onDaySelected remain the same) ...

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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

    if (clients.isEmpty && mounted) { // check mounted before showing SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clients found to schedule an appointment with.')),
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
                title: Text('Schedule for ${DateFormat.yMMMMd().format(selectedDate)}', style: _getTextStyle(dialogContext, fontWeight: FontWeight.bold, fontSize: 18)), // Use dialogContext
                backgroundColor: _cardBgColor(dialogContext), // Use dialogContext
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      if (clients.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Client',
                            labelStyle: _getTextStyle(dialogContext, color: _textColorSecondary(dialogContext)), // Use dialogContext
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: _scaffoldBgColor(dialogContext), // Use dialogContext
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          value: selectedClientId,
                          hint: Text(selectedClientName, style: _getTextStyle(dialogContext, color: selectedClientId == null ? _textColorSecondary(dialogContext) : _textColorPrimary(dialogContext))), // Use dialogContext
                          dropdownColor: _cardBgColor(dialogContext), // Use dialogContext
                          items: clients.map((DocumentSnapshot document) {
                            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                            String name = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
                            if (name.isEmpty) name = "Client ID: ${document.id.substring(0,5)}";
                            return DropdownMenuItem<String>(
                              value: document.id,
                              child: Text(name, style: _getTextStyle(dialogContext, color: _textColorPrimary(dialogContext))), // Use dialogContext
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setStateDialog(() {
                              selectedClientId = newValue;
                              if (newValue != null) {
                                final clientDoc = clients.firstWhere((doc) => doc.id == newValue);
                                final clientData = clientDoc.data() as Map<String, dynamic>;
                                selectedClientName = "${clientData['firstName'] ?? ''} ${clientData['lastName'] ?? ''}".trim();
                                if (selectedClientName.isEmpty) selectedClientName = "Client ID: ${newValue.substring(0,5)}";
                              } else {
                                selectedClientName = "Select Client";
                              }
                            });
                          },
                          validator: (value) => value == null ? 'Please select a client' : null,
                        )
                      else
                        Text("No clients available.", style: _getTextStyle(dialogContext)), // Use dialogContext
                      const SizedBox(height: 15),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.access_time_filled_rounded, color: _primaryColor),
                        title: Text('Time: ${selectedTime?.format(dialogContext) ?? 'Tap to select'}', style: _getTextStyle(dialogContext)), // Use dialogContext
                        onTap: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: dialogContext, // Use dialogContext
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
                          labelStyle: _getTextStyle(dialogContext, color: _textColorSecondary(dialogContext)), // Use dialogContext
                          hintText: 'Details for this appointment?',
                          hintStyle: _getTextStyle(dialogContext, color: _textColorSecondary(dialogContext).withOpacity(0.7)), // Use dialogContext
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: _scaffoldBgColor(dialogContext), // Use dialogContext
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: _getTextStyle(dialogContext), // Use dialogContext
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel', style: _getTextStyle(dialogContext, color: _textColorSecondary(dialogContext))), // Use dialogContext
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _textColorOnPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text('Send Schedule', style: _getTextStyle(dialogContext, color: _textColorOnPrimary, fontWeight: FontWeight.bold)), // Use dialogContext
                    onPressed: () {
                      if (selectedClientId == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar( // Use dialogContext for SnackBar if it's purely for dialog validation
                          const SnackBar(content: Text('Please select a client.')),
                        );
                        return;
                      }
                      if (selectedTime == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please select an appointment time.')),
                        );
                        return;
                      }

                      final DateTime finalAppointmentDateTime = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime!.hour, selectedTime!.minute,
                      );

                      // --- CORRECTED dietitianName access ---
                      String dietitianDisplayName;
                      if (widget.isDietitianNameLoading) {
                        dietitianDisplayName = currentDietitian.displayName ?? "Dietitian";
                      } else {
                        dietitianDisplayName = (widget.dietitianFirstName.isNotEmpty || widget.dietitianLastName.isNotEmpty)
                            ? "${widget.dietitianFirstName} ${widget.dietitianLastName}".trim()
                            : currentDietitian.displayName ?? "Dietitian";
                      }

                      _saveScheduleToFirestore(
                        dietitianId: currentDietitian.uid,
                        dietitianName: dietitianDisplayName, // Use passed or fallback name
                        clientId: selectedClientId!,
                        clientName: selectedClientName,
                        appointmentDateTime: finalAppointmentDateTime,
                        notes: notesController.text.trim(),
                        status: 'proposed_by_dietitian',
                        contextForSnackBar: this.context, // Use this.context (from _ScheduleCalendarPageState) for SnackBar that shows on main page
                      );
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            }
        );
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
    required BuildContext contextForSnackBar,
  }) async {
    // This method remains the same
    try {
      await FirebaseFirestore.instance.collection('schedules')
          .add({
        'dietitianId': dietitianId,
        'dietitianName': dietitianName,
        'clientId': clientId,
        'clientName': clientName,
        'appointmentDate': Timestamp.fromDate(appointmentDateTime),
        'notes': notes,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return; // Check if widget is still mounted before showing SnackBar
      ScaffoldMessenger.of(contextForSnackBar).showSnackBar(
        SnackBar(content: Text('Schedule proposed to $clientName successfully!'), backgroundColor: _primaryColor),
      );
    } catch (e) {
      print("Error saving schedule: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(contextForSnackBar).showSnackBar(
        SnackBar(content: Text('Error saving schedule: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This build method for ScheduleCalendarPage remains the same
    // (the part that builds the TableCalendar and the "Details for..." section)
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: _cardBgColor(context),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TableCalendar(
                // ... (rest of TableCalendar properties are unchanged)
                locale: 'en_US',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    selectedDecoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                    selectedTextStyle: _getTextStyle(context, color: _textColorOnPrimary, fontWeight: FontWeight.bold),
                    todayDecoration: BoxDecoration(color: _primaryColor.withOpacity(0.5), shape: BoxShape.circle),
                    todayTextStyle: _getTextStyle(context, color: _textColorOnPrimary, fontWeight: FontWeight.bold),
                    weekendTextStyle: _getTextStyle(context, color: _primaryColor.withOpacity(0.8)),
                    defaultTextStyle: _getTextStyle(context, color: _textColorPrimary(context)),
                    markerDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  titleTextStyle: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold, color: _textColorPrimary(context)),
                  formatButtonTextStyle: _getTextStyle(context, color: _textColorOnPrimary),
                  formatButtonDecoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(20.0)),
                  leftChevronIcon: Icon(Icons.chevron_left, color: _textColorPrimary(context)),
                  rightChevronIcon: Icon(Icons.chevron_right, color: _textColorPrimary(context)),
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() { _calendarFormat = format; });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Details for ${DateFormat.yMMMMd().format(_selectedDay!)}:",
                    style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold, color: _textColorPrimary(context)),
                  ),
                  const SizedBox(height: 10),
                  Card( // Placeholder for displaying actual appointments for the day
                    color: _cardBgColor(context),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "No appointments scheduled for this day yet.", // This will be replaced by actual appointment list
                        style: _getTextStyle(context, color: _textColorSecondary(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _textColorOnPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: _textColorOnPrimary)
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text("Schedule New Appointment"),
                      onPressed: () {
                        if (_selectedDay != null) {
                          _showScheduleAppointmentDialog(_selectedDay!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar( // Use context of _ScheduleCalendarPageState
                            const SnackBar(content: Text('Please select a day on the calendar first!')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}


