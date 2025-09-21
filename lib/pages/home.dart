import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'messages.dart';
import 'package:intl/intl.dart';
// import 'dart:ui'; // REMOVED - Assuming ImageFilter or other direct dart:ui members are not used
import 'UserProfile.dart';
import 'package:shimmer/shimmer.dart'; // Import for Shimmer effect

// --- Style Definitions (Ideally in a separate file or Theme) ---
const String _primaryFontFamily = 'PlusJakartaSans';

const Color _primaryColor = Color(0xFF4CAF50);
Color _scaffoldBgColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100;
Color _cardBgColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white;
Color _textColorPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;
Color _textColorSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54;
const Color _textColorOnPrimary = Colors.white;

TextStyle _sectionTitleStyle(BuildContext context) => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: _textColorPrimary(context));

TextStyle _cardTitleStyle(BuildContext context) => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: _primaryColor);

TextStyle _cardSubtitleStyle(BuildContext context) => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 12,
    color: _textColorSecondary(context));

TextStyle _cardBodyTextStyle(BuildContext context) => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    color: _textColorPrimary(context));

TextStyle _tableHeaderStyle(BuildContext context) => TextStyle(
    fontFamily: _primaryFontFamily,
    fontWeight: FontWeight.bold,
    color: _textColorPrimary(context));

TextStyle _lockedTextStyle(BuildContext context) => TextStyle(
    fontFamily: _primaryFontFamily,
    color: _textColorSecondary(context).withOpacity(0.7),
    fontStyle: FontStyle.italic);
// --- End Style Definitions ---

class home extends StatefulWidget {
  final int initialIndex;
  const home({super.key, this.initialIndex = 0});

  @override
  State<home> createState() => _HomeState();
}

Future<Map<String, dynamic>?> getCurrentUserData() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) return null;

  final userDoc = await FirebaseFirestore.instance
      .collection("Users")
      .doc(currentUser.uid)
      .get();

  if (userDoc.exists) {
    return userDoc.data();
  } else {
    return null;
  }
}

