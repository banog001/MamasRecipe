import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../pages/login.dart';
import '../pages/messages.dart';
import 'createMealPlan.dart';

class HomePageDietitian extends StatefulWidget {
  const HomePageDietitian({super.key});

  @override
  State<HomePageDietitian> createState() => _HomePageDietitianState();
}

class _HomePageDietitianState extends State<HomePageDietitian> {
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  String selectedMenu = '';
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _setUserStatus("online");
    _updateGooglePhotoURL();
  }

  Future<void> _updateGooglePhotoURL() async {
    if (firebaseUser != null) {
      String? photoURL = firebaseUser!.photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(firebaseUser!.uid)
            .set({"profile": photoURL}, SetOptions(merge: true));
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
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      debugPrint("Sign out error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _setUserStatus("offline");
    super.dispose();
  }

  List<Widget> get _pages => [
    // Home Page with Add a Meal Plan button
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "You're Dietitian",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
  onPressed: () {
  Navigator.push(
  context,
  MaterialPageRoute(
  builder: (context) => const CreateMealPlanPage(), // ✅ new file
  ),
  );
  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Add a Meal Plan",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ),

    const Center(
        child: Text("Schedule Page", style: TextStyle(fontSize: 20))),
    const Center(
        child: Text("Favorites Page", style: TextStyle(fontSize: 20))),
    UsersListPage(currentUserId: FirebaseAuth.instance.currentUser!.uid),
    const Center(
        child: Text("No new notifications", style: TextStyle(fontSize: 20))),
  ];

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in.")),
      );
    }

    return Scaffold(
      drawer: SizedBox(
        width: 220,
        child: Drawer(
          child: Container(
            color: const Color(0xFF4CAF50),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                  ),
                  child: Text(
                    firebaseUser!.email ?? "MENU",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                buildMenuTile('Subscription', Icons.subscriptions),
                buildMenuTile('Settings', Icons.settings),
                buildMenuTile('About', Icons.info),
                const Divider(color: Colors.white70),
                buildMenuTile('Logout', Icons.logout),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 36,
        ),
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {},
              child: CircleAvatar(
                radius: 20,
                backgroundImage: (firebaseUser != null &&
                    firebaseUser!.photoURL != null &&
                    firebaseUser!.photoURL!.isNotEmpty)
                    ? NetworkImage(firebaseUser!.photoURL!)
                    : const AssetImage("lib/assets/image/user.png")
                as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: _pages[selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            setState(() => selectedIndex = index);
          },
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white30,
          backgroundColor: Colors.green,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.edit_calendar), label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite), label: 'Favorites'),
            BottomNavigationBarItem(
                icon: Icon(Icons.message), label: 'Messages'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: 'Notifications'),
          ],
        ),
      ),
    );
  }

  Widget buildMenuTile(String label, IconData icon) {
    bool isSelected = selectedMenu == label;

    return Container(
      color: isSelected ? Colors.white : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.green[700] : Colors.white,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.green[700] : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          if (label == 'Logout') {
            bool signedOut = await signOutFromGoogle();
            if (signedOut) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const LoginPageMobile()),
                    (Route<dynamic> route) => false,
              );
            }
          } else {
            setState(() {
              selectedMenu = label;
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

/// ✅ Users list for Messages Page
class UsersListPage extends StatelessWidget {
  final String currentUserId;

  const UsersListPage({super.key, required this.currentUserId});

  Future<Map<String, dynamic>> getLastMessage(
      BuildContext context, String otherUserId) async {
    final query = await FirebaseFirestore.instance
        .collection("messages")
        .where("senderId", whereIn: [currentUserId, otherUserId])
        .where("receiverId", whereIn: [currentUserId, otherUserId])
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return {"message": "", "isMe": false, "time": ""};
    }

    final data = query.docs.first.data();
    final timestamp = data["timestamp"] != null
        ? (data["timestamp"] as Timestamp).toDate()
        : DateTime.now();

    final formattedTime = TimeOfDay.fromDateTime(timestamp).format(context);

    return {
      "message": data["message"] ?? "",
      "isMe": data["senderId"] == currentUserId,
      "time": formattedTime
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("Users").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found."));
        }

        var users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            var data = user.data() as Map<String, dynamic>;
            bool isCurrentUser = user.id == currentUserId;
            bool isOnline = data["status"] == "online";

            if (isCurrentUser) return const SizedBox();

            return FutureBuilder<Map<String, dynamic>>(
              future: getLastMessage(context, user.id),
              builder: (context, snapshotMessage) {
                String subtitle = "";
                if (snapshotMessage.connectionState == ConnectionState.done &&
                    snapshotMessage.hasData) {
                  final lastMsg = snapshotMessage.data!;
                  subtitle =
                  "${lastMsg["isMe"] ? "You" : data["firstName"]}: ${lastMsg["message"]}   ${lastMsg["time"]}";
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagesPage(
                          currentUserId: currentUserId,
                          receiverId: user.id,
                          receiverName:
                          "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}",
                          receiverProfile: data["profile"] ?? "",
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: (data["profile"] != null &&
                                data["profile"].toString().isNotEmpty)
                                ? NetworkImage(data["profile"])
                                : const AssetImage("lib/assets/image/user.png")
                            as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          )
                        ],
                      ),
                      title: Text(
                        "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
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
  }
}
