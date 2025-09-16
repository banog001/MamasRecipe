import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'messages.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // for ImageFilter

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _HomeState();
}

class _HomeState extends State<home> {
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  String selectedMenu = '';
  int selectedIndex = 0;
  /// Widget to display meal plans in a table
  Widget mealPlansTable() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("mealPlans").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var plans = snapshot.data!.docs;
        if (plans.isEmpty) return const Center(child: Text("No meal plans available"));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: plans.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String ownerId = data["owner"] ?? "";
            if (ownerId.isEmpty) return const SizedBox();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("Users").doc(ownerId).get(),
              builder: (context, ownerSnapshot) {
                String ownerName = "Unknown";
                if (ownerSnapshot.hasData && ownerSnapshot.data != null && ownerSnapshot.data!.exists) {
                  var ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>;
                  ownerName = "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}";
                }

                // Format timestamp
                String formattedDate = "";
                if (data["timestamp"] != null && data["timestamp"] is Timestamp) {
                  Timestamp ts = data["timestamp"];
                  DateTime date = ts.toDate();
                  formattedDate = DateFormat('MMM dd, yyyy – hh:mm a').format(date);
                }

                List<List<String?>> grayRows = [
                  ["AM Snack 9:00 AM", data["amSnack"]],
                  ["Lunch 12:00 PM", data["lunch"]],
                  ["PM Snack 3:00 PM", data["pmSnack"]],
                  ["Dinner 6:00 PM", data["dinner"]],
                  ["Midnight Snack 9:00 PM", data["midnightSnack"]],
                ];

                int likeCount = data["likeCounts"] ?? 0;

                final likesCollection = FirebaseFirestore.instance.collection("likes");
                final mealPlanDoc = FirebaseFirestore.instance.collection("mealPlans").doc(doc.id);
                final likeDocId = "${currentUser!.uid}_${doc.id}";
                final likeDocRef = likesCollection.doc(likeDocId);

                return StreamBuilder<DocumentSnapshot>(
                  stream: likeDocRef.snapshots(),
                  builder: (context, likeSnapshot) {
                    bool isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ownerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                if (formattedDate.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  data["planType"] ?? "",
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                                Table(
                                  border: TableBorder.all(color: Colors.grey.shade300),
                                  columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                                  children: [
                                    const TableRow(
                                      decoration: BoxDecoration(color: Color(0xFFE0F2F1)),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Text("Meal", style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Text(
                                            "Breakfast 6:00 AM",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Text(data["breakfast"] ?? ""),
                                        ),
                                      ],
                                    ),
                                    for (var row in grayRows)
                                      TableRow(
                                        children: row.map((cell) {
                                          return Container(
                                            color: Colors.black.withOpacity(0.9),
                                            padding: const EdgeInsets.all(6.0),
                                            child: Text(
                                              cell ?? "",
                                              style: const TextStyle(color: Colors.black54),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Like button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (isLiked) {
                                      // Unlike
                                      await likeDocRef.delete();
                                      await mealPlanDoc.update({"likeCounts": FieldValue.increment(-1)});
                                    } else {
                                      // Like
                                      await likeDocRef.set({
                                        "mealPlanID": doc.id,
                                        "userID": currentUser.uid,
                                        "timestamp": FieldValue.serverTimestamp(),
                                      });
                                      await mealPlanDoc.update({"likeCounts": FieldValue.increment(1)});
                                    }
                                  },
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$likeCount",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
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
          }).toList(),
        );
      },
    );
  }



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

  /// Dietitians horizontal list
  Widget dietitiansList() {
    return SizedBox(
      height: 120,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .where("role", isEqualTo: "dietitian") // filter dietitians
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var dietitians = snapshot.data!.docs;
          if (dietitians.isEmpty) return const Center(child: Text("No dietitians found"));

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: dietitians.length,
            itemBuilder: (context, index) {
              var dietitian = dietitians[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: (dietitian["profile"] != null &&
                          dietitian["profile"].toString().isNotEmpty)
                          ? NetworkImage(dietitian["profile"])
                          : const AssetImage("lib/assets/image/user.png") as ImageProvider,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: Text(
                        "${dietitian["firstName"] ?? ""} ${dietitian["lastName"] ?? ""}",
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> get _pages => [
    // Home page with dietitians list
    SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "Dietitians",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          dietitiansList(),
          const SizedBox(height: 20),
          mealPlansTable(),

        ],
      ),
    ),
    const Center(child: Text("Schedule Page", style: TextStyle(fontSize: 20))),
    const Center(child: Text("Favorites Page", style: TextStyle(fontSize: 20))),
    UsersListPage(currentUserId: firebaseUser!.uid),
    const Center(child: Text("No new notifications", style: TextStyle(fontSize: 20))),
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
                    : const AssetImage("lib/assets/image/user.png") as ImageProvider,
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
            BottomNavigationBarItem(icon: Icon(Icons.edit_calendar), label: 'Schedule'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
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
                MaterialPageRoute(builder: (context) => const LoginPageMobile()),
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

/// Users list for Messages Page with last message preview
class UsersListPage extends StatelessWidget {
  final String currentUserId;

  const UsersListPage({super.key, required this.currentUserId});

  Future<Map<String, dynamic>> getLastMessage(BuildContext context, String otherUserId) async {
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
                  subtitle = "${lastMsg["isMe"] ? "You" : data["firstName"]}: ${lastMsg["message"]}   ${lastMsg["time"]}";
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagesPage(
                          currentUserId: currentUserId,
                          receiverId: user.id,
                          receiverName: "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}",
                          receiverProfile: data["profile"] ?? "",
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: (data["profile"] != null &&
                                data["profile"].toString().isNotEmpty)
                                ? NetworkImage(data["profile"])
                                : const AssetImage("lib/assets/image/user.png") as ImageProvider,
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
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          )
                        ],
                      ),
                      title: Text(
                        "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
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