class _HomeState extends State<home> {
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  String selectedMenu = '';
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
              _isUserNameLoading = false;
            });
          } else {
            setState(() {
              firstName = "";
              lastName = "";
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

  Widget recommendationsWidget() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("User not logged in"));
    const double w1 = 1.0;
    const double alpha = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("Recommendations ✨", style: _sectionTitleStyle(context)),
        ),
        SizedBox(
          height: 380,
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection("Users").doc(currentUser.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting && !userSnapshot.hasData) {
                return _buildRecommendationsLoadingShimmer();
              }

              bool isSubscribed = false;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                isSubscribed = userData["isSubscribed"] ?? false;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("mealPlans").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return _buildRecommendationsLoadingShimmer();

                  var docs = snapshot.data!.docs;
                  List<Map<String, dynamic>> scoredPlans = docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    int likes = data["likeCounts"] ?? 0;
                    DateTime publishedDate;
                    if (data["timestamp"] is Timestamp) {
                      publishedDate = (data["timestamp"] as Timestamp).toDate();
                    } else if (data["timestamp"] is String) {
                      publishedDate = DateTime.tryParse(data["timestamp"]) ?? DateTime.now();
                    } else {
                      publishedDate = DateTime.now();
                    }
                    int daysSincePublished = DateTime.now().difference(publishedDate).inDays;
                    if (daysSincePublished == 0) daysSincePublished = 1;
                    double finalScore = (w1 * likes) / (alpha * daysSincePublished);
                    return {"doc": doc, "data": data, "score": finalScore};
                  }).toList();

                  scoredPlans.sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));
                  if (scoredPlans.length > 5) scoredPlans = scoredPlans.sublist(0, 5);

                  if (scoredPlans.isEmpty) {
                    return Center(child: Text("No recommendations yet.", style: _cardBodyTextStyle(context)));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: scoredPlans.length,
                    itemBuilder: (context, index) {
                      final plan = scoredPlans[index];
                      var docSnap = plan["doc"] as DocumentSnapshot;
                      var data = plan["data"] as Map<String, dynamic>;
                      String ownerId = data["owner"] ?? "";
                      return _buildRecommendationCard(context, docSnap, data, ownerId, currentUser.uid, isSubscribed);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) => Card(
        elevation: 2,
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Shimmer.fromColors( // Added Shimmer here
          baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            width: 300,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white, // This color is needed for shimmer to paint on
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isUserSubscribed) {
    return SizedBox(
      width: 300,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _cardBgColor(context),
        child: InkWell(
          onTap: () {
            debugPrint("Tapped on recommendation: ${data['planType']}");
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: (ownerId.isNotEmpty)
                      ? FirebaseFirestore.instance.collection("Users").doc(ownerId).get()
                      : Future.value(null),
                  builder: (context, ownerSnapshot) {
                    String ownerName = "Unknown Chef";
                    String ownerProfileUrl = "";
                    if (ownerId.isNotEmpty && ownerSnapshot.hasData && ownerSnapshot.data != null && ownerSnapshot.data!.exists) {
                      var ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>;
                      ownerName = "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}".trim();
                      if (ownerName.isEmpty) ownerName = "Unknown Chef";
                      ownerProfileUrl = ownerData["profile"] ?? "";
                    }
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: ownerProfileUrl.isNotEmpty ? NetworkImage(ownerProfileUrl) : null,
                          backgroundColor: Colors.grey.shade300,
                          child: ownerProfileUrl.isEmpty ? const Icon(Icons.person, size: 18) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                style: _cardTitleStyle(context).copyWith(color: _primaryColor, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (data["timestamp"] != null && data["timestamp"] is Timestamp)
                                Text(
                                  DateFormat('MMM dd, yyyy').format((data["timestamp"] as Timestamp).toDate()),
                                  style: _cardSubtitleStyle(context),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  data["planType"] ?? "Meal Plan",
                  style: _sectionTitleStyle(context).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(3.5)
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Time", style: _tableHeaderStyle(context).copyWith(color: _primaryColor)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Meal", style: _tableHeaderStyle(context).copyWith(color: _primaryColor)),
                            ),
                          ],
                        ),
                        _buildMealRow("Breakfast", data["breakfast"], true),
                        _buildMealRow("AM Snack", data["amSnack"], isUserSubscribed),
                        _buildMealRow("Lunch", data["lunch"], isUserSubscribed),
                        _buildMealRow("PM Snack", data["pmSnack"], isUserSubscribed),
                        _buildMealRow("Dinner", data["dinner"], isUserSubscribed),
                        _buildMealRow("Midnight Snack", data["midnightSnack"], isUserSubscribed),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection("likes").doc("${currentUserId}_${doc.id}").snapshots(),
                      builder: (context, likeSnapshot) {
                        bool isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;
                        int likeCount = data["likeCounts"] ?? 0;
                        return TextButton.icon(
                            onPressed: () async {
                              final likeDocRef = FirebaseFirestore.instance.collection("likes").doc("${currentUserId}_${doc.id}");
                              final mealPlanDocRef = FirebaseFirestore.instance.collection("mealPlans").doc(doc.id);
                              if (isLiked) {
                                await likeDocRef.delete();
                                await mealPlanDocRef.update({"likeCounts": FieldValue.increment(-1)});
                              } else {
                                await likeDocRef.set({
                                  "mealPlanID": doc.id,
                                  "userID": currentUserId,
                                  "timestamp": FieldValue.serverTimestamp()
                                });
                                await mealPlanDocRef.update({"likeCounts": FieldValue.increment(1)});
                              }
                            },
                            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 20),
                            label: Text("$likeCount",
                                style: const TextStyle(
                                    color: Colors.redAccent, fontFamily: _primaryFontFamily, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4))
                        );
                      }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget mealPlansTable() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("User not logged in"));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("Users").doc(currentUser.uid).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: _primaryColor));

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String userGoal = userData["goals"] ?? "";
          bool isSubscribed = userData["isSubscribed"] ?? false;

          if (userGoal.isEmpty) {
            return Center(child: Text("Set your health goal to see meal plans!", style: _cardBodyTextStyle(context)));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: Text("Meal Plans for: $userGoal", style: _sectionTitleStyle(context)),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("mealPlans").where("planType", isEqualTo: userGoal).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _primaryColor));
                  var plans = snapshot.data!.docs;
                  if (plans.isEmpty) {
                    return Center(child: Text("No $userGoal meal plans available yet.", style: _cardBodyTextStyle(context)));
                  }

                  return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final docSnap = plans[index];
                        final data = docSnap.data() as Map<String, dynamic>;
                        final ownerId = data["owner"] ?? "";
                        return _buildMealPlanListItem(context, docSnap, data, ownerId, currentUser.uid, isSubscribed);
                      });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMealPlanListItem(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isUserSubscribed) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
      child: InkWell(
        onTap: () { /* TODO: Navigate to full meal plan detail */ },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                  future: (ownerId.isNotEmpty) ? FirebaseFirestore.instance.collection("Users").doc(ownerId).get() : Future.value(null),
                  builder: (context, ownerSnapshot) {
                    String ownerName = "Unknown Chef";
                    if (ownerId.isNotEmpty && ownerSnapshot.hasData && ownerSnapshot.data != null && ownerSnapshot.data!.exists) {
                      var ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>;
                      ownerName = "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}".trim();
                      if (ownerName.isEmpty) ownerName = "Unknown Chef";
                    }
                    return Text(ownerName, style: _cardTitleStyle(context).copyWith(fontSize: 15));
                  }),
              const SizedBox(height: 4),
              Text(data["planType"] ?? "Meal Plan",
                  style: _cardBodyTextStyle(context).copyWith(fontWeight: FontWeight.w600, fontSize: 17)),
              if (data["timestamp"] != null && data["timestamp"] is Timestamp)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormat('MMM dd, yyyy – hh:mm a').format((data["timestamp"] as Timestamp).toDate()),
                    style: _cardSubtitleStyle(context),
                  ),
                ),
              const Divider(height: 20),
              Table(
                children: [
                  _buildMealRow("Breakfast", data["breakfast"], true, isCompact: true),
                  _buildMealRow("Lunch", data["lunch"], isUserSubscribed, isCompact: true),
                  _buildMealRow("Dinner", data["dinner"], isUserSubscribed, isCompact: true),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection("likes").doc("${currentUserId}_${doc.id}").snapshots(),
                    builder: (context, likeSnapshot) {
                      bool isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;
                      int likeCount = data["likeCounts"] ?? 0;
                      return TextButton.icon(
                        onPressed: () async {
                          final likeDocRef = FirebaseFirestore.instance.collection("likes").doc("${currentUserId}_${doc.id}");
                          final mealPlanDocRef = FirebaseFirestore.instance.collection("mealPlans").doc(doc.id);
                          if (isLiked) {
                            await likeDocRef.delete();
                            await mealPlanDocRef.update({"likeCounts": FieldValue.increment(-1)});
                          } else {
                            await likeDocRef.set({
                              "mealPlanID": doc.id,
                              "userID": currentUserId,
                              "timestamp": FieldValue.serverTimestamp()
                            });
                            await mealPlanDocRef.update({"likeCounts": FieldValue.increment(1)});
                          }
                        },
                        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 18),
                        label: Text("$likeCount",
                            style: const TextStyle(
                                color: Colors.redAccent, fontFamily: _primaryFontFamily, fontWeight: FontWeight.w600, fontSize: 13)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
                      );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildMealRow(String time, String? meal, bool isSubscribed, {bool isCompact = false}) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 4.0 : 6.0, horizontal: 6.0),
          child: Text(time, style: _tableHeaderStyle(context).copyWith(fontSize: isCompact ? 13 : 14, color: _textColorPrimary(context))),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 4.0 : 6.0, horizontal: 6.0),
          child: Text(
            isSubscribed ? (meal ?? "Not specified") : "🔒 Locked",
            style: isSubscribed
                ? _cardBodyTextStyle(context).copyWith(fontSize: isCompact ? 13 : 14)
                : _lockedTextStyle(context).copyWith(fontSize: isCompact ? 13 : 14),
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget dietitiansList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("Connect with Dietitians 🧑‍⚕️", style: _sectionTitleStyle(context)),
        ),
        SizedBox(
          height: 130, // Adjusted height
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("Users").where("role", isEqualTo: "dietitian").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _primaryColor));
              var dietitians = snapshot.data!.docs;
              if (dietitians.isEmpty) {
                return Center(child: Text("No dietitians found.", style: _cardBodyTextStyle(context)));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: dietitians.length,
                itemBuilder: (context, index) {
                  var dietitianData = dietitians[index].data() as Map<String, dynamic>;
                  String name = "${dietitianData["firstName"] ?? ""} ${dietitianData["lastName"] ?? ""}".trim();
                  if (name.isEmpty) name = "Dietitian";
                  String profileUrl = dietitianData["profile"] ?? "";

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30, // Corrected Radius
                          backgroundColor: _primaryColor.withOpacity(0.2),
                          backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                          child: profileUrl.isEmpty ? const Icon(Icons.person, size: 30, color: _primaryColor) : null,
                        ),
                        const SizedBox(height: 6), // Corrected Spacing
                        SizedBox(
                          width: 80,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: _cardBodyTextStyle(context).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
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

  Future<void> _updateGooglePhotoURL() async {
    if (firebaseUser != null) {
      String? photoURL = firebaseUser!.photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(firebaseUser!.uid)
              .set({"profile": photoURL}, SetOptions(merge: true));
        } catch (e) {
          debugPrint("Error updating Google Photo URL in Firestore: $e");
        }
      }
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
        debugPrint("Error setting user status: $e");
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
    SingleChildScrollView(
      key: const PageStorageKey('homePageScroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dietitiansList(),
          const SizedBox(height: 10),
          recommendationsWidget(),
          const SizedBox(height: 10),
          mealPlansTable(),
          const SizedBox(height: 20),
        ],
      ),
    ),
    Scaffold(
        appBar: AppBar(title: Text("Schedule", style: TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, color: _textColorOnPrimary, fontSize: 20)), backgroundColor: _primaryColor, iconTheme: const IconThemeData(color: _textColorOnPrimary)),
        backgroundColor: _scaffoldBgColor(context),
        body: Center(child: Text("Schedule Page Content", style: _sectionTitleStyle(context)))),
    UsersListPage(currentUserId: firebaseUser!.uid),
  ];

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        body: Center(child: Text("No user logged in.", style: _cardBodyTextStyle(context))),
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
                  (firstName.isNotEmpty || lastName.isNotEmpty) ? "$firstName $lastName".trim() : "User Profile",
                  style: const TextStyle(
                      fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, fontSize: 18, color: _textColorOnPrimary),
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
                    : (firebaseUser!.email != null && firebaseUser!.email!.isNotEmpty
                    ? Text(
                  firebaseUser!.email!,
                  style: const TextStyle(fontFamily: _primaryFontFamily, fontSize: 14, color: _textColorOnPrimary),
                )
                    : null),
                currentAccountPicture: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: (firebaseUser!.photoURL != null && firebaseUser!.photoURL!.isNotEmpty)
                      ? NetworkImage(firebaseUser!.photoURL!)
                      : null,
                  child: (firebaseUser!.photoURL == null || firebaseUser!.photoURL!.isEmpty)
                      ? const Icon(Icons.person, size: 30, color: _primaryColor)
                      : null,
                ),
                decoration: const BoxDecoration(
                  color: _primaryColor,
                ),
                otherAccountsPictures: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: _textColorOnPrimary.withOpacity(0.8)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfile()));
                    },
                    tooltip: "Edit Profile",
                  )
                ],
              ),
              buildMenuTile('Subscription', Icons.subscriptions_outlined, Icons.subscriptions),
              buildMenuTile('Settings', Icons.settings_outlined, Icons.settings),
              buildMenuTile('About', Icons.info_outline, Icons.info),
              const Divider(indent: 16, endIndent: 16),
              buildMenuTile('Logout', Icons.logout_outlined, Icons.logout),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: _textColorOnPrimary, size: 28),
        title: Text(
          selectedIndex == 0 ? "Mama's Recipe" : (selectedIndex == 1 ? "Schedule" : "Messages"),
          style: const TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, color: _textColorOnPrimary, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfile()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _textColorOnPrimary.withOpacity(0.2),
                backgroundImage: (firebaseUser!.photoURL != null && firebaseUser!.photoURL!.isNotEmpty)
                    ? NetworkImage(firebaseUser!.photoURL!)
                    : null,
                child: (firebaseUser!.photoURL == null || firebaseUser!.photoURL!.isEmpty)
                    ? Icon(Icons.person_outline, size: 20, color: _textColorOnPrimary.withOpacity(0.8))
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: _pages[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _primaryColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
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
            selectedLabelStyle: const TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontFamily: _primaryFontFamily, fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.edit_calendar_outlined), activeIcon: Icon(Icons.edit_calendar), label: 'Schedule'),
              BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Messages'),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuTile(String label, IconData icon, IconData activeIcon) {
    bool isSelected = selectedMenu == label;
    final Color itemColor = isSelected ? _primaryColor : _textColorPrimary(context);
    final Color itemBgColor = isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(isSelected ? activeIcon : icon, color: itemColor, size: 24),
        title: Text(
          label,
          style: TextStyle(
              fontFamily: _primaryFontFamily,
              color: itemColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15),
        ),
        onTap: () async {
          Navigator.pop(context);
          if (label == 'Logout') {
            bool signedOut = await signOutFromGoogle();
            if (signedOut && mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPageMobile()),
                    (Route<dynamic> route) => false,
              );
            }
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
  String getChatRoomId(String userA, String userB) {
    // Ensure consistent ordering to have the same chatRoomID for both users
    return userA.hashCode <= userB.hashCode ? "${userA}_$userB" : "${userB}_$userA";
  }

  final String currentUserId;
  const UsersListPage({super.key, required this.currentUserId});
  Future<Map<String, dynamic>> getLastMessage(
      BuildContext context,
      String otherUserId,
      String otherUserName, // Pass the receiver's display name
      ) async {
    // Query messages between currentUserId and otherUserId
    final query = await FirebaseFirestore.instance
        .collection("messages")
        .where("chatRoomID", isEqualTo: getChatRoomId(currentUserId, otherUserId))
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return {"message": "", "senderName": "", "time": ""};
    }

    final data = query.docs.first.data();
    final timestamp = data["timestamp"];
    String formattedTime = "";

    if (timestamp is Timestamp) {
      DateTime messageDate = timestamp.toDate();
      DateTime nowDate = DateTime.now();
      if (messageDate.year == nowDate.year &&
          messageDate.month == nowDate.month &&
          messageDate.day == nowDate.day) {
        formattedTime = TimeOfDay.fromDateTime(messageDate).format(context); // HH:mm
      } else {
        formattedTime = DateFormat('MMM d').format(messageDate); // e.g., Jan 5
      }
    }

    bool isMe = data["senderId"] == currentUserId;
    String senderName = isMe ? "You" : otherUserName;

    return {
      "message": data["message"] ?? "",
      "senderName": senderName,
      "time": formattedTime,
    };
  }


  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentScaffoldBg = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50; // Lighter bg for content
    final Color currentAppBarBg = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color currentTabLabel = _textColorPrimary(context); // Use themed primary text color
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
            labelStyle: const TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontFamily: _primaryFontFamily, fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: "CHATS"), // Changed from MESSAGES
              Tab(text: "NOTIFICATIONS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
        // where("role", isEqualTo: "dietitian")
              stream: FirebaseFirestore.instance.collection("Users").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No dietitians to chat with yet.", style: _cardBodyTextStyle(context)));
                }

                var users = snapshot.data!.docs;
                return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var userDoc = users[index]; // Renamed for clarity
                      var data = userDoc.data() as Map<String, dynamic>;
                      if (userDoc.id == currentUserId) return const SizedBox.shrink();

                      return FutureBuilder<Map<String, dynamic>>(
                        future: getLastMessage(context, userDoc.id, "${data["firstName"]} ${data["lastName"]}".trim()),
                        builder: (context, snapshotMessage) {
                          String subtitleText = "No messages yet";
                          String timeText = "";

                          if (snapshotMessage.connectionState == ConnectionState.done && snapshotMessage.hasData) {
                            final lastMsg = snapshotMessage.data!;
                            if ((lastMsg["message"] ?? "").isNotEmpty) {
                              subtitleText = "${lastMsg["senderName"]}: ${lastMsg["message"]}";
                              timeText = lastMsg["time"] ?? "";
                            }
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (data["profile"] != null && data["profile"].toString().isNotEmpty)
                                  ? NetworkImage(data["profile"])
                                  : null,
                              child: (data["profile"] == null || data["profile"].toString().isEmpty)
                                  ? Icon(Icons.person_outline, color: _primaryColor)
                                  : null,
                            ),
                            title: Text("${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim()),
                            subtitle: Text(subtitleText, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: timeText.isNotEmpty ? Text(timeText, style: TextStyle(fontSize: 12)) : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessagesPage(
                                    currentUserId: currentUserId,
                                    receiverId: userDoc.id,
                                    receiverName: "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim(),
                                    receiverProfile: data["profile"] ?? "",
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      var userDoc = users[index];
                      if (userDoc.id == currentUserId && index < users.length -1 && users[index+1].id == currentUserId) return const SizedBox.shrink(); // Avoid double separator if current user is filtered out
                      if(userDoc.id == currentUserId) return const SizedBox.shrink();
                      return const Divider(height: 0.5, indent: 88, endIndent: 16, thickness: 0.5); // Thinner divider
                    }
                );
              },
            ),
            Center(
                child:
                Text("No new notifications.", style: _cardBodyTextStyle(context)
                )
            ),
          ],
        ),
      ),
    );
  }
}
