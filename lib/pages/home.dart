import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'messages.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'UserProfile.dart';
import 'package:shimmer/shimmer.dart';
import 'subscription_model.dart';
import 'subscription_service.dart';
import 'subscription_widget.dart';
import '../Dietitians/dietitianPublicProfile.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

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

  String _searchQuery = "";
  String _searchFilter = "All";
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? userData;
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
              profileUrl = data['profile'] as String? ?? '';
              _isUserNameLoading = false;
            });
          } else {
            setState(() {
              firstName = "";
              lastName = "";
              profileUrl = "";
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
            profileUrl = "";
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

  Widget _buildSearchBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBgColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: _getTextStyle(context, fontSize: 15),
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: _getTextStyle(
                  context,
                  fontSize: 14,
                  color: _textColorSecondary(context),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _primaryColor,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: _textColorSecondary(context),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        _buildFilterChips(),
      ],
    );
  }

  String _getSearchHint() {
    switch (_searchFilter) {
      case "Health Goals":
        return "Search by health goals (e.g., Weight Loss, Muscle Gain)...";
      case "Dietitians":
        return "Search dietitians by name or specialization...";
      case "Meal Plans":
        return "Search meal plans by name or type...";
      default:
        return "Search by health goals, dietitians, meal plans...";
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {"label": "All", "icon": Icons.apps},
      {"label": "Health Goals", "icon": Icons.favorite},
      {"label": "Dietitians", "icon": Icons.person},
      {"label": "Meal Plans", "icon": Icons.restaurant_menu},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _searchFilter == filter["label"];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter["icon"] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : _primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter["label"] as String,
                    style: _getTextStyle(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _primaryColor,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _searchFilter = filter["label"] as String;
                });
              },
              backgroundColor: _cardBgColor(context),
              selectedColor: _primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
            ),
          );
        },
      ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget recommendationsWidget() {
    if (_searchFilter != "All" && _searchFilter != "Health Goals") {
      return const SizedBox.shrink();
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    // Weight configuration for scoring formula
    const double w1 = 1.0;  // weight for likes
    const double w2 = 1.5;  // weight for calendar adds (can adjust importance)
    const double alpha = 1.0; // time decay factor

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Recommendations ✨",
            style: _sectionTitleStyle(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                isSubscribed = userData["isSubscribed"] ?? false;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("mealPlans")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildRecommendationsLoadingShimmer();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "There's no meal plan recommendation.",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  // Filter valid meal plans
                  var docs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>?;

                    if (data == null) return false;
                    if ((data["owner"] ?? "").toString().trim().isEmpty) return false;

                    bool allMealsEmpty = [
                      data["breakfast"],
                      data["amSnack"],
                      data["lunch"],
                      data["pmSnack"],
                      data["dinner"],
                      data["midnightSnack"],
                    ].every((meal) =>
                    meal == null ||
                        meal.toString().trim().isEmpty ||
                        meal.toString().toLowerCase() == "null");

                    if (allMealsEmpty) return false;

                    return (data["planType"] ?? "").toString().trim().isNotEmpty;
                  }).toList();

                  // Apply search filtering
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String planName =
                      (data["planName"] ?? "").toString().toLowerCase();
                      String planType =
                      (data["planType"] ?? "").toString().toLowerCase();
                      String description =
                      (data["description"] ?? "").toString().toLowerCase();

                      if (_searchFilter == "Health Goals") {
                        return planType.contains(_searchQuery);
                      }
                      return planName.contains(_searchQuery) ||
                          planType.contains(_searchQuery) ||
                          description.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "There's no meal plan recommendation.",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  // Compute scores based on collaborative filtering formula
                  List<Map<String, dynamic>> scoredPlans = docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    int likes = data["likeCounts"] ?? 0;
                    int calendarAdds = data["calendarAdds"] ?? 0;

                    DateTime publishedDate;
                    if (data["timestamp"] is Timestamp) {
                      publishedDate = (data["timestamp"] as Timestamp).toDate();
                    } else if (data["timestamp"] is String) {
                      publishedDate = DateTime.tryParse(data["timestamp"]) ?? DateTime.now();
                    } else {
                      publishedDate = DateTime.now();
                    }

                    int daysSincePublished =
                        DateTime.now().difference(publishedDate).inDays;
                    if (daysSincePublished <= 0) daysSincePublished = 1;

                    // Apply formula
                    double finalScore =
                        ((w1 * likes) + (w2 * calendarAdds)) /
                            (alpha * daysSincePublished);

                    return {"doc": doc, "data": data, "score": finalScore};
                  }).toList();

                  if (scoredPlans.isEmpty) {
                    return const Center(
                      child: Text(
                        "There's no meal plan recommendation.",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  // Sort by highest score and limit to 5
                  scoredPlans.sort((a, b) =>
                      (b["score"] as double).compareTo(a["score"] as double));
                  if (scoredPlans.length > 5) {
                    scoredPlans = scoredPlans.sublist(0, 5);
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


  Widget _buildRecommendationCard(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isUserSubscribed,
      ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("subscribeTo")
          .doc(ownerId)
          .snapshots(),
      builder: (context, subscribeSnapshot) {
        bool isSubscribed = false;

        if (subscribeSnapshot.hasData &&
            subscribeSnapshot.data != null &&
            subscribeSnapshot.data!.exists) {
          final subData =
          subscribeSnapshot.data!.data() as Map<String, dynamic>;
          if (subData["status"] == "approved") {
            isSubscribed = true;
          }
        }

        return SizedBox(
          width: 300,
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.only(right: 12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: _cardBgColor(context),
            child: InkWell(
              onTap: () {
                debugPrint("Tapped on recommendation: ${data['planType']}");
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot?>(
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
                            var ownerData = ownerSnapshot.data!.data()
                            as Map<String, dynamic>;
                            ownerName =
                                "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                                    .trim();
                            if (ownerName.isEmpty) ownerName = "Unknown Chef";
                            ownerProfileUrl = ownerData["profile"] ?? "";
                          }

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: _primaryColor.withOpacity(0.2),
                                backgroundImage: (ownerProfileUrl.isNotEmpty)
                                    ? NetworkImage(ownerProfileUrl)
                                    : null,
                                child: (ownerProfileUrl.isEmpty)
                                    ? const Icon(Icons.person,
                                    size: 24, color: _primaryColor)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ownerName,
                                      style: _cardTitleStyle(context).copyWith(
                                        color: _primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (data["timestamp"] != null &&
                                        data["timestamp"] is Timestamp)
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(
                                          (data["timestamp"] as Timestamp)
                                              .toDate(),
                                        ),
                                        style: _cardSubtitleStyle(context)
                                            .copyWith(fontSize: 12),
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
                        style: _cardBodyTextStyle(context).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      if (data["timestamp"] != null &&
                          data["timestamp"] is Timestamp)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            DateFormat('MMM dd, yyyy – hh:mm a').format(
                              (data["timestamp"] as Timestamp).toDate(),
                            ),
                            style: _cardSubtitleStyle(context),
                          ),
                        ),
                      const Divider(height: 20),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.5), // Meal type
                          1: FlexColumnWidth(2.5), // Food
                          2: FlexColumnWidth(1.2), // Time
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: Colors.grey.shade300),
                        ),
                        children: [
                          _buildMealRow3("Breakfast", data["breakfast"], data["breakfastTime"], true),
                          _buildMealRow3("AM Snack", data["amSnack"], data["amSnackTime"], isSubscribed),
                          _buildMealRow3("Lunch", data["lunch"], data["lunchTime"], isSubscribed),
                          _buildMealRow3("PM Snack", data["pmSnack"], data["pmSnackTime"], isSubscribed),
                          _buildMealRow3("Dinner", data["dinner"], data["dinnerTime"], isSubscribed),
                          _buildMealRow3("Midnight Snack", data["midnightSnack"], data["midnightSnackTime"], isSubscribed),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("likes")
                                  .doc("${currentUserId}_${doc.id}")
                                  .snapshots(), // ✅ stream the correct like doc
                              builder: (context, likeSnapshot) {
                                bool isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;

                                // ✅ listen to meal plan doc for likeCount updates
                                return StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection("mealPlans")
                                      .doc(doc.id)
                                      .snapshots(),
                                  builder: (context, mealSnapshot) {
                                    if (!mealSnapshot.hasData) return const SizedBox();

                                    final mealData = mealSnapshot.data!.data() as Map<String, dynamic>;
                                    int likeCount = mealData["likeCounts"] ?? 0;

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
                                        padding:
                                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final firestore = FirebaseFirestore.instance;

                                final subscribeToRef = firestore
                                    .collection("Users")
                                    .doc(currentUserId)
                                    .collection("subscribeTo")
                                    .doc(ownerId); // client → dietitian

                                final subscriberRef = firestore
                                    .collection("Users")
                                    .doc(ownerId) // dietitian → client
                                    .collection("subscriber")
                                    .doc(currentUserId);

                                try {
                                  final results = await Future.wait([
                                    subscribeToRef.get(),
                                    subscriberRef.get(),
                                  ]);

                                  bool isSubscribed = false;

                                  // Check if either document exists AND has status "approved"
                                  if (results[0].exists) {
                                    final data = results[0].data() as Map<String, dynamic>;
                                    if (data["status"] == "approved") isSubscribed = true;
                                  }

                                  if (results[1].exists) {
                                    final data = results[1].data() as Map<String, dynamic>;
                                    if (data["status"] == "approved") isSubscribed = true;
                                  }

                                  if (isSubscribed) {
                                    final ownerSnapshot = await FirebaseFirestore.instance
                                        .collection("Users")
                                        .doc(ownerId)
                                        .get();

                                    String ownerName = "Unknown Chef";
                                    if (ownerSnapshot.exists) {
                                      var ownerData = ownerSnapshot.data() as Map<String, dynamic>;
                                      ownerName = "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}".trim();
                                      if (ownerName.isEmpty) ownerName = "Unknown Chef";
                                    }

                                    // Call the download function
                                    await _downloadMealPlanAsPdf(context, data, ownerName, doc.id);
                                    // ✅ User has approved subscription
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Meal plan downloaded for offline use."),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );

                                    // TODO: Add your actual download logic here
                                  } else {
                                    // ❌ Subscription not approved or missing
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("You must have an approved subscription to this dietitian to download this meal plan."),
                                        backgroundColor: Colors.redAccent,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error checking subscription: $e"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.download_rounded,
                                color: Colors.blueAccent,
                                size: 18,
                              ),
                              label: const Text(
                                "Download",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontFamily: _primaryFontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget dietitiansList() {
    if (_searchFilter != "All" && _searchFilter != "Dietitians") {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Connect with Dietitians 🧑‍⚕️",
            style: _sectionTitleStyle(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 140,
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

              if (_searchQuery.isNotEmpty) {
                dietitians = dietitians.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                      .toLowerCase();
                  String specialization =
                  (data["specialization"] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      specialization.contains(_searchQuery);
                }).toList();
              }

              if (dietitians.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? "No dietitians found for '$_searchQuery'"
                        : "No dietitians found.",
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
                    child: GestureDetector(
                      onTap: () {
                        // Get the dietitian ID
                        String dietitianId = dietitians[index].id;
                        String name = "${dietitianData["firstName"] ?? ""} ${dietitianData["lastName"] ?? ""}".trim();
                        if (name.isEmpty) name = "Dietitian";
                        String profileUrl = dietitianData["profile"] ?? "";

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DietitianPublicProfile(
                              dietitianId: dietitianId,
                              dietitianName: name,
                              dietitianProfile: profileUrl,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: _primaryColor.withOpacity(0.2),
                              backgroundImage: (profileUrl.isNotEmpty)
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: (profileUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                  size: 32, color: _primaryColor)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 90,
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: _cardBodyTextStyle(context).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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

  Widget mealPlansTable(String userGoal) {
    if (_searchFilter == "Dietitians") {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("Users")
            .doc(firebaseUser!.uid)
            .get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String userGoal = userData["goals"] ?? "";
          bool isSubscribed = userData["isSubscribed"] ?? false;

          if (userGoal.isEmpty && _searchFilter != "Meal Plans") {
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
                  _searchQuery.isNotEmpty
                      ? "Search Results for '$_searchQuery'"
                      : _searchFilter == "Meal Plans"
                      ? "All Meal Plans"
                      : "Meal Plans for: $userGoal",
                  style: _sectionTitleStyle(context),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _searchFilter == "Meal Plans" || _searchQuery.isNotEmpty
                    ? FirebaseFirestore.instance
                    .collection("mealPlans")
                    .snapshots()
                    : FirebaseFirestore.instance
                    .collection("mealPlans")
                    .where("planType", isEqualTo: userGoal)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  var plans = snapshot.data!.docs;

                  // Filter out empty/invalid documents first
                  plans = plans.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    // Check if document has required fields
                    final ownerId = data["ownerId"] ?? data["owner"] ?? "";
                    if (ownerId.isEmpty) return false;

                    // Check if at least one meal field has data
                    final hasMealData = [
                      data["breakfast"],
                      data["amSnack"],
                      data["lunch"],
                      data["pmSnack"],
                      data["dinner"],
                      data["midnightSnack"],
                    ].any((meal) => meal != null && meal.toString().trim().isNotEmpty);

                    return hasMealData;
                  }).toList();

                  // Enhanced search logic for Meal Plans filter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();

                    plans = plans.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;

                      // Search in all meal fields
                      final mealFields = [
                        data["breakfast"]?.toString().toLowerCase() ?? "",
                        data["amSnack"]?.toString().toLowerCase() ?? "",
                        data["lunch"]?.toString().toLowerCase() ?? "",
                        data["pmSnack"]?.toString().toLowerCase() ?? "",
                        data["dinner"]?.toString().toLowerCase() ?? "",
                        data["midnightSnack"]?.toString().toLowerCase() ?? "",
                        data["planName"]?.toString().toLowerCase() ?? "",
                        data["planType"]?.toString().toLowerCase() ?? "",
                        data["description"]?.toString().toLowerCase() ?? "",
                      ];

                      // Check if any field contains the search query
                      return mealFields.any((field) => field.contains(query));
                    }).toList();
                  }

                  if (plans.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? "No meal plans found containing '$_searchQuery'"
                            : "No meal plans available.",
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
                        firebaseUser!.uid,
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
      ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('subscribeTo')
          .doc(ownerId)
          .snapshots(),
      builder: (context, subscribeSnapshot) {
        bool isSubscribed = false;

        if (subscribeSnapshot.hasData &&
            subscribeSnapshot.data != null &&
            subscribeSnapshot.data!.exists) {
          final subData =
          subscribeSnapshot.data!.data() as Map<String, dynamic>;
          if (subData['status'] == 'approved') {
            isSubscribed = true;
          }
        }

        return Card(
          elevation: 8,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: _cardBgColor(context),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("Users")
                        .doc(ownerId)
                        .get(),
                    builder: (context, ownerSnapshot) {
                      String ownerName = "Unknown Chef";
                      if (ownerSnapshot.hasData &&
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
                        style: _cardTitleStyle(context).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data["planType"] ?? "Meal Plan",
                    style: _cardBodyTextStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  if (data["timestamp"] != null && data["timestamp"] is Timestamp)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('MMM dd, yyyy – hh:mm a')
                            .format((data["timestamp"] as Timestamp).toDate()),
                        style: _cardSubtitleStyle(context),
                      ),
                    ),
                  const Divider(height: 20),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2), // Meal type
                      1: FlexColumnWidth(2.5), // Food
                      2: FlexColumnWidth(1.2), // Time
                    },
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: Colors.grey.shade300),
                    ),
                    children: [
                      _buildMealRow3("Breakfast", data["breakfast"], data["breakfastTime"], true),
                      _buildMealRow3("AM Snack", data["amSnack"], data["amSnackTime"], isSubscribed),
                      _buildMealRow3("Lunch", data["lunch"], data["lunchTime"], isSubscribed),
                      _buildMealRow3("PM Snack", data["pmSnack"], data["pmSnackTime"], isSubscribed),
                      _buildMealRow3("Dinner", data["dinner"], data["dinnerTime"], isSubscribed),
                      _buildMealRow3("Midnight Snack", data["midnightSnack"], data["midnightSnackTime"], isSubscribed),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("likes")
                              .doc("${currentUserId}_${doc.id}")
                              .snapshots(),
                          builder: (context, likeSnapshot) {
                            bool isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final firestore = FirebaseFirestore.instance;

                            final subscribeToRef = firestore
                                .collection("Users")
                                .doc(currentUserId)
                                .collection("subscribeTo")
                                .doc(ownerId); // client → dietitian

                            final subscriberRef = firestore
                                .collection("Users")
                                .doc(ownerId) // dietitian → client
                                .collection("subscriber")
                                .doc(currentUserId);

                            try {
                              final results = await Future.wait([
                                subscribeToRef.get(),
                                subscriberRef.get(),
                              ]);

                              bool isSubscribed = false;

                              // Check if either document exists AND has status "approved"
                              if (results[0].exists) {
                                final data = results[0].data() as Map<String, dynamic>;
                                if (data["status"] == "approved") isSubscribed = true;
                              }

                              if (results[1].exists) {
                                final data = results[1].data() as Map<String, dynamic>;
                                if (data["status"] == "approved") isSubscribed = true;
                              }

                              if (isSubscribed) {

                                final ownerSnapshot = await FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(ownerId)
                                    .get();

                                String ownerName = "Unknown Chef";
                                if (ownerSnapshot.exists) {
                                  var ownerData = ownerSnapshot.data() as Map<String, dynamic>;
                                  ownerName = "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}".trim();
                                  if (ownerName.isEmpty) ownerName = "Unknown Chef";
                                }

                                // Call the download function
                                await _downloadMealPlanAsPdf(context, data, ownerName, doc.id);
                                // ✅ User has approved subscription
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Meal plan downloaded for offline use."),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                // TODO: Add your actual download logic here
                              } else {
                                // ❌ Subscription not approved or missing
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("You must have an approved subscription to this dietitian to download this meal plan."),
                                    backgroundColor: Colors.redAccent,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error checking subscription: $e"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.download_rounded,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          label: const Text(
                            "Download",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontFamily: _primaryFontFamily,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> _downloadMealPlanAsPdf(
      BuildContext context,
      Map<String, dynamic> mealPlanData,
      String ownerName,
      String docId,
      ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Meal Plan',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Chef: $ownerName',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Plan Type: ${mealPlanData["planType"] ?? "Meal Plan"}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                if (mealPlanData["timestamp"] != null)
                  pw.Text(
                    'Created: ${DateFormat('MMM dd, yyyy – hh:mm a').format((mealPlanData["timestamp"] as Timestamp).toDate())}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Meal Type', 'Food', 'Time'],
                  data: [
                    ['Breakfast', mealPlanData["breakfast"] ?? '', mealPlanData["breakfastTime"] ?? ''],
                    ['AM Snack', mealPlanData["amSnack"] ?? '', mealPlanData["amSnackTime"] ?? ''],
                    ['Lunch', mealPlanData["lunch"] ?? '', mealPlanData["lunchTime"] ?? ''],
                    ['PM Snack', mealPlanData["pmSnack"] ?? '', mealPlanData["pmSnackTime"] ?? ''],
                    ['Dinner', mealPlanData["dinner"] ?? '', mealPlanData["dinnerTime"] ?? ''],
                    ['Midnight Snack', mealPlanData["midnightSnack"] ?? '', mealPlanData["midnightSnackTime"] ?? ''],
                  ],
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellHeight: 30,
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final now = DateTime.now();
      final filename = 'MealPlan_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.pdf';

      final params = SaveFileDialogParams(
        data: bytes,
        fileName: filename,
      );

      final savedFilePath = await FlutterFileDialog.saveFile(params: params);

      if (savedFilePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal plan downloaded: $filename'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download canceled by user'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  TableRow _buildMealRow3(
      String label,
      dynamic value,
      dynamic time,
      bool isSubscribed,
      ) {
    final textStyle = TextStyle(
      fontSize: 14,
      fontFamily: _primaryFontFamily,
      color: Colors.black87,
    );

    final greyStyle = textStyle.copyWith(color: Colors.grey.shade600);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: greyStyle.copyWith(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            isSubscribed ? (value ?? "—") : "Locked 🔒",
            style: textStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            time ?? "—",
            style: greyStyle,
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
    _searchController.dispose();
    _setUserStatus("offline");
    super.dispose();
  }

  List<Widget> get _pages => [
    SingleChildScrollView(
      key: const PageStorageKey('homePageScroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          dietitiansList(),
          const SizedBox(height: 10),
          recommendationsWidget(),
          const SizedBox(height: 10),
          mealPlansTable(""),
          const SizedBox(height: 20),
        ],
      ),
    ),
    firebaseUser != null
        ? UserSchedulePage(currentUserId: firebaseUser!.uid)
        : const Center(
      child: Text(
        "Please log in to view your schedule.",
        style: TextStyle(fontFamily: _primaryFontFamily),
      ),
    ),
    firebaseUser != null
        ? UsersListPage(currentUserId: firebaseUser!.uid)
        : const Center(
      child: Text(
        "Please log in to view messages.",
        style: TextStyle(fontFamily: _primaryFontFamily),
      ),
    ),
    firebaseUser != null
        ? const UserProfile()
        : const Center(
      child: Text(
        "Please log in to view your profile.",
        style: TextStyle(fontFamily: _primaryFontFamily),
      ),
    ),
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
              buildMenuTile('Subscription', Icons.subscriptions_outlined,
                  Icons.subscriptions),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfile(),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuTile(String label, IconData icon, IconData activeIcon) {
    bool isSelected = selectedMenu == label;
    final Color itemColor =
    isSelected ? _primaryColor : _textColorPrimary(context);
    final Color itemBgColor =
    isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent;

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
            showSubscriptionOptions(context, firebaseUser!.uid);
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

  Map<String, Map<String, dynamic>?> _weeklySchedule = {};
  bool _isLoadingSchedule = false;

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
        data['id'] = doc.id;
        final appointmentDateStr = data['appointmentDate'] as String?;
        if (appointmentDateStr != null) {
          try {
            final appointmentDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(appointmentDateStr);
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

  Future<void> _updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(appointmentId)
          .update({'status': newStatus});

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

  Future<List<Map<String, dynamic>>> _fetchLikedMealPlansWithOwners(String? userId) async {
    if (userId == null) return [];

    final firestore = FirebaseFirestore.instance;
    final likesSnapshot = await firestore
        .collection('likes')
        .where('userID', isEqualTo: userId)
        .get();

    if (likesSnapshot.docs.isEmpty) return [];

    final mealPlanIDs = likesSnapshot.docs.map((doc) => doc['mealPlanID'] as String).toList();
    final List<Map<String, dynamic>> mealPlans = [];

    for (String id in mealPlanIDs) {
      final mealPlanDoc = await firestore.collection('mealPlans').doc(id).get();
      if (mealPlanDoc.exists) {
        final planData = mealPlanDoc.data()!;
        planData['planId'] = id;
        String ownerId = planData['owner'] ?? '';
        String ownerName = 'Unknown';

        if (ownerId.isNotEmpty) {
          final userDoc = await firestore.collection('Users').doc(ownerId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            if (userData['role'] == 'dietitian') {
              ownerName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
              if (ownerName.isEmpty) {
                ownerName = userData['name'] ?? userData['fullName'] ?? userData['displayName'] ?? ownerId;
              }
            }
          }
        }

        planData['ownerName'] = ownerName;
        mealPlans.add(planData);
      }
    }

    return mealPlans;
  }

  Future<void> _loadScheduledMealPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingSchedule = true;
    });

    try {
      final now = DateTime.now();
      final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

      Map<String, Map<String, dynamic>?> loadedSchedule = {
        for (var day in daysOfWeek) day: null,
      };

      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayName = daysOfWeek[date.weekday - 1];

        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('scheduledMealPlans')
            .doc(dateStr)
            .get();

        if (doc.exists) {
          loadedSchedule[dayName] = doc.data();
        }
      }

      setState(() {
        _weeklySchedule = loadedSchedule;
        _isLoadingSchedule = false;
      });
    } catch (e) {
      print('Error loading scheduled meal plans: $e');
      setState(() {
        _isLoadingSchedule = false;
      });
    }
  }

  Future<void> _deleteMealPlanFromSchedule(String day, DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('scheduledMealPlans')
          .doc(dateStr)
          .delete();

      setState(() {
        _weeklySchedule[day] = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan removed')),
      );
    } catch (e) {
      print('Error deleting meal plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete meal plan')),
      );
    }
  }

  Future<void> _saveMealPlanToSchedule(String day, DateTime date, Map<String, dynamic> plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('scheduledMealPlans')
          .doc(dateStr)
          .set({
        'date': Timestamp.fromDate(date),
        'dayOfWeek': day,
        'planType': plan['planType'],
        'planId': plan['planId'],
        'ownerName': plan['ownerName'],
        'breakfast': plan['breakfast'],
        'amSnack': plan['amSnack'],
        'lunch': plan['lunch'],
        'pmSnack': plan['pmSnack'],
        'dinner': plan['dinner'],
        'midnightSnack': plan['midnightSnack'],
        'scheduledAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _weeklySchedule[day] = plan;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan scheduled!')),
      );
    } catch (e) {
      print('Error saving meal plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule meal plan')),
      );
    }
  }

  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                selectedDecoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                selectedTextStyle: _getTextStyle(context, color: _textColorOnPrimary, fontWeight: FontWeight.bold),
                todayDecoration: BoxDecoration(color: _primaryColor.withOpacity(0.5), shape: BoxShape.circle),
                todayTextStyle: _getTextStyle(context, color: _textColorOnPrimary, fontWeight: FontWeight.bold),
                weekendTextStyle: _getTextStyle(context, color: _primaryColor.withOpacity(0.8)),
                defaultTextStyle: _getTextStyle(context, color: _textColorPrimary(context)),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text('${events.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                  return null;
                },
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
            child: Center(child: CircularProgressIndicator(color: _primaryColor)),
          )
        else if (_selectedDay != null)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Appointments for ${DateFormat.yMMMMd().format(_selectedDay!)}:",
                    style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold, color: _textColorPrimary(context)),
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
                    style: _getTextStyle(context, color: _textColorSecondary(context)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final orderedDays = List.generate(7, (i) {
      final date = now.add(Duration(days: i));
      final weekdayName = daysOfWeek[date.weekday - 1];
      return {'label': weekdayName, 'date': date};
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _scaffoldBgColor(context),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: _primaryColor,
            foregroundColor: _textColorOnPrimary,
            elevation: 0,
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(icon: Icon(Icons.calendar_today, size: 20), text: 'Appointments'),
                Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'Meal Plans'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentsTab(),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchLikedMealPlansWithOwners(user?.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("You haven't liked any meal plans yet.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  );
                }

                final mealPlans = snapshot.data!;

                if (_weeklySchedule.isEmpty && !_isLoadingSchedule) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadScheduledMealPlans();
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("Drag and drop meal plans to schedule your week", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Your Meal Plans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: mealPlans.map((plan) {
                          return LongPressDraggable<Map<String, dynamic>>(
                            data: plan,
                            feedback: Material(color: Colors.transparent, child: _planCard(plan, isDragging: true)),
                            childWhenDragging: Opacity(opacity: 0.5, child: _planCard(plan)),
                            child: _planCard(plan),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      const Text("Weekly Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      if (_isLoadingSchedule)
                        const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
                      else
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: orderedDays.length,
                            itemBuilder: (context, index) {
                              final dayInfo = orderedDays[index];
                              final day = dayInfo['label'] as String;
                              final date = dayInfo['date'] as DateTime;
                              final formattedDate = "${_monthAbbrev(date.month)} ${date.day}";
                              final plan = _weeklySchedule[day];

                              return DragTarget<Map<String, dynamic>>(
                                onAccept: (receivedPlan) {
                                  _saveMealPlanToSchedule(day, date, receivedPlan);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    width: 250,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                            const SizedBox(height: 10),
                                            if (plan == null)
                                              const Expanded(
                                                child: Center(child: Text("Drop plan here", style: TextStyle(fontSize: 13, color: Colors.grey))),
                                              )
                                            else
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(plan['planType'] ?? 'Meal Plan', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                          IconButton(
                                                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                                            onPressed: () {
                                                              _deleteMealPlanFromSchedule(day, date);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                      _mealRow("Breakfast", plan['breakfast']),
                                                      _mealRow("AM Snack", plan['amSnack']),
                                                      _mealRow("Lunch", plan['lunch']),
                                                      _mealRow("PM Snack", plan['pmSnack']),
                                                      _mealRow("Dinner", plan['dinner']),
                                                      _mealRow("Midnight Snack", plan['midnightSnack']),
                                                    ],
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
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(Map<String, dynamic> plan, {bool isDragging = false}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [if (!isDragging) BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.green),
          const SizedBox(height: 8),
          Text(plan['planType'] ?? 'Meal Plan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(plan['ownerName'] ?? 'Unknown Owner', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _mealRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text("$label:")),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _monthAbbrev(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildScheduledAppointmentsList(DateTime selectedDate) {
    final normalizedSelectedDate = DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEvents = _events[normalizedSelectedDate] ?? [];

    if (dayEvents.isEmpty) {
      return Card(
        color: _cardBgColor(context),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text("No appointments scheduled for this day yet.", style: _getTextStyle(context, color: _textColorSecondary(context))),
          ),
        ),
      );
    }

    dayEvents.sort((a, b) {
      try {
        final dateA = DateFormat('yyyy-MM-dd HH:mm').parse(a['appointmentDate']);
        final dateB = DateFormat('yyyy-MM-dd HH:mm').parse(b['appointmentDate']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return Column(
      children: dayEvents.map<Widget>((data) {
        DateTime appointmentDateTime;
        try {
          appointmentDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(data['appointmentDate']);
        } catch (e) {
          print("Error parsing appointment date: $e");
          return const SizedBox.shrink();
        }
        final formattedTime = DateFormat.jm().format(appointmentDateTime);
        final status = data['status'] ?? 'scheduled';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: _cardBgColor(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['dietitianName'] ?? 'Unknown Dietitian',
                        style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold, color: _textColorPrimary(context)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: _getStatusColor(status), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _getStatusDisplayText(status),
                        style: _getTextStyle(context, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: _primaryColor),
                    const SizedBox(width: 8),
                    Text(formattedTime, style: _getTextStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: _textColorPrimary(context))),
                  ],
                ),
                if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_alt_outlined, size: 16, color: _primaryColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(data['notes'], style: _getTextStyle(context, fontSize: 14, color: _textColorSecondary(context)))),
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
      case 'proposed_by_dietitian': return 'Scheduled';
      case 'confirmed': return 'Confirmed';
      case 'declined': return 'Declined';
      case 'completed': return 'Completed';
      default: return 'Scheduled';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'declined': return Colors.red;
      case 'proposed_by_dietitian': return Colors.orange;
      case 'completed': return Colors.blue;
      default: return _primaryColor;
    }
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
    final Color currentScaffoldBg = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final Color currentAppBarBg = isDarkMode ? Colors.grey.shade800 : Colors.white;
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
                            backgroundImage: (data["profile"] != null &&
                                data["profile"].toString().isNotEmpty)
                                ? NetworkImage(data["profile"])
                                : null,
                            child: (data["profile"] == null ||
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

                return MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
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

