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

import 'package:mamas_recipe/about/about_page.dart';

import 'package:mamas_recipe/widget/custom_snackbar.dart';

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

  void _showSubscriptionDialog(String? ownerName, String? ownerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium Content',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscribe to ${ownerName ?? "this creator"} to unlock all meal details and times.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _benefitRow('Full meal plans with times'),
                    _benefitRow('Personalized nutrition guidance'),
                    _benefitRow('Exclusive recipes'),
                    _benefitRow('Direct creator support'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription page
                // You'll need to implement this navigation
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Subscribe Now'),
            ),
          ],
        );
      },
    );
  }




  // --- PASTE THIS FUNCTION INSIDE _HomeState ---
  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: _getTextStyle(context, fontSize: 13), // Ensure context is available
            ),
          ),
        ],
      ),
    );
  }
// --- END OF FUNCTION ---



  // --- PASTE THIS HELPER FUNCTION INSIDE _HomeState ---
  Widget _mealRowWithTime(String label, String? value, String? time,
      {bool isLocked = false}) {
    if ((value == null || value.trim().isEmpty || value.trim() == '-') &&
        (time == null || time.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : _primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: _getTextStyle(context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? Colors.grey.shade600
                                : _primaryColor),
                      ),
                    ),
                    if (time != null && time.isNotEmpty && !isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 10, color: _primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: _getTextStyle(context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (value != null && value.isNotEmpty && value != '-')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isLocked ? '•••••••••' : value,
                      style: _getTextStyle(context,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLocked
                              ? Colors.grey.shade500
                              : _getTextStyle(context, fontSize: 13).color),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- END OF HELPER FUNCTION ---

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


// --- REPLACE _buildRecommendationCard with this ---
  Widget _buildRecommendationCard(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isUserSubscribed, // This might not be fully accurate here, better check dynamically
      ) {
    // We need to fetch the subscription status dynamically for recommendations
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("subscribeTo")
          .doc(ownerId)
          .snapshots(),
      builder: (context, subscribeSnapshot) {
        bool isSubscribed = false; // Default to false
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
          width: 300, // Keep original width for horizontal scroll
          child: Card(
            elevation: 4, // Slightly less elevation than before
            margin: const EdgeInsets.only(right: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
            color: _cardBgColor(context),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // Use SingleChildScrollView in case content overflows vertically
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Takes minimum vertical space
                  children: [
                    // Owner Info Row (same as before)
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
                    const SizedBox(height: 12),
                    // Plan Type
                    Text(
                      data["planType"] ?? "Meal Plan",
                      style: _cardBodyTextStyle(context).copyWith(
                        fontWeight: FontWeight.bold, // Make it bold
                        fontSize: 17,
                      ),
                    ),
                    const Divider(height: 20, thickness: 0.5),

                    // Meal Details using the new style
                    _mealRowWithTime("Breakfast", data["breakfast"], data["breakfastTime"], isLocked: false), // Breakfast always unlocked
                    _mealRowWithTime("AM Snack", data["amSnack"], data["amSnackTime"], isLocked: !isSubscribed),
                    _mealRowWithTime("Lunch", data["lunch"], data["lunchTime"], isLocked: !isSubscribed),
                    _mealRowWithTime("PM Snack", data["pmSnack"], data["pmSnackTime"], isLocked: !isSubscribed),
                    _mealRowWithTime("Dinner", data["dinner"], data["dinnerTime"], isLocked: !isSubscribed),
                    _mealRowWithTime("Midnight Snack", data["midnightSnack"], data["midnightSnackTime"], isLocked: !isSubscribed),

                    // Subscription Unlock Prompt (If needed)
                    if (!isSubscribed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: InkWell(
                          onTap: () {
                            _showSubscriptionDialog(
                                data['ownerName'], // You might need to fetch this again if not available
                                ownerId);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_open, size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  'Subscribe to unlock',
                                  style: _getTextStyle(context, fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    // Like and Download Buttons (same as before)
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
                                      // ... (like logic remains the same)
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
                                        color: Colors.redAccent, size: 18),
                                    label: Text("$likeCount", style: const TextStyle(color: Colors.redAccent, fontFamily: _primaryFontFamily, fontWeight: FontWeight.w600, fontSize: 13)),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              // ... (download logic remains the same)
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

                              if (isSubscribed) {
                                await _downloadMealPlanAsPdf(context, data, ownerName, doc.id);
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  'You must have an approved subscription to download this plan.',
                                  backgroundColor: Colors.redAccent,
                                  icon: Icons.lock,
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            },
                            icon: const Icon(Icons.download_rounded, color: Colors.blueAccent, size: 18),
                            label: const Text("Download", style: TextStyle(color: Colors.blueAccent, fontFamily: _primaryFontFamily, fontWeight: FontWeight.w600, fontSize: 13)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  // --- END OF REPLACEMENT ---

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

// --- REPLACE _buildMealPlanListItem with this ---
  Widget _buildMealPlanListItem(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      ) {
    // Check subscription status dynamically
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('subscribeTo')
          .doc(ownerId)
          .snapshots(),
      builder: (context, subscribeSnapshot) {
        bool isSubscribed = false; // Default to false
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
          elevation: 4, // Use less elevation for list items
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
          color: _cardBgColor(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner Info Row (same structure as recommendations)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("Users")
                      .doc(ownerId)
                      .get(),
                  builder: (context, ownerSnapshot) {
                    String ownerName = "Unknown Chef";
                    String ownerProfileUrl = ""; // Add profile URL fetching

                    if (ownerSnapshot.hasData &&
                        ownerSnapshot.data != null &&
                        ownerSnapshot.data!.exists) {
                      var ownerData =
                      ownerSnapshot.data!.data() as Map<String, dynamic>;
                      ownerName =
                          "${ownerData["firstName"] ?? ""} ${ownerData["lastName"] ?? ""}"
                              .trim();
                      if (ownerName.isEmpty) ownerName = "Unknown Chef";
                      ownerProfileUrl = ownerData["profile"] ?? ""; // Get profile URL
                    }
                    return Row(
                      children: [
                        // Add CircleAvatar for profile picture
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
                                  color: _primaryColor, // Use primary color for name
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (data["timestamp"] != null && data["timestamp"] is Timestamp)
                                Text( // Add timestamp below name
                                  DateFormat('MMM dd, yyyy').format(
                                    (data["timestamp"] as Timestamp).toDate(),
                                  ),
                                  style: _cardSubtitleStyle(context).copyWith(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12), // Add space after owner info
                // Plan Type
                Text(
                  data["planType"] ?? "Meal Plan",
                  style: _cardBodyTextStyle(context).copyWith(
                    fontWeight: FontWeight.bold, // Make it bold
                    fontSize: 17,
                  ),
                ),
                const Divider(height: 20, thickness: 0.5),

                // Meal Details using the new style
                _mealRowWithTime("Breakfast", data["breakfast"], data["breakfastTime"], isLocked: false), // Breakfast always unlocked
                _mealRowWithTime("AM Snack", data["amSnack"], data["amSnackTime"], isLocked: !isSubscribed),
                _mealRowWithTime("Lunch", data["lunch"], data["lunchTime"], isLocked: !isSubscribed),
                _mealRowWithTime("PM Snack", data["pmSnack"], data["pmSnackTime"], isLocked: !isSubscribed),
                _mealRowWithTime("Dinner", data["dinner"], data["dinnerTime"], isLocked: !isSubscribed),
                _mealRowWithTime("Midnight Snack", data["midnightSnack"], data["midnightSnackTime"], isLocked: !isSubscribed),

                // Subscription Unlock Prompt (If needed)
                if (!isSubscribed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTap: () {
                        _showSubscriptionDialog(
                            data['ownerName'], // You might need to fetch this again if not available
                            ownerId);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_open, size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              'Subscribe to unlock',
                              style: _getTextStyle(context, fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                // Like and Download Buttons (same structure as recommendations)
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
                                  // ... (like logic remains the same)
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
                                    color: Colors.redAccent, size: 18),
                                label: Text("$likeCount", style: const TextStyle(color: Colors.redAccent, fontFamily: _primaryFontFamily, fontWeight: FontWeight.w600, fontSize: 13)),
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          // ... (download logic remains the same)
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
                          if (isSubscribed) {
                            await _downloadMealPlanAsPdf(context, data, ownerName, doc.id);
                          } else {
                            CustomSnackBar.show(
                              context,
                              'You must have an approved subscription to download this plan.',
                              backgroundColor: Colors.redAccent,
                              icon: Icons.lock,
                              duration: const Duration(seconds: 3),
                            );
                          }
                        },
                        icon: const Icon(Icons.download_rounded, color: Colors.blueAccent, size: 18),
                        label: const Text("Download", style: TextStyle(color: Colors.blueAccent, fontFamily: _primaryFontFamily, fontWeight: FontWeight.w600, fontSize: 13)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- END OF REPLACEMENT ---


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
        // Success - show custom snackbar
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Meal plan downloaded: $filename',
            backgroundColor: Colors.green,
            icon: Icons.download_done,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        // Cancelled by user
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Download canceled by user',
            backgroundColor: Colors.orange,
            icon: Icons.info,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      // Error occurred
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error generating PDF: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
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
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.black87),
                title: const Text('About', style: TextStyle(fontFamily: _primaryFontFamily)),
                onTap: () {
                  Navigator.pop(context); // Close the drawer first
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),

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



  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: _primaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: _getTextStyle(context,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColorPrimary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _getTextStyle(context,
                  fontSize: 14, color: _textColorSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

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
        CustomSnackBar.show(
          context,
          'Appointment status updated to $newStatus',
          backgroundColor: _primaryColor,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("Error updating appointment status: $e");
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error updating appointment: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(appointmentId)
          .update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      _loadAppointmentsForCalendar();

      if (mounted) {
        CustomSnackBar.show(
        context,
        'Appointment confirmed successfully!',
        backgroundColor: Colors.green,
        icon: Icons.verified,
        duration: const Duration(seconds: 2),
      );
      }
    } catch (e) {
      print("Error confirming appointment: $e");
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error confirming appointment: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _showCancelConfirmationDialog(
      String appointmentId, Map<String, dynamic> appointmentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Cancel Appointment?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No, Keep It'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCancellationReasonDialog(appointmentId, appointmentData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCancellationReasonDialog(
      String appointmentId, Map<String, dynamic> appointmentData) {
    final ValueNotifier<String?> selectedReason = ValueNotifier(null);

    final List<String> cancellationReasons = [
      'Schedule conflict',
      'Feeling unwell',
      'Emergency situation',
      'Need to reschedule',
      'Financial reasons',
      'Found another provider',
      'No longer needed',
      'Personal reasons',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cancellation Reason',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select a reason for cancelling:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String?>(
                  valueListenable: selectedReason,
                  builder: (context, selected, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: cancellationReasons.map((reason) {
                        return RadioListTile<String>(
                          title: Text(
                            reason,
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: reason,
                          groupValue: selected,
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (value) {
                            selectedReason.value = value;
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'A reason is required to cancel.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                selectedReason.dispose();
              },
              child: const Text('Back', style: TextStyle(color: Colors.grey)),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: selectedReason,
              builder: (context, selected, child) {
                return ElevatedButton(
                  onPressed: selected != null
                      ? () async {
                    final reason = selected;

                    // Close the reason dialog
                    Navigator.of(dialogContext).pop();

                    // Dispose the notifier
                    selectedReason.dispose();

                    // Show progress dialog using root context
                    if (!mounted) return;

                    showDialog(
                      context: this.context,
                      barrierDismissible: false,
                      builder: (progressContext) => WillPopScope(
                        onWillPop: () async => false,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 200,
                                minHeight: 100,
                              ),
                              child: Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                          color: Colors.orange),
                                      SizedBox(height: 16),
                                      Text(
                                        'Cancelling appointment...',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    // Perform cancellation
                    await _cancelAppointment(
                        appointmentId, reason, appointmentData);

                    // Close progress dialog
                    if (mounted && Navigator.of(this.context).canPop()) {
                      Navigator.of(this.context).pop();
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    selected != null ? Colors.red : Colors.grey.shade300,
                    foregroundColor:
                    selected != null ? Colors.white : Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Submit'),
                );
              },
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    ).then((_) {
      // Clean up if dialog is dismissed
      if (selectedReason.hasListeners) {
        selectedReason.dispose();
      }
    });
  }

  Future<void> _cancelAppointment(String appointmentId, String reason,
      Map<String, dynamic> appointmentData) async {
    if (reason.trim().isEmpty) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Cancellation reason is required',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
        );
      }
      return;
    }

    try {
      final appointmentRef =
      FirebaseFirestore.instance.collection('schedules').doc(appointmentId);

      final docSnapshot = await appointmentRef.get();

      if (!docSnapshot.exists) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Appointment not found',
            backgroundColor: Colors.redAccent,
            icon: Icons.error,
          );
        }
        return;
      }

      await appointmentRef.update({
        'status': 'cancelled',
        'cancellationReason': reason.trim(),
        'cancelledBy': 'client',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      await _loadAppointmentsForCalendar();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Appointment cancelled successfully',
          backgroundColor: Colors.orange,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint("Error cancelling appointment: $e");
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to cancel appointment. Please try again.',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
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

      CustomSnackBar.show(
        context,
        'Meal plan removed',
        backgroundColor: Colors.orange,
        icon: Icons.delete,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error deleting meal plan: $e');
      CustomSnackBar.show(
        context,
        'Failed to delete meal plan',
        backgroundColor: Colors.redAccent,
        icon: Icons.error,
        duration: const Duration(seconds: 2),
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

      CustomSnackBar.show(
        context,
        'Meal plan scheduled!',
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error saving meal plan: $e');
      CustomSnackBar.show(
        context,
        'Failed to schedule meal plan',
        backgroundColor: Colors.redAccent,
        icon: Icons.error,
        duration: const Duration(seconds: 2),
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
    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

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
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColorOnPrimary,
              ),
              unselectedLabelStyle: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColorOnPrimary.withOpacity(0.7),
              ),
              tabs: const [
                Tab(
                    icon: Icon(Icons.calendar_today, size: 20),
                    text: 'Appointments'),
                Tab(
                    icon: Icon(Icons.restaurant_menu, size: 20),
                    text: 'Meal Plans'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentsTab(),
            // --- START OF REDESIGNED MEAL PLAN TAB ---
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchLikedMealPlansWithOwners(user?.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    "No Liked Plans",
                    "Like a meal plan from the Home feed to see it here.",
                    Icons.favorite_border,
                  );
                }

                final mealPlans = snapshot.data!;

                if (_weeklySchedule.isEmpty && !_isLoadingSchedule) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadScheduledMealPlans();
                  });
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor.withOpacity(0.15),
                              _primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.touch_app,
                                  color: _primaryColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Long press and drag meal plans to schedule your week",
                                style: _getTextStyle(
                                  context,
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.favorite, color: _primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Your Meal Plans",
                            style: _getTextStyle(context,
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: mealPlans.map((plan) {
                          return LongPressDraggable<Map<String, dynamic>>(
                            data: plan,
                            feedback: Material(
                                color: Colors.transparent,
                                child: _planCard(plan, isDragging: true)),
                            childWhenDragging:
                            Opacity(opacity: 0.3, child: _planCard(plan)),
                            child: _planCard(plan),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Icon(Icons.calendar_month,
                              color: _primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Weekly Schedule",
                            style: _getTextStyle(context,
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingSchedule)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child:
                            CircularProgressIndicator(color: _primaryColor),
                          ),
                        )
                      else
                        SizedBox(
                          height: 320,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: orderedDays.length,
                            itemBuilder: (context, index) {
                              final dayInfo = orderedDays[index];
                              final day = dayInfo['label'] as String;
                              final date = dayInfo['date'] as DateTime;
                              final formattedDate =
                                  "${_monthAbbrev(date.month)} ${date.day}";
                              final plan = _weeklySchedule[day];
                              final isToday = date.day == now.day &&
                                  date.month == now.month &&
                                  date.year == now.year;

                              return DragTarget<Map<String, dynamic>>(
                                onAccept: (receivedPlan) {
                                  _saveMealPlanToSchedule(day, date, receivedPlan);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final isHovering = candidateData.isNotEmpty;
                                  return Container(
                                    width: 270,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(14.0),
                                    decoration: BoxDecoration(
                                      color: isHovering
                                          ? _primaryColor.withOpacity(0.1)
                                          : _cardBgColor(context),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isToday
                                            ? _primaryColor
                                            : isHovering
                                            ? _primaryColor.withOpacity(0.5)
                                            : Colors.transparent,
                                        width: isToday ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      day,
                                                      style: _getTextStyle(context,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          fontSize: 16),
                                                    ),
                                                    if (isToday) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: _primaryColor,
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                        ),
                                                        child: Text(
                                                          'TODAY',
                                                          style: _getTextStyle(
                                                            context,
                                                            fontSize: 10,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                Text(
                                                  formattedDate,
                                                  style: _getTextStyle(context,
                                                      color: _textColorSecondary(
                                                          context),
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            if (plan != null)
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                const BoxConstraints(),
                                                icon: const Icon(Icons.close,
                                                    color: Colors.redAccent,
                                                    size: 20),
                                                onPressed: () {
                                                  _deleteMealPlanFromSchedule(
                                                      day, date);
                                                },
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (plan == null)
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _primaryColor
                                                    .withOpacity(0.05),
                                                borderRadius:
                                                BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _primaryColor
                                                      .withOpacity(0.2),
                                                  width: 2,
                                                  style: BorderStyle.solid,
                                                ),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_circle_outline,
                                                      color: _primaryColor
                                                          .withOpacity(0.4),
                                                      size: 32,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      "Drop plan here",
                                                      style: _getTextStyle(context,
                                                          fontSize: 13,
                                                          fontWeight:
                                                          FontWeight.w500,
                                                          color:
                                                          _textColorSecondary(
                                                              context)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        _primaryColor,
                                                        _primaryColor
                                                            .withOpacity(0.7),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                    BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .restaurant_menu_rounded,
                                                          color: Colors.white,
                                                          size: 16),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          plan['planType'] ??
                                                              'Meal Plan',
                                                          style: _getTextStyle(
                                                            context,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            fontSize: 13,
                                                            color: Colors.white,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(
                                                  child: FutureBuilder<bool>(
                                                    future: _isUserSubscribedToOwner(
                                                        user?.uid,
                                                        plan['owner']),
                                                    builder: (context, snapshot) {
                                                      final isSubscribed =
                                                          snapshot.data ?? false;
                                                      return SingleChildScrollView(
                                                        physics:
                                                        const BouncingScrollPhysics(),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                          children: [
                                                            _mealRowWithTime(
                                                              "Breakfast",
                                                              plan['breakfast'],
                                                              plan[
                                                              'breakfastTime'],
                                                              isLocked: false,
                                                            ),
                                                            _mealRowWithTime(
                                                              "AM Snack",
                                                              plan['amSnack'],
                                                              plan['amSnackTime'],
                                                              isLocked:
                                                              !isSubscribed,
                                                            ),
                                                            _mealRowWithTime(
                                                              "Lunch",
                                                              plan['lunch'],
                                                              plan['lunchTime'],
                                                              isLocked:
                                                              !isSubscribed,
                                                            ),
                                                            _mealRowWithTime(
                                                              "PM Snack",
                                                              plan['pmSnack'],
                                                              plan['pmSnackTime'],
                                                              isLocked:
                                                              !isSubscribed,
                                                            ),
                                                            _mealRowWithTime(
                                                              "Dinner",
                                                              plan['dinner'],
                                                              plan['dinnerTime'],
                                                              isLocked:
                                                              !isSubscribed,
                                                            ),
                                                            _mealRowWithTime(
                                                              "Midnight Snack",
                                                              plan[
                                                              'midnightSnack'],
                                                              plan[
                                                              'midnightSnackTime'],
                                                              isLocked:
                                                              !isSubscribed,
                                                            ),
                                                            if (!isSubscribed)
                                                              Padding(
                                                                padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8.0),
                                                                child: InkWell(
                                                                  onTap: () {
                                                                    _showSubscriptionDialog(
                                                                        plan[
                                                                        'ownerName'],
                                                                        plan[
                                                                        'owner']);
                                                                  },
                                                                  child: Container(
                                                                    padding:
                                                                    const EdgeInsets
                                                                        .all(8),
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      color: Colors
                                                                          .orange
                                                                          .withOpacity(
                                                                          0.1),
                                                                      borderRadius:
                                                                      BorderRadius.circular(
                                                                          8),
                                                                      border: Border
                                                                          .all(
                                                                        color: Colors
                                                                            .orange
                                                                            .withOpacity(
                                                                            0.3),
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                      children: [
                                                                        const Icon(
                                                                          Icons
                                                                              .lock_open,
                                                                          size: 14,
                                                                          color: Colors
                                                                              .orange,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                            6),
                                                                        Text(
                                                                          'Subscribe to unlock',
                                                                          style: _getTextStyle(
                                                                              context,
                                                                              fontSize:
                                                                              11,
                                                                              fontWeight:
                                                                              FontWeight.w600,
                                                                              color: Colors.orange),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
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
            // --- END OF REDESIGNED MEAL PLAN TAB ---
          ],
        ),
      ),
    );
  }

  Widget _planCard(Map<String, dynamic> plan, {bool isDragging = false}) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.1),
            _primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDragging)
            BoxShadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant_menu_rounded,
                color: _primaryColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            plan['planType'] ?? 'Meal Plan',
            style: _getTextStyle(context,
                fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: _textColorSecondary(context)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  plan['ownerName'] ?? 'Unknown Owner',
                  style: _getTextStyle(context,
                      fontSize: 12, color: _textColorSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealRowWithTime(String label, String? value, String? time,
      {bool isLocked = false}) {
    if ((value == null || value.trim().isEmpty || value.trim() == '-') &&
        (time == null || time.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : _primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: _getTextStyle(context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? Colors.grey.shade600
                                : _primaryColor),
                      ),
                    ),
                    if (time != null && time.isNotEmpty && !isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 10, color: _primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: _getTextStyle(context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (value != null && value.isNotEmpty && value != '-')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isLocked ? '•••••••••' : value,
                      style: _getTextStyle(context,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLocked
                              ? Colors.grey.shade500
                              : _getTextStyle(context, fontSize: 13).color),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Add this method to check subscription status
  Future<bool> _isUserSubscribedToOwner(String? userId, String? ownerId) async {
    if (userId == null || ownerId == null || userId == ownerId) {
      return true; // User is the owner or not logged in
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc('${userId}_$ownerId')
          .get();

      return doc.exists && (doc.data()?['status'] == 'active');
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }

// Add this method to show subscription dialog
  void _showSubscriptionDialog(String? ownerName, String? ownerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium Content',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscribe to ${ownerName ?? "this creator"} to unlock all meal details and times.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _benefitRow('Full meal plans with times'),
                    _benefitRow('Personalized nutrition guidance'),
                    _benefitRow('Exclusive recipes'),
                    _benefitRow('Direct creator support'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription page
                // You'll need to implement this navigation
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Subscribe Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: _getTextStyle(context, fontSize: 13),
            ),
          ),
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
        final appointmentId = data['id'];

        // Use the helpers already in home.dart
        final statusColor = _getStatusColor(status);

        // --- START: NEW LAYOUT (from homePageDietitian.dart) ---
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardBgColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dietitian Name Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_rounded, // Dietitian Icon
                        color: _primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data['dietitianName'] ?? 'Unknown Dietitian', // Client-side logic
                        style: _getTextStyle(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time and Status Layout
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time section
                    Row(
                      mainAxisSize: MainAxisSize.min, // Takes only needed space
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedTime,
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColorPrimary(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8.0), // Vertical space

                    // Status section
                    Row(
                      mainAxisSize: MainAxisSize.min, // Takes only needed space
                      children: [
                        Icon(
                          Icons.bookmark_outline_rounded,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusDisplayText(status), // Client-side logic
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Notes Row
                if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: _textColorSecondary(context).withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['notes'],
                          style: _getTextStyle(
                            context,
                            fontSize: 13,
                            color: _textColorSecondary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // --- CLIENT-SPECIFIC ACTIONS (from home.dart) ---
                if (status == 'Waiting for client response.') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmAppointment(appointmentId),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCancelConfirmationDialog(appointmentId, data),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        // --- END: NEW LAYOUT ---
      }).toList(),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'proposed_by_dietitian': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'declined': return 'Declined';
      case 'cancelled': return 'Cancelled';
      case 'completed': return 'Completed';
      default: return 'Scheduled';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'declined': return Colors.red;
      case 'cancelled': return Colors.orange;
      case 'proposed_by_dietitian': return Colors.blue;
      case 'completed': return Colors.grey;
      default: return _primaryColor;
    }
  }
}

// REPLACE the entire UsersListPage class in your home.dart with this code

// REPLACE the entire UsersListPage class in your home.dart with this code

class UsersListPage extends StatefulWidget {
  final String currentUserId;
  const UsersListPage({super.key, required this.currentUserId});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  // --- STATE VARIABLES ---
  List<Map<String, dynamic>> _sortedChats = [];
  bool _isLoadingChats = true;
  String _selectedNotificationFilter = 'all'; // 'all', 'appointment', 'message', 'pricing'

  @override
  void initState() {
    super.initState();
    _loadAndSortChats();
  }
  Widget _buildCompactFilterChip(String filter) {
    final isSelected = _selectedNotificationFilter == filter;
    final chipColor = _getFilterChipColor(filter);
    final chipIcon = _getFilterChipIcon(filter);
    final chipLabel = _getFilterChipLabel(filter);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? chipColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? chipColor : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedNotificationFilter = filter;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              size: 14,
              color: isSelected ? chipColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              chipLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? chipColor : Colors.grey.shade600,
                fontFamily: _primaryFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- HELPER FUNCTIONS (moved to class level) ---

  /// Show confirmation dialog with premium design
  Future<void> _showClearAllDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardBgColor(dialogContext),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Clear Notifications?',
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary(dialogContext),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to clear all notifications?)',
                  textAlign: TextAlign.center,
                  style: _getTextStyle(
                    dialogContext,
                    fontSize: 14,
                    color: _textColorSecondary(dialogContext),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: _primaryColor, width: 1.5),
                      foregroundColor: _primaryColor,
                    ),
                    child: Text(
                      'Cancel',
                      style: _getTextStyle(
                        dialogContext,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                    label: Text(
                      'Yes, Clear All',
                      style: _getTextStyle(
                        dialogContext,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      _clearAllNotifications();
    }
  }

  /// Clear all notifications function
  Future<void> _clearAllNotifications() async {
    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.currentUserId)
          .collection("notifications")
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notificationsSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'All notifications cleared from view.',
          backgroundColor: _primaryColor,
          icon: Icons.done_all,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error clearing notifications: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error,
        );
      }
    }
  }

  /// Get notification type for filtering
  String _getNotificationType(Map<String, dynamic> data) {
    final type = (data["type"] ?? '').toString().toLowerCase();
    if (type.contains('message')) return 'message';
    if (type.contains('appointment') || type.contains('appointment_update')) return 'appointment';
    if (type.contains('pricing') || type.contains('subscription')) return 'pricing';
    return 'other';
  }

  /// Get color for filter chip
  Color _getFilterChipColor(String filter) {
    switch (filter) {
      case 'appointment':
        return const Color(0xFFFF9800);
      case 'message':
        return const Color(0xFF2196F3);
      case 'pricing':
        return const Color(0xFF9C27B0);
      default:
        return _primaryColor;
    }
  }

  /// Get icon for filter chip
  IconData _getFilterChipIcon(String filter) {
    switch (filter) {
      case 'appointment':
        return Icons.event_available_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'pricing':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Get label for filter chip
  String _getFilterChipLabel(String filter) {
    switch (filter) {
      case 'appointment':
        return 'Appointments';
      case 'message':
        return 'Messages';
      case 'pricing':
        return 'Pricing';
      default:
        return 'All';
    }
  }

  /// Filter notifications based on selected filter
  bool _shouldShowNotification(Map<String, dynamic> data) {
    if (_selectedNotificationFilter == 'all') return true;
    final notificationType = _getNotificationType(data);
    return notificationType == _selectedNotificationFilter;
  }

  /// Build filter chip widget
  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedNotificationFilter == filter;
    final chipColor = _getFilterChipColor(filter);
    final chipIcon = _getFilterChipIcon(filter);
    final chipLabel = _getFilterChipLabel(filter);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedNotificationFilter = filter;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: chipColor.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            size: 16,
            color: isSelected ? chipColor : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            chipLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? chipColor : Colors.grey.shade600,
              fontFamily: _primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  String getChatRoomId(String userA, String userB) {
    if (userA.compareTo(userB) > 0) {
      return "$userB\_$userA";
    } else {
      return "$userA\_$userB";
    }
  }

  Future<List<String>> getFollowedDietitianIds() async {
    try {
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.currentUserId)
          .collection('following')
          .get();
      return followingSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching followed dietitians: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getLastMessage(
      BuildContext context,
      String chatRoomId,
      ) async {
    final query = await FirebaseFirestore.instance
        .collection("messages")
        .where("chatRoomID", isEqualTo: chatRoomId)
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return {"message": "", "isMe": false, "time": "", "timestampObject": null};
    }

    final data = query.docs.first.data();
    String formattedTime = "";
    final timestamp = data["timestamp"];
    DateTime? messageDate;

    if (timestamp is Timestamp) {
      messageDate = timestamp.toDate();
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
      "timestampObject": messageDate,
    };
  }

  Future<void> _loadAndSortChats() async {
    if (!mounted) return;
    setState(() => _isLoadingChats = true);

    try {
      final followedDietitianIds = await getFollowedDietitianIds();
      final usersSnapshot = await FirebaseFirestore.instance.collection("Users").get();
      final users = usersSnapshot.docs;

      final filteredUsers = users.where((userDoc) {
        if (userDoc.id == widget.currentUserId) return false;
        final data = userDoc.data();
        final role = data["role"]?.toString().toLowerCase() ?? "";
        if (role == "admin") return true;
        if (role == "dietitian" && followedDietitianIds.contains(userDoc.id)) {
          return true;
        }
        return false;
      }).toList();

      if (filteredUsers.isEmpty) {
        if (mounted) setState(() => _isLoadingChats = false);
        return;
      }

      List<Future<Map<String, dynamic>>> chatFutures = [];
      for (var userDoc in filteredUsers) {
        chatFutures.add(_fetchChatDetails(userDoc));
      }

      final resolvedChats = await Future.wait(chatFutures);

      resolvedChats.sort((a, b) {
        final timeA = a['lastMessage']['timestampObject'] as DateTime?;
        final timeB = b['lastMessage']['timestampObject'] as DateTime?;

        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;

        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _sortedChats = resolvedChats;
          _isLoadingChats = false;
        });
      }
    } catch (e) {
      print("Error loading and sorting chats: $e");
      if (mounted) setState(() => _isLoadingChats = false);
    }
  }

  Future<Map<String, dynamic>> _fetchChatDetails(DocumentSnapshot userDoc) async {
    final data = userDoc.data() as Map<String, dynamic>;
    final senderName = "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
    final chatRoomId = getChatRoomId(widget.currentUserId, userDoc.id);

    final lastMessageData = await getLastMessage(context, chatRoomId);

    return {
      'userDoc': userDoc,
      'lastMessage': lastMessageData,
    };
  }

  void _showPriceChangeDialog(BuildContext context, Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String title = notificationData['title'] ?? 'Price Change Notification';
        final String message = notificationData['message'] ?? 'No details available';
        final String dietitianName = notificationData['dietitianName'] ?? 'Dietitian';
        final Timestamp? timestamp = notificationData['timestamp'] as Timestamp?;

        final monthlyOld = notificationData['monthlyOldPrice']?.toString() ?? 'N/A';
        final monthlyNew = notificationData['monthlyNewPrice']?.toString() ?? 'N/A';
        final weeklyOld = notificationData['weeklyOldPrice']?.toString() ?? 'N/A';
        final weeklyNew = notificationData['weeklyNewPrice']?.toString() ?? 'N/A';
        final yearlyOld = notificationData['yearlyOldPrice']?.toString() ?? 'N/A';
        final yearlyNew = notificationData['yearlyNewPrice']?.toString() ?? 'N/A';

        String formattedDate = '';
        if (timestamp != null) {
          formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.price_change_outlined,
                          color: Colors.orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (formattedDate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontFamily: _primaryFontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18, color: _primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              dietitianName,
                              style: const TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontFamily: _primaryFontFamily,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPriceComparison('Monthly', monthlyOld, monthlyNew),
                      const SizedBox(height: 12),
                      _buildPriceComparison('Weekly', weeklyOld, weeklyNew),
                      const SizedBox(height: 12),
                      _buildPriceComparison('Yearly', yearlyOld, yearlyNew),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceComparison(String label, String oldPrice, String newPrice) {
    final bool priceChanged = oldPrice != newPrice;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontFamily: _primaryFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₱$oldPrice',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: priceChanged ? Colors.grey.shade500 : Colors.grey.shade700,
                        decoration: priceChanged ? TextDecoration.lineThrough : null,
                        fontFamily: _primaryFontFamily,
                      ),
                    ),
                    if (priceChanged) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade400),
                      ),
                      Text(
                        '₱$newPrice',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontFamily: _primaryFontFamily,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToAppointment(BuildContext context, Map<String, dynamic> notificationData) async {
    print('=== APPOINTMENT NOTIFICATION DATA ===');
    notificationData.forEach((key, value) {
      print('$key: $value');
    });
    print('======================================');

    final String message = notificationData['message'] ?? '';
    DateTime? targetDate;

    try {
      final datePattern = RegExp(r'on\s+([A-Za-z]+\s+\d+,\s+\d{4})\s+at\s+(\d+:\d+\s+[AP]M)');
      final match = datePattern.firstMatch(message);

      if (match != null) {
        final dateStr = match.group(1);
        final timeStr = match.group(2);
        final fullDateStr = '$dateStr $timeStr';

        print('Extracted date string: $fullDateStr');
        targetDate = DateFormat('MMMM d, yyyy h:mm a').parse(fullDateStr);
        print('Parsed date: $targetDate');
      }
    } catch (e) {
      print('Error parsing date from message: $e');
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => home(initialIndex: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (targetDate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Showing appointments for ${DateFormat('MMM dd, yyyy').format(targetDate)}',
              style: const TextStyle(fontFamily: _primaryFontFamily),
            ),
            backgroundColor: _primaryColor,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Navigated to your appointments schedule',
              style: TextStyle(fontFamily: _primaryFontFamily),
            ),
            backgroundColor: _primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
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
                  clipBehavior: Clip.none,
                  children: [
                    const Text("NOTIFICATIONS"),
                    Positioned(
                      top: 8,
                      right: -20,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(widget.currentUserId)
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
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadCount',
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- CHATS TAB ---
            _isLoadingChats
                ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                : _sortedChats.isEmpty
                ? Center(
              child: Text(
                "Follow dietitians to chat with them.",
                style: _getTextStyle(
                  context,
                  fontSize: 16,
                  color: _textColorPrimary(context),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              itemCount: _sortedChats.length,
              itemBuilder: (context, index) {
                final chat = _sortedChats[index];
                final userDoc = chat['userDoc'] as DocumentSnapshot;
                final data = userDoc.data() as Map<String, dynamic>;
                final lastMsg = chat['lastMessage'] as Map<String, dynamic>;

                final senderName =
                "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                    .trim();

                String subtitleText = "No messages yet";
                final lastMessage = lastMsg["message"] ?? "";
                final lastSenderName = lastMsg["senderName"] ?? "";
                final timeText = lastMsg["time"] ?? "";

                if (lastMessage.isNotEmpty) {
                  if (lastMsg["isMe"] ?? false) {
                    subtitleText = "You: $lastMessage";
                  } else {
                    subtitleText = "$lastSenderName: $lastMessage";
                  }
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagesPage(
                              currentUserId: widget.currentUserId,
                              receiverId: userDoc.id,
                              receiverName: senderName,
                              receiverProfile: data["profile"] ?? "",
                            ),
                          ),
                        ).then((_) {
                          _loadAndSortChats();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _cardBgColor(context),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _primaryColor.withOpacity(0.2),
                                  backgroundImage: (data["profile"] != null &&
                                      data["profile"].toString().isNotEmpty)
                                      ? NetworkImage(data["profile"])
                                      : null,
                                  child: (data["profile"] == null ||
                                      data["profile"].toString().isEmpty)
                                      ? Icon(Icons.person_outline,
                                      color: _primaryColor, size: 24)
                                      : null,
                                ),
                                if (data['status'] == 'online')
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName,
                                    style: _getTextStyle(context,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _getTextStyle(context,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: _textColorSecondary(context)),
                                  ),
                                ],
                              ),
                            ),
                            if (timeText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  timeText,
                                  style: _getTextStyle(context,
                                      fontSize: 12,
                                      color: _textColorSecondary(context)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // --- NOTIFICATIONS TAB ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(widget.currentUserId)
                  .collection("notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: _primaryColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text("No notifications yet",
                            style: _getTextStyle(context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textColorPrimary(context))),
                      ],
                    ),
                  );
                }

                // Group notifications (latest only per group)
                final Map<String, DocumentSnapshot> groupedNotifications = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String groupingKey;

                  if (data['type'] == 'message' && data['senderId'] != null) {
                    groupingKey = data['senderId'];
                  } else {
                    groupingKey = doc.id;
                  }

                  if (!groupedNotifications.containsKey(groupingKey)) {
                    groupedNotifications[groupingKey] = doc;
                  }
                }

                final finalDocsToShow = groupedNotifications.values.toList();

                // Filter by selected filter
                final filteredDocs = finalDocsToShow
                    .where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _shouldShowNotification(data);
                })
                    .toList();

                return Column(
                  children: [
                    // --- COMPACT HEADER WITH FILTER CHIPS AND CLEAR BUTTON ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Filter chips in a horizontal scrollable row
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCompactFilterChip('all'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('appointment'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('message'),
                                  const SizedBox(width: 6),
                                  _buildCompactFilterChip('pricing'),
                                ],
                              ),
                            ),
                          ),
                          // Clear All button as icon button
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showClearAllDialog,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.redAccent.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- NOTIFICATIONS LIST ---
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: _primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No notifications",
                              style: _getTextStyle(
                                context,
                                fontSize: 16,
                                color: _textColorSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: filteredDocs.length,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final Timestamp? timestamp =
                          data["timestamp"] as Timestamp?;
                          String formattedTime = "";

                          if (timestamp != null) {
                            final date = timestamp.toDate();
                            final now = DateTime.now();
                            if (date.year == now.year &&
                                date.month == now.month &&
                                date.day == now.day) {
                              formattedTime = DateFormat.jm().format(date);
                            } else if (date.year == now.year &&
                                date.month == now.month &&
                                date.day == now.day - 1) {
                              formattedTime = "Yesterday";
                            } else {
                              formattedTime = DateFormat('MMM d').format(date);
                            }
                          }

                          bool isRead = data["isRead"] == true;
                          final notificationType = _getNotificationType(data);
                          final iconBgColor = _getFilterChipColor(notificationType);
                          final notificationIcon = _getFilterChipIcon(notificationType);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: isRead
                                  ? null
                                  : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  iconBgColor.withOpacity(0.08),
                                  iconBgColor.withOpacity(0.03),
                                ],
                              ),
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: isRead ? 0.5 : 2,
                              color: _cardBgColor(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: isRead
                                    ? BorderSide(color: Colors.grey.shade300, width: 0.5)
                                    : BorderSide(
                                  color: iconBgColor.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  if (!isRead) {
                                    await FirebaseFirestore.instance
                                        .collection("Users")
                                        .doc(widget.currentUserId)
                                        .collection("notifications")
                                        .doc(doc.id)
                                        .update({"isRead": true});
                                  }

                                  if (data["type"] == "priceChange") {
                                    _showPriceChangeDialog(context, data);
                                  } else if (data["type"] == "message" &&
                                      data["senderId"] != null &&
                                      data["senderName"] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MessagesPage(
                                          receiverId: data["senderId"],
                                          receiverName: data["senderName"],
                                          currentUserId: widget.currentUserId,
                                          receiverProfile:
                                          data["receiverProfile"] ?? "",
                                        ),
                                      ),
                                    ).then((_) {
                                      _loadAndSortChats();
                                    });
                                  } else if (data["type"] == "appointment" ||
                                      data["type"] == "appointment_update") {
                                    await _navigateToAppointment(context, data);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                          iconBgColor.withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                            color: iconBgColor
                                                .withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          notificationIcon,
                                          color: iconBgColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    data["title"] ??
                                                        "Notification",
                                                    style: _getTextStyle(
                                                      context,
                                                      fontSize: 15,
                                                      fontWeight: isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                      color:
                                                      _textColorPrimary(
                                                          context),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                    const EdgeInsets.only(
                                                        left: 8.0),
                                                    decoration: BoxDecoration(
                                                      color: iconBgColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              data["message"] ?? "",
                                              style: _getTextStyle(
                                                context,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                _textColorSecondary(context),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (formattedTime.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                formattedTime,
                                                style: _getTextStyle(
                                                  context,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isRead
                                                      ? _textColorSecondary(
                                                      context)
                                                      : iconBgColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}

