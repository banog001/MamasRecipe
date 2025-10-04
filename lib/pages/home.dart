import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'messages.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'dart:ui'; // REMOVED - Assuming ImageFilter or other direct dart:ui members are not used
import 'UserProfile.dart';
import 'package:shimmer/shimmer.dart'; // Import for Shimmer effect
import 'subscription_model.dart';
import 'subscription_service.dart';
import 'subscription_page.dart';

// --- Style Definitions (Ideally in a separate file or Theme) ---
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
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}

TextStyle _sectionTitleStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: _textColorPrimary(context),
);

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

TextStyle _cardBodyTextStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 14,
  color: _textColorPrimary(context),
);

TextStyle _tableHeaderStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontWeight: FontWeight.bold,
  color: _textColorPrimary(context),
);

TextStyle _lockedTextStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  color: _textColorSecondary(context).withOpacity(0.7),
  fontStyle: FontStyle.italic,
);
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
  String profileUrl = "";
  bool _isUserNameLoading = true;

  Map<String, dynamic>? userData;
  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _setUserStatus("online");
    _updateGooglePhotoURL();
    loadUserName();
  }

  // Inside class _HomeState, replace your existing loadUserName() with this:

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
              profileUrl =
                  data['profile'] as String? ?? ''; // <-- ADD THIS LINE
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

  Widget recommendationsWidget() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null)
      return const Center(child: Text("User not logged in"));
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
            future: FirebaseFirestore.instance
                .collection("Users")
                .doc(currentUser.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting &&
                  !userSnapshot.hasData) {
                return _buildRecommendationsLoadingShimmer();
              }

              bool isSubscribed = false;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                isSubscribed = userData["isSubscribed"] ?? false;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("mealPlans")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return _buildRecommendationsLoadingShimmer();

                  var docs = snapshot.data!.docs;
                  List<Map<String, dynamic>> scoredPlans = docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    int likes = data["likeCounts"] ?? 0;
                    DateTime publishedDate;
                    if (data["timestamp"] is Timestamp) {
                      publishedDate = (data["timestamp"] as Timestamp).toDate();
                    } else if (data["timestamp"] is String) {
                      publishedDate =
                          DateTime.tryParse(data["timestamp"]) ??
                          DateTime.now();
                    } else {
                      publishedDate = DateTime.now();
                    }
                    int daysSincePublished = DateTime.now()
                        .difference(publishedDate)
                        .inDays;
                    if (daysSincePublished == 0) daysSincePublished = 1;
                    double finalScore =
                        (w1 * likes) / (alpha * daysSincePublished);
                    return {"doc": doc, "data": data, "score": finalScore};
                  }).toList();

                  scoredPlans.sort(
                    (a, b) =>
                        (b["score"] as double).compareTo(a["score"] as double),
                  );
                  if (scoredPlans.length > 5)
                    scoredPlans = scoredPlans.sublist(0, 5);

                  if (scoredPlans.isEmpty) {
                    return Center(
                      child: Text(
                        "No recommendations yet.",
                        style: _cardBodyTextStyle(context),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: scoredPlans.length,
                    itemBuilder: (context, index) {
                      final plan = scoredPlans[index];
                      var docSnap = plan["doc"] as DocumentSnapshot;
                      var data = plan["data"] as Map<String, dynamic>;
                      String ownerId = data["owner"] ?? "";
                      return _buildRecommendationCard(
                        context,
                        docSnap,
                        data,
                        ownerId,
                        currentUser.uid,
                        isSubscribed,
                      );
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
        child: Shimmer.fromColors(
          // Added Shimmer here
          baseColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
          highlightColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
          child: Container(
            width: 300,
            height: 350,
            decoration: BoxDecoration(
              color:
                  Colors.white, // This color is needed for shimmer to paint on
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
    bool isUserSubscribed,
  ) {
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
                      ? FirebaseFirestore.instance
                            .collection("Users")
                            .doc(ownerId)
                            .get()
                      : Future.value(null),
                  builder: (context, ownerSnapshot) {
                    String ownerName = "Unknown Chef";
                    String ownerProfileUrl = "";
                    if (ownerId.isNotEmpty &&
                        ownerSnapshot.hasData &&
                        ownerSnapshot.data != null &&
                        ownerSnapshot.data!.exists) {
                      var ownerData =
                          ownerSnapshot.data!.data() as Map<String, dynamic>;
                      ownerName =
                          "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                              .trim();
                      if (ownerName.isEmpty) ownerName = "Unknown Chef";
                      ownerProfileUrl = ownerData["profile"] ?? "";
                    }
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: (profileUrl.isNotEmpty)
                              ? NetworkImage(profileUrl)
                              : null,
                          child: (profileUrl.isEmpty)
                              ? const Icon(Icons.person, size: 30, color: _primaryColor)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                style: _cardTitleStyle(
                                  context,
                                ).copyWith(color: _primaryColor, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (data["timestamp"] != null &&
                                  data["timestamp"] is Timestamp)
                                Text(
                                  DateFormat('MMM dd, yyyy').format(
                                    (data["timestamp"] as Timestamp).toDate(),
                                  ),
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
                  style: _sectionTitleStyle(
                    context,
                  ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(3.5),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Time",
                                style: _tableHeaderStyle(
                                  context,
                                ).copyWith(color: _primaryColor),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Meal",
                                style: _tableHeaderStyle(
                                  context,
                                ).copyWith(color: _primaryColor),
                              ),
                            ),
                          ],
                        ),
                        _buildMealRow("Breakfast", data["breakfast"], true),
                        _buildMealRow(
                          "AM Snack",
                          data["amSnack"],
                          isUserSubscribed,
                        ),
                        _buildMealRow("Lunch", data["lunch"], isUserSubscribed),
                        _buildMealRow(
                          "PM Snack",
                          data["pmSnack"],
                          isUserSubscribed,
                        ),
                        _buildMealRow(
                          "Dinner",
                          data["dinner"],
                          isUserSubscribed,
                        ),
                        _buildMealRow(
                          "Midnight Snack",
                          data["midnightSnack"],
                          isUserSubscribed,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("likes")
                        .doc("${currentUserId}_${doc.id}")
                        .snapshots(),
                    builder: (context, likeSnapshot) {
                      bool isLiked =
                          likeSnapshot.hasData && likeSnapshot.data!.exists;
                      int likeCount = data["likeCounts"] ?? 0;
                      return TextButton.icon(
                        onPressed: () async {
                          final likeDocRef = FirebaseFirestore.instance
                              .collection("likes")
                              .doc("${currentUserId}_${doc.id}");
                          final mealPlanDocRef = FirebaseFirestore.instance
                              .collection("mealPlans")
                              .doc(doc.id);
                          if (isLiked) {
                            await likeDocRef.delete();
                            await mealPlanDocRef.update({
                              "likeCounts": FieldValue.increment(-1),
                            });
                          } else {
                            await likeDocRef.set({
                              "mealPlanID": doc.id,
                              "userID": currentUserId,
                              "timestamp": FieldValue.serverTimestamp(),
                            });
                            await mealPlanDocRef.update({
                              "likeCounts": FieldValue.increment(1),
                            });
                          }
                        },
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        label: Text(
                          "$likeCount",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: _primaryFontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget mealPlansTable() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null)
      return const Center(child: Text("User not logged in"));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUser.uid)
            .get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String userGoal = userData["goals"] ?? "";
          bool isSubscribed = userData["isSubscribed"] ?? false;

          if (userGoal.isEmpty) {
            return Center(
              child: Text(
                "Set your health goal to see meal plans!",
                style: _cardBodyTextStyle(context),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: Text(
                  "Meal Plans for: $userGoal",
                  style: _sectionTitleStyle(context),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("mealPlans")
                    .where("planType", isEqualTo: userGoal)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  var plans = snapshot.data!.docs;
                  if (plans.isEmpty) {
                    return Center(
                      child: Text(
                        "No $userGoal meal plans available yet.",
                        style: _cardBodyTextStyle(context),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final docSnap = plans[index];
                      final data = docSnap.data() as Map<String, dynamic>;
                      final ownerId = data["owner"] ?? "";
                      return _buildMealPlanListItem(
                        context,
                        docSnap,
                        data,
                        ownerId,
                        currentUser.uid,
                        isSubscribed,
                      );
                    },
                  );
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
    bool isUserSubscribed,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
      child: InkWell(
        onTap: () {
          /* TODO: Navigate to full meal plan detail */
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: (ownerId.isNotEmpty)
                    ? FirebaseFirestore.instance
                          .collection("Users")
                          .doc(ownerId)
                          .get()
                    : Future.value(null),
                builder: (context, ownerSnapshot) {
                  String ownerName = "Unknown Chef";
                  if (ownerId.isNotEmpty &&
                      ownerSnapshot.hasData &&
                      ownerSnapshot.data != null &&
                      ownerSnapshot.data!.exists) {
                    var ownerData =
                        ownerSnapshot.data!.data() as Map<String, dynamic>;
                    ownerName =
                        "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                            .trim();
                    if (ownerName.isEmpty) ownerName = "Unknown Chef";
                  }
                  return Text(
                    ownerName,
                    style: _cardTitleStyle(context).copyWith(fontSize: 15),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                data["planType"] ?? "Meal Plan",
                style: _cardBodyTextStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 17),
              ),
              if (data["timestamp"] != null && data["timestamp"] is Timestamp)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormat(
                      'MMM dd, yyyy – hh:mm a',
                    ).format((data["timestamp"] as Timestamp).toDate()),
                    style: _cardSubtitleStyle(context),
                  ),
                ),
              const Divider(height: 20),
              Table(
                children: [
                  _buildMealRow(
                    "Breakfast",
                    data["breakfast"],
                    true,
                    isCompact: true,
                  ),
                  _buildMealRow(
                    "AM Snack",
                    data["amSnack"],
                    isUserSubscribed,
                    isCompact: true,
                  ),
                  _buildMealRow(
                    "Lunch",
                    data["lunch"],
                    isUserSubscribed,
                    isCompact: true,
                  ),
                  _buildMealRow(
                    "Pm Snack",
                    data["pmSnack"],
                    isUserSubscribed,
                    isCompact: true,
                  ),
                  _buildMealRow(
                    "Dinner",
                    data["dinner"],
                    isUserSubscribed,
                    isCompact: true,
                  ),
                  _buildMealRow(
                    "Midnight Snack",
                    data["midnightSnack"],
                    isUserSubscribed,
                    isCompact: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("likes")
                      .doc("${currentUserId}_${doc.id}")
                      .snapshots(),
                  builder: (context, likeSnapshot) {
                    bool isLiked =
                        likeSnapshot.hasData && likeSnapshot.data!.exists;
                    int likeCount = data["likeCounts"] ?? 0;
                    return TextButton.icon(
                      onPressed: () async {
                        final likeDocRef = FirebaseFirestore.instance
                            .collection("likes")
                            .doc("${currentUserId}_${doc.id}");
                        final mealPlanDocRef = FirebaseFirestore.instance
                            .collection("mealPlans")
                            .doc(doc.id);
                        if (isLiked) {
                          await likeDocRef.delete();
                          await mealPlanDocRef.update({
                            "likeCounts": FieldValue.increment(-1),
                          });
                        } else {
                          await likeDocRef.set({
                            "mealPlanID": doc.id,
                            "userID": currentUserId,
                            "timestamp": FieldValue.serverTimestamp(),
                          });
                          await mealPlanDocRef.update({
                            "likeCounts": FieldValue.increment(1),
                          });
                        }
                      },
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      label: Text(
                        "$likeCount",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                      ),
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

  TableRow _buildMealRow(
    String time,
    String? meal,
    bool isSubscribed, {
    bool isCompact = false,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 4.0 : 6.0,
            horizontal: 6.0,
          ),
          child: Text(
            time,
            style: _tableHeaderStyle(context).copyWith(
              fontSize: isCompact ? 13 : 14,
              color: _textColorPrimary(context),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 4.0 : 6.0,
            horizontal: 6.0,
          ),
          child: Text(
            isSubscribed ? (meal ?? "Not specified") : "🔒 Locked",
            style: isSubscribed
                ? _cardBodyTextStyle(
                    context,
                  ).copyWith(fontSize: isCompact ? 13 : 14)
                : _lockedTextStyle(
                    context,
                  ).copyWith(fontSize: isCompact ? 13 : 14),
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
          child: Text(
            "Connect with Dietitians 🧑‍⚕️",
            style: _sectionTitleStyle(context),
          ),
        ),
        SizedBox(
          height: 130, // Adjusted height
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("Users")
                .where("role", isEqualTo: "dietitian")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                );
              var dietitians = snapshot.data!.docs;
              if (dietitians.isEmpty) {
                return Center(
                  child: Text(
                    "No dietitians found.",
                    style: _cardBodyTextStyle(context),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: dietitians.length,
                itemBuilder: (context, index) {
                  var dietitianData =
                      dietitians[index].data() as Map<String, dynamic>;
                  String name =
                      "${dietitianData["firstName"] ?? ""} ${dietitianData["lastName"] ?? ""}"
                          .trim();
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
                          backgroundImage: (profileUrl.isNotEmpty)
                              ? NetworkImage(profileUrl)
                              : null,
                          child: (profileUrl.isEmpty)
                              ? const Icon(Icons.person, size: 30, color: _primaryColor)
                              : null,
                        ),
                        const SizedBox(height: 6), // Corrected Spacing
                        SizedBox(
                          width: 80,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: _cardBodyTextStyle(context).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
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
      // Home Tab Content (Page 0) - From your existing code
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
    // Page 1: User's Schedule (NEW)
    // Conditional rendering based on firebaseUser ensures currentUserId is not null
    firebaseUser != null
        ? UserSchedulePage(currentUserId: firebaseUser!.uid)
        : const Center(
            child: Text(
              "Please log in to view your schedule.",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ), // Fallback
    // Page 2: Messages Tab (UsersListPage from your existing code)
    firebaseUser != null
        ? UsersListPage(currentUserId: firebaseUser!.uid)
        : const Center(
            child: Text(
              "Please log in to view messages.",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ), // Fallback
    // Page 3: Profile Tab (NEW)
    firebaseUser != null
        ? const UserProfile() // Assuming UserProfile is the correct widget for the profile tab
        : const Center(
            child: Text(
              "Please log in to view your profile.",
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
          ), // Fallback
  ];

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        body: Center(
          child: Text("No user logged in.", style: _cardBodyTextStyle(context)),
        ),
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
                          builder: (context) => const UserProfile(),
                        ),
                      );
                    },
                    tooltip: "Edit Profile",
                  ),
                ],
              ),
              buildMenuTile(
                'Subscription',
                Icons.subscriptions_outlined,
                Icons.subscriptions,
              ),
              buildMenuTile(
                'Settings',
                Icons.settings_outlined,
                Icons.settings,
              ),
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
          // MODIFIED: AppBar title logic for the new schedule tab
          selectedIndex == 0
              ? "Mama's Recipe"
              : (selectedIndex == 1
                    ? "My Schedule"
                    : (selectedIndex == 2 ? "Messages" : "Profile")),
          style: const TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
            fontSize: 20,
          ),
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30, color: _primaryColor),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final profileUrl = data?['profile'] ?? '';

                  return CircleAvatar(
                    backgroundImage: (profileUrl.isNotEmpty)
                        ? NetworkImage(profileUrl)
                        : null,
                    child: (profileUrl.isEmpty)
                        ? const Icon(Icons.person, size: 30, color: _primaryColor)
                        : null,
                  );
                },
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
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
              if (index == 3) {
                // Profile button tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfile(),
                  ), // Assuming EditProfilePage is the correct widget
                );
              } else {
                setState(() => selectedIndex = index);
              }
            },
            selectedItemColor: _textColorOnPrimary,
            unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
            backgroundColor: _primaryColor,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: _getTextStyle(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textColorOnPrimary,
            ),
            unselectedLabelStyle: _getTextStyle(
              context,
              fontSize: 11,
              color: _textColorOnPrimary.withOpacity(0.6),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_calendar_outlined),
                activeIcon: Icon(Icons.edit_calendar),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mail_outline),
                activeIcon: Icon(Icons.mail),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuTile(String label, IconData icon, IconData activeIcon) {
    bool isSelected = selectedMenu == label;
    final Color itemColor = isSelected
        ? _primaryColor
        : _textColorPrimary(context);
    final Color itemBgColor = isSelected
        ? _primaryColor.withOpacity(0.1)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: itemColor,
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            color: itemColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: () async {
          Navigator.pop(context);
          if (label == 'Logout') {
            bool signedOut = await signOutFromGoogle();
            if (signedOut && mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginPageMobile(),
                ),
                    (Route<dynamic> route) => false,
              );
            }
          } else if (label == 'Subscription') {
            _showSubscriptionOptions();
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

  void _showSubscriptionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subscription Options', style: _sectionTitleStyle(context)),
              const SizedBox(height: 20),

              // Current subscription status
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(firebaseUser!.uid)
                    .get(),
                builder: (context, snapshot) {
                  bool isSubscribed = false;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    var userData =
                    snapshot.data!.data() as Map<String, dynamic>;
                    isSubscribed = userData["isSubscribed"] ?? false;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSubscribed
                          ? _primaryColor.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSubscribed ? _primaryColor : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSubscribed
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: isSubscribed ? _primaryColor : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSubscribed ? 'Premium Member' : 'Free Member',
                                style: _cardTitleStyle(context).copyWith(
                                  color: isSubscribed
                                      ? _primaryColor
                                      : Colors.orange,
                                ),
                              ),
                              Text(
                                isSubscribed
                                    ? 'You have access to all meal plans'
                                    : 'Upgrade to unlock all meal plans',
                                style: _cardSubtitleStyle(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Browse dietitians button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDietitiansForSubscription();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: _textColorOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.person_search_rounded),
                  label: const Text(
                    'Browse Dietitians',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // My subscriptions button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMySubscriptions();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.subscriptions_outlined),
                  label: const Text(
                    'My Subscriptions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showDietitiansForSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DietitiansListPage()),
    );
  }

  void _showMySubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MySubscriptionsPage(userId: firebaseUser!.uid),
      ),
    );
  }
}

// =======================================================================
// ENHANCED UserSchedulePage to match dietitian's schedule design and functionality
// =======================================================================
class UserSchedulePage extends StatefulWidget {
  final String currentUserId;
  const UserSchedulePage({super.key, required this.currentUserId});

  @override
  State<UserSchedulePage> createState() => _UserSchedulePageState();
}

class _UserSchedulePageState extends State<UserSchedulePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoadingEvents = true;
  String firstName = "";
  String lastName = "";
  bool _isUserNameLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUserName();
    _loadAppointmentsForCalendar();
  }

  void _loadUserName() async {
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

  Future<void> _loadAppointmentsForCalendar() async {
    if (mounted) {
      setState(() => _isLoadingEvents = true);
    }

    try {
      // Try both clientId and clientID field names for compatibility
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('clientID', isEqualTo: widget.currentUserId)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('schedules')
            .where('clientId', isEqualTo: widget.currentUserId)
            .get();
      }

      final Map<DateTime, List<dynamic>> eventsMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Store document ID
        final appointmentDateStr = data['appointmentDate'] as String?;
        if (appointmentDateStr != null) {
          try {
            final appointmentDateTime = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).parse(appointmentDateStr);
            final dateOnly = DateTime.utc(
              appointmentDateTime.year,
              appointmentDateTime.month,
              appointmentDateTime.day,
            );
            if (eventsMap[dateOnly] == null) {
              eventsMap[dateOnly] = [];
            }
            eventsMap[dateOnly]!.add(data);
          } catch (e) {
            print("Error parsing appointment date: $e");
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

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId,
      String newStatus,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(appointmentId)
          .update({'status': newStatus});

      // Refresh the calendar events
      _loadAppointmentsForCalendar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $newStatus'),
            backgroundColor: _primaryColor,
          ),
        );
      }
    } catch (e) {
      print("Error updating appointment status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: _getTextStyle(
                    context,
                    color: _textColorOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: _getTextStyle(
                    context,
                    color: _textColorOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendTextStyle: _getTextStyle(
                    context,
                    color: _primaryColor.withOpacity(0.8),
                  ),
                  defaultTextStyle: _getTextStyle(
                    context,
                    color: _textColorPrimary(context),
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        top: 1,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${events.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  titleTextStyle: _getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(context),
                  ),
                  formatButtonTextStyle: _getTextStyle(
                    context,
                    color: _textColorOnPrimary,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: _textColorPrimary(context),
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: _textColorPrimary(context),
                  ),
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
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),
          ),
          if (_isLoadingEvents)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: _primaryColor),
              ),
            )
          else if (_selectedDay != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Appointments for ${DateFormat.yMMMMd().format(_selectedDay!)}:",
                      style: _getTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColorPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildScheduledAppointmentsList(_selectedDay!),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )
          else if (!_isLoadingEvents)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Select a day to see your appointments.",
                      style: _getTextStyle(
                        context,
                        color: _textColorSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildScheduledAppointmentsList(DateTime selectedDate) {
    final normalizedSelectedDate = DateTime.utc(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
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
                context,
                color: _textColorSecondary(context),
              ),
            ),
          ),
        ),
      );
    }

    dayEvents.sort((a, b) {
      try {
        final dateA = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).parse(a['appointmentDate']);
        final dateB = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).parse(b['appointmentDate']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return Column(
      children: dayEvents.map<Widget>((data) {
        DateTime appointmentDateTime;
        try {
          appointmentDateTime = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).parse(data['appointmentDate']);
        } catch (e) {
          print("Error parsing appointment date: $e");
          return const SizedBox.shrink();
        }
        final formattedTime = DateFormat.jm().format(appointmentDateTime);
        final status = data['status'] ?? 'scheduled';
        final appointmentId = data['id'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: _cardBgColor(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with dietitian name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['dietitianName'] ?? 'Unknown Dietitian',
                        style: _getTextStyle(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColorPrimary(context),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusDisplayText(status),
                        style: _getTextStyle(
                          context,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Time and date info
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: _primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: _getTextStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColorPrimary(context),
                      ),
                    ),
                  ],
                ),
                if (data['notes'] != null &&
                    data['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 16,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['notes'],
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            color: _textColorSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'proposed_by_dietitian':
        return 'Scheduled'; // Changed from 'Pending'
      case 'confirmed':
        return 'Confirmed';
      case 'declined':
        return 'Declined';
      case 'completed':
        return 'Completed';
      default:
        return 'Scheduled';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'proposed_by_dietitian':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return _primaryColor;
    }
  }
}

//user list chat messages
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
      BuildContext context,
      String chatRoomId,
      String otherUserName,
      ) async {
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
    final Color currentScaffoldBg = isDarkMode
        ? Colors.grey.shade900
        : Colors.grey.shade50;
    final Color currentAppBarBg = isDarkMode
        ? Colors.grey.shade800
        : Colors.white;
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
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final unreadCount = snapshot.data!.docs.length;
                          return Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Chats tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No dietitians to chat with yet.",
                      style: _getTextStyle(
                        context,
                        fontSize: 16,
                        color: _textColorPrimary(context),
                      ),
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
                    final chatRoomId = getChatRoomId(currentUserId, userDoc.id);

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
                            backgroundImage:
                            (data["profile"] != null &&
                                data["profile"].toString().isNotEmpty)
                                ? NetworkImage(data["profile"])
                                : null,
                            child:
                            (data["profile"] == null ||
                                data["profile"].toString().isEmpty)
                                ? Icon(
                              Icons.person_outline,
                              color: _primaryColor,
                            )
                                : null,
                          ),
                          title: Text(senderName),
                          subtitle: Text(
                            subtitleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: timeText.isNotEmpty
                              ? Text(
                            timeText,
                            style: const TextStyle(fontSize: 12),
                          )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MessagesPage(
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No notifications"));
                }

                return MediaQuery.removePadding(
                  context: context,
                  removeTop: true, // 🔥 removes the space above
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return ListTile(
                        title: Text(data["title"] ?? "Notification"),
                        subtitle: Text(data["message"] ?? ""),
                        trailing: data["isRead"] == false
                            ? Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                            : null,
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection("Users")
                              .doc(currentUserId)
                              .collection("notifications")
                              .doc(doc.id)
                              .update({"isRead": true});

                          if (data["type"] == "message") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessagesPage(
                                  receiverId: data["senderId"],
                                  receiverName: data["senderName"],
                                  currentUserId: currentUserId,
                                  receiverProfile:
                                  data["receiverProfile"] ?? "",
                                ),
                              ),
                            );
                          } else if (data["type"] == "appointment") {
                            final homeState = context
                                .findAncestorStateOfType<_HomeState>();
                            if (homeState != null) {
                              homeState.setState(() {
                                homeState.selectedIndex =
                                1; // go to My Schedule tab
                              });
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DietitiansListPage extends StatelessWidget {
  const DietitiansListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        title: const Text('Choose Your Dietitian'),
        backgroundColor: _primaryColor,
        foregroundColor: _textColorOnPrimary,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .where("role", isEqualTo: "dietitian")
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
                    Icons.health_and_safety_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No dietitians available',
                    style: _sectionTitleStyle(
                      context,
                    ).copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for available dietitians',
                    style: _cardSubtitleStyle(context),
                  ),
                ],
              ),
            );
          }

          final dietitians = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dietitians.length,
            itemBuilder: (context, index) {
              final dietitianData =
              dietitians[index].data() as Map<String, dynamic>;
              final dietitianId = dietitians[index].id;
              final name =
              "${dietitianData["firstName"] ?? ""} ${dietitianData["lastName"] ?? ""}"
                  .trim();
              final profileUrl = dietitianData["profile"] ?? "";
              final specialization =
                  dietitianData["specialization"] ?? "General Nutrition";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _cardBgColor(context),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubscriptionPage(
                          dietitianId: dietitianId,
                          dietitianName: name.isEmpty ? "Dietitian" : name,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _primaryColor.withOpacity(0.2),
                          backgroundImage: profileUrl.isNotEmpty
                              ? NetworkImage(profileUrl)
                              : null,
                          child: profileUrl.isEmpty
                              ? const Icon(
                            Icons.health_and_safety,
                            size: 30,
                            color: _primaryColor,
                          )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? "Dietitian" : "Dr. $name",
                                style: _cardTitleStyle(
                                  context,
                                ).copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                specialization,
                                style: _cardSubtitleStyle(context),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'View Plans',
                                  style: _cardSubtitleStyle(context).copyWith(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: _textColorSecondary(context),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MySubscriptionsPage extends StatefulWidget {
  final String userId;

  const MySubscriptionsPage({super.key, required this.userId});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<UserSubscription> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final subscriptions = await _subscriptionService.getUserSubscriptions(
        widget.userId,
      );
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: _primaryColor,
        foregroundColor: _textColorOnPrimary,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _subscriptions.isEmpty
          ? _buildEmptyState()
          : _buildSubscriptionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Active Subscriptions',
            style: _sectionTitleStyle(
              context,
            ).copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscribe to a dietitian to get personalized meal plans',
            style: _cardSubtitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DietitiansListPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: _textColorOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('Browse Dietitians'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = _subscriptions[index];
        return _buildSubscriptionCard(subscription);
      },
    );
  }

  Widget _buildSubscriptionCard(UserSubscription subscription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("Users")
                        .doc(subscription.dietitianId)
                        .get(),
                    builder: (context, snapshot) {
                      String dietitianName = "Unknown Dietitian";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data =
                        snapshot.data!.data() as Map<String, dynamic>;
                        dietitianName =
                            "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                                .trim();
                        if (dietitianName.isEmpty) dietitianName = "Dietitian";
                      }
                      return Text(
                        "Dr. $dietitianName",
                        style: _cardTitleStyle(context).copyWith(fontSize: 18),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getSubscriptionStatusColor(
                      subscription.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subscription.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getSubscriptionStatusColor(subscription.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: _textColorSecondary(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Started: ${DateFormat('MMM dd, yyyy').format(subscription.startDate)}',
                  style: _cardSubtitleStyle(context),
                ),
              ],
            ),
            if (subscription.endDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 16,
                    color: _textColorSecondary(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ends: ${DateFormat('MMM dd, yyyy').format(subscription.endDate!)}',
                    style: _cardSubtitleStyle(context),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Navigate to dietitian's meal plans or profile
                  },
                  icon: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('View Meal Plans'),
                  style: TextButton.styleFrom(foregroundColor: _primaryColor),
                ),
                if (subscription.status == 'active')
                  TextButton.icon(
                    onPressed: () => _showCancelDialog(subscription),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubscriptionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'past_due':
        return Colors.orange;
      default:
        return _primaryColor;
    }
  }

  void _showCancelDialog(UserSubscription subscription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardBgColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Subscription',
            style: _sectionTitleStyle(context),
          ),
          content: Text(
            'Are you sure you want to cancel this subscription? You will lose access to premium meal plans.',
            style: _cardBodyTextStyle(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Subscription',
                style: TextStyle(color: _textColorSecondary(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelSubscription(subscription);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel Subscription'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelSubscription(UserSubscription subscription) async {
    try {
      await _subscriptionService.cancelSubscription(subscription.id);
      _loadSubscriptions(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
