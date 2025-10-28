import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/home.dart';
import 'package:intl/intl.dart';
import '../plan/choosePlan.dart';

import 'package:mamas_recipe/widget/custom_snackbar.dart';

// --- Theme Helpers (Copied from other files) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;


Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white;

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

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle,
      double? height,
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
    height: height,
  );
}

// --- Background Shapes Widget ---
Widget _buildBackgroundShapes(BuildContext context) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: _scaffoldBgColor(context),
    child: Stack(
      children: [
        Positioned(
          top: -100,
          left: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          right: -180,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

class DietitianPublicProfile extends StatefulWidget {
  final String dietitianId;
  final String dietitianName;
  final String dietitianProfile;

  const DietitianPublicProfile({
    super.key,
    required this.dietitianId,
    required this.dietitianName,
    required this.dietitianProfile,
  });



  State<DietitianPublicProfile> createState() => _DietitianPublicProfileState();
}

class _DietitianPublicProfileState extends State<DietitianPublicProfile> {

  Map<String, bool> _expandedStates = {};
  Map<String, GlobalKey> _cardKeys = {}; // Add this
  late ScrollController _scrollController; // Add this line

  bool _isFollowing = false;
  int _followerCount = 0;
  int _uploadCount = 0;
  String _bio = "";
  bool _isLoadingBio = true;
  String _subscriptionStatus = '';
  bool _isLoadingSubscription = true;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkIfFollowing();
    _getFollowerCount();
    _getUploadCount();
    _getDietitianBio();
    _checkSubscriptionStatus();
    _expandedStates = {};
    _cardKeys = {};
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

// REPLACE your old _buildMealItemExpanded with this one
  Widget _buildMealItemExpanded(
      BuildContext context,
      String mealName,
      String? mealContent,
      String? mealTime,
      IconData icon,
      Color iconColor, {
        bool isLocked = false,
      }) {
    // Skip if meal content is empty
    if (mealContent == null || mealContent.isEmpty || mealContent == '-') {
      return const SizedBox.shrink();
    }

    // Use the locked content if isLocked is true
    final String displayContent =
    isLocked ? "Subscribe to see meal content" : mealContent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.1)
            : iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : iconColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and meal name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.withOpacity(0.2)
                      : iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: isLocked ? Colors.grey.shade600 : iconColor,
                    size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLocked ? Colors.grey.shade600 : iconColor,
                      ),
                    ),
                    if ((mealTime ?? '').isNotEmpty && !isLocked) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: iconColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mealTime ?? '',
                            style: _getTextStyle(
                              context,
                              fontSize: 11,
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Meal content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              displayContent, // Use the displayContent
              style: _getTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLocked
                    ? Colors.grey.shade500
                    : _textColorPrimary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// ADD THIS NEW HELPER METHOD
  Future<void> _navigateToChoosePlan() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.dietitianId)
          .get();
      if (!doc.exists) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Dietitian not found',
            backgroundColor: Colors.orange,
            icon: Icons.person_off_outlined,
          );
        }
        return;
      }

      final data = doc.data()!;
      final dietitianEmail = data['email'] ?? 'No email';
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChoosePlanPage(
              dietitianName: widget.dietitianName,
              dietitianEmail: dietitianEmail,
              dietitianProfile: widget.dietitianProfile,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to choose plan: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }


 // NEW: Check subscription status
  Future<void> _checkSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _subscriptionStatus = '';
          _isLoadingSubscription = false;
        });
      }
      return;
    }

    try {
      final subDoc = await _firestore
          .collection('Users')
          .doc(widget.dietitianId)
          .collection('subscriber')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _subscriptionStatus = subDoc.exists ? (subDoc.data()?['status'] ?? '') : '';
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      if (mounted) {
        setState(() {
          _subscriptionStatus = '';
          _isLoadingSubscription = false;
        });
      }
    }
  }

  // NEW: Helper method to check if content should be locked
  bool _isContentLocked() {
    // Content is locked if:
    // 1. Not subscribed at all (_subscriptionStatus is empty)
    // 2. Subscribed but status is 'cancelled' or 'expired'
    // Content is unlocked only when status is 'approved'
    return _subscriptionStatus.isEmpty ||
        _subscriptionStatus == 'cancelled' ||
        _subscriptionStatus == 'expired';
  }

  Future<void> _checkIfFollowing() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('Users').doc(user.uid).collection('following').doc(widget.dietitianId).get();
      if (mounted) setState(() => _isFollowing = doc.exists);
    } catch (e) { debugPrint('Error checking following status: $e'); }
  }

  Future<void> _getFollowerCount() async {
    try {
      _firestore.collection('Users').doc(widget.dietitianId).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final newCount = doc.data()?['followerCount'] ?? 0;
          // Only update if the value actually changed
          if (newCount != _followerCount) {
            setState(() => _followerCount = newCount);
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching follower count: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final user = _auth.currentUser;
    if (user == null) {
      CustomSnackBar.show(
        context,
        'Please log in to follow dietitians',
        backgroundColor: Colors.redAccent,
        icon: Icons.lock_outline,
      );
      return;
    }
    if (user.uid == widget.dietitianId) {
      CustomSnackBar.show(
        context,
        'You cannot follow yourself',
        backgroundColor: Colors.orange,
        icon: Icons.block_outlined,
      );
      return;
    }

    final previousFollowingState = _isFollowing;
    final previousFollowerCount = _followerCount;

    if (mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount += _isFollowing ? 1 : -1;
      });
    }

    try {
      final userRef = _firestore.collection('Users').doc(user.uid);
      final dietitianRef = _firestore.collection('Users').doc(widget.dietitianId);
      final followingRef = userRef.collection('following').doc(widget.dietitianId);
      final followerRef = dietitianRef.collection('followers').doc(user.uid);
      final batch = _firestore.batch();

      if (!_isFollowing) {
        batch.delete(followingRef);
        batch.delete(followerRef);
        batch.update(userRef, {'followingCount': FieldValue.increment(-1),});
        batch.update(dietitianRef, {'followerCount': FieldValue.increment(-1),});
      } else {
        batch.set(followingRef, {
          'dietitianId': widget.dietitianId,
          'dietitianName': widget.dietitianName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.set(followerRef, {
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.update(userRef, {'followingCount': FieldValue.increment(1),});
        batch.update(dietitianRef, {'followerCount': FieldValue.increment(1),});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      CustomSnackBar.show(
        context,
        'Error: $e',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      if (mounted) {
        setState(() {
          _isFollowing = previousFollowingState;
          _followerCount = previousFollowerCount;
        });
      }
    }
  }

// Same for upload count
  Future<void> _getUploadCount() async {
    try {
      _firestore.collection('mealPlans').where('owner', isEqualTo: widget.dietitianId).snapshots().listen((snapshot) {
        if (mounted) {
          final newCount = snapshot.docs.length;
          // Only update if the value actually changed
          if (newCount != _uploadCount) {
            setState(() => _uploadCount = newCount);
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching upload count: $e');
    }
  }

  Future<void> _getDietitianBio() async {
    if (mounted) setState(() => _isLoadingBio = true);
    try {
      final doc = await _firestore.collection('Users').doc(widget.dietitianId).get();
      if (doc.exists && mounted) {
        setState(() {
          _bio = doc.data()?['bio'] ?? 'No bio available';
          _isLoadingBio = false;
        });
      } else if (mounted) {
        setState(() {
          _bio = 'No bio available';
          _isLoadingBio = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bio: $e');
      if (mounted) {
        setState(() {
          _bio = 'Error loading bio';
          _isLoadingBio = false;
        });
      }
    }
  }


// REPLACE your _buildMealPlanListItem with THIS StatefulBuilder version
// REPLACE your _buildMealPlanListItem with THIS map-based version AGAIN
  Widget _buildMealPlanListItem(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isLocked,
      ) {
    // Data extraction
    final String planType = data["planType"] ?? "Meal Plan";
    final String description = data['description']?.toString() ?? '';
    final timestamp = data["timestamp"] as Timestamp?;
    final int likeCounts = data['likeCounts'] as int? ?? 0;

    // Use doc.id as the unique key for this meal plan's state
    final String cardKey = doc.id;

    if (!_cardKeys.containsKey(cardKey)) {
      _cardKeys[cardKey] = GlobalKey();
    }

    // Initialize the expanded state for this card if it doesn't exist yet
    // IMPORTANT: DO NOT CALL setState here. We just ensure the key exists.
    if (!_expandedStates.containsKey(cardKey)) {
      _expandedStates[cardKey] = false;
    }
    // Get the current expanded state for THIS card from the main state map
    final bool isExpanded = _expandedStates[cardKey]!;
    final bool lockAllMeals = isLocked;

    return Card(
      key: _cardKeys[cardKey],
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Column( // Main Column for Header + AnimatedCrossFade
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER SECTION - Always visible, clickable to expand
          InkWell( // InkWell to handle tap for expansion
            onTap: () {
              // Use the main setState ONLY here in onTap
              setState(() { // <<<--- Calls the main setState
                _expandedStates[cardKey] = !_expandedStates[cardKey]!; // Toggle state for this specific card
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final RenderObject? renderObject = _cardKeys[cardKey]?.currentContext?.findRenderObject();
                if (renderObject != null) {
                  _scrollController.position.ensureVisible(
                    renderObject,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Padding( // Header Content Padding
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner Info Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _primaryColor.withOpacity(0.2),
                        backgroundImage: (widget.dietitianProfile.isNotEmpty)
                            ? NetworkImage(widget.dietitianProfile)
                            : null,
                        child: (widget.dietitianProfile.isEmpty)
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
                              widget.dietitianName, // Use widget data
                              style: _getTextStyle(context,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _primaryColor)
                                  .copyWith(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (timestamp != null)
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(timestamp.toDate()),
                                style: _getTextStyle(context,
                                    fontSize: 12,
                                    color: _textColorSecondary(context))
                                    .copyWith(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      // Like Count (Moved to header)
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            likeCounts.toString(),
                            style: _getTextStyle(
                              context,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8), // Spacer
                      // Animated expand/collapse indicator (uses the state variable)
                      AnimatedRotation( // Shows expand state visually
                        turns: isExpanded ? 0.5 : 0, // <<<--- Uses isExpanded from map
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more,
                          color: _primaryColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Plan Type
                  Text(
                    planType,
                    style: _getTextStyle(context,
                        fontWeight: FontWeight.bold, fontSize: 17)
                        .copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- DESCRIPTION (Always Visible) ---
                  if (description.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  style: _getTextStyle(
                                    context,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _textColorPrimary(context),
                                  ),
                                  maxLines: isExpanded
                                      ? 100 // Show full text when expanded
                                      : 2, // Limit lines when collapsed
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Only show "View full" if not expanded OR if text might overflow
                                if (!isExpanded || description.length > 80) // Adjust length check as needed
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: GestureDetector(
                                      onTap: () => _showFullDescription( // Calls the dialog
                                        context,
                                        description,
                                        planType,
                                      ),
                                      child: Text(
                                        isExpanded ? "View in dialog" : "View full description",
                                        style: _getTextStyle(
                                          context,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryColor,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // --- END DESCRIPTION ---

                  const SizedBox(height: 12),

                  // "Tap to view" hint only when collapsed
                  if (!isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Tap to view full meal plan",
                        style: _getTextStyle(
                          context,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // EXPANDED CONTENT - Shows all meals and actions
          AnimatedCrossFade( // Handles the expand/collapse animation
            firstChild: const SizedBox.shrink(), // Empty when collapsed
            secondChild: Padding( // Content shown when expanded
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20, thickness: 0.5),

                  // Pass the isLocked flag to the meal items
                  _buildMealItemExpanded(
                    context,
                    "Breakfast",
                    data["breakfast"],
                    data["breakfastTime"],
                    Icons.wb_sunny_outlined,
                    Colors.orange,
                    isLocked: lockAllMeals, // Use the correct lock logic
                  ),
                  _buildMealItemExpanded(
                    context,
                    "AM Snack",
                    data["amSnack"],
                    data["amSnackTime"],
                    Icons.coffee_outlined,
                    Colors.brown,
                    isLocked: lockAllMeals,
                  ),
                  _buildMealItemExpanded(
                    context,
                    "Lunch",
                    data["lunch"],
                    data["lunchTime"],
                    Icons.restaurant_outlined,
                    Colors.green,
                    isLocked: lockAllMeals,
                  ),
                  _buildMealItemExpanded(
                    context,
                    "PM Snack",
                    data["pmSnack"],
                    data["pmSnackTime"],
                    Icons.local_cafe_outlined,
                    Colors.purple,
                    isLocked: lockAllMeals,
                  ),
                  _buildMealItemExpanded(
                    context,
                    "Dinner",
                    data["dinner"],
                    data["dinnerTime"],
                    Icons.nightlight_outlined,
                    Colors.indigo,
                    isLocked: lockAllMeals,
                  ),
                  _buildMealItemExpanded(
                    context,
                    "Midnight Snack",
                    data["midnightSnack"],
                    data["midnightSnackTime"],
                    Icons.bedtime_outlined,
                    Colors.blueGrey,
                    isLocked: lockAllMeals,
                  ),

                  // Subscription Unlock Prompt (If needed)
                  if (isLocked) // Use the main isLocked flag
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: _navigateToChoosePlan, // Use the helper
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_open,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text(
                                'Subscribe to unlock',
                                style: _getTextStyle(context,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Controls which child (collapsed/expanded) is visible based on the map value
            crossFadeState: isExpanded // <<<--- Uses isExpanded from map
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300), // Animation duration
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundShapes(context),
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        backgroundImage: widget.dietitianProfile.isNotEmpty
                            ? NetworkImage(widget.dietitianProfile)
                            : null,
                        child: widget.dietitianProfile.isEmpty
                            ? Icon(Icons.person_outline, size: 50, color: _primaryColor.withOpacity(0.8))
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.dietitianName,
                        style: _getTextStyle(context, fontWeight: FontWeight.bold, fontSize: 22, color: _textColorPrimary(context)),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatColumn(context, _uploadCount.toString(), "Uploads"),
                          Container(
                            height: 30, width: 1,
                            color: Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          _buildStatColumn(context, _followerCount.toString(), "Followers"),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing ? _cardBgColor(context) : _primaryColor,
                                  foregroundColor: _isFollowing ? _primaryColor : _textColorOnPrimary,
                                  side: _isFollowing ? BorderSide(color: _primaryColor, width: 1.5) : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: _isFollowing ? 0 : 4,
                                  shadowColor: _primaryColor.withOpacity(0.3),
                                ),
                                icon: Icon(_isFollowing ? Icons.check : Icons.person_add_alt_1_outlined, size: 20),
                                label: Text(
                                  _isFollowing ? "Following" : "Follow",
                                  style: _getTextStyle(
                                    context,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _isFollowing ? _primaryColor : _textColorOnPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final doc = await FirebaseFirestore.instance .collection('Users').doc(widget.dietitianId).get();
                                    if (!doc.exists) {
                                      CustomSnackBar.show(
                                        context,
                                        'Dietitian not found',
                                        backgroundColor: Colors.orange,
                                        icon: Icons.person_off_outlined,
                                      );
                                      return;
                                    }

                                    final data = doc.data()!;
                                    final dietitianEmail = data['email'] ?? 'No email';
                                    if (mounted) {
                                      Navigator.push( context, MaterialPageRoute( builder: (context) => ChoosePlanPage( dietitianName: widget.dietitianName, dietitianEmail: dietitianEmail, dietitianProfile: widget.dietitianProfile,),),);
                                    }
                                  } catch (e) { debugPrint('Error navigating to choose plan: $e');
                                  CustomSnackBar.show(
                                    context,
                                    'Error: $e',
                                    backgroundColor: Colors.red,
                                    icon: Icons.error_outline,
                                  );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: _textColorOnPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: _primaryColor.withOpacity(0.3),
                                ),
                                icon: const Icon(Icons.workspace_premium_outlined, size: 20),
                                label: Text(
                                  "Subscribe",
                                  style: _getTextStyle(
                                    context,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _textColorOnPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isLoadingBio)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: _primaryColor),
                        )
                      else if (_bio.isNotEmpty && _bio != 'No bio available')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            // --- BIO CARD ---
                            Container(
                              margin: const EdgeInsets.only(bottom: 24.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: _cardBgColor(context),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.info_outlined,
                                          color: _primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "About me",
                                        style: _getTextStyle(
                                          context,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textColorPrimary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _bio,
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 14,
                                      color: _textColorSecondary(context),
                                      fontWeight: FontWeight.w400,
                                      height: 1.6,
                                    ),
                                    // Remove maxLines to show full bio
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Meal Plans",
                          style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // UPDATED: StreamBuilder now checks subscription status
                      if (_isLoadingSubscription) const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: _primaryColor),
                        ),
                      ) else SizedBox (
                      child:StreamBuilder<QuerySnapshot>(
                        key: ValueKey(widget.dietitianId), // Add a key!
                        stream: FirebaseFirestore.instance
                            .collection('mealPlans')
                            .where('owner', isEqualTo: widget.dietitianId)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(color: _primaryColor),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                              decoration: BoxDecoration(
                                  color: _cardBgColor(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300, width: 1)
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.restaurant_menu_outlined, size: 40, color: _primaryColor.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No meal plans uploaded yet.",
                                    style: _getTextStyle(context, fontSize: 15, color: _textColorSecondary(context)),
                                  ),
                                ],
                              ),
                            );
                          }

                          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                          final isLocked = _isContentLocked(); // NEW: Check if content should be locked

                          return Column(
                            children: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final ownerId = data['owner'] ?? '';
                              return _buildMealPlanListItem(
                                context, doc, data, ownerId, currentUserId, isLocked, // NEW: Pass isLocked
                              );
                            }).toList(),
                          );
                        },
                      ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only( topLeft: Radius.circular(20), topRight: Radius.circular(20),),
        child: BottomNavigationBar(
          backgroundColor: _primaryColor,
          selectedItemColor: _textColorOnPrimary,
          unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => home(initialIndex: index)),
                  (route) => false,
            );
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home',),
            BottomNavigationBarItem(icon: Icon(Icons.edit_calendar_outlined), activeIcon: Icon(Icons.edit_calendar), label: 'Schedule',),
            BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Messages',),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: _getTextStyle(context, fontWeight: FontWeight.bold, fontSize: 18, color: _textColorPrimary(context)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: _getTextStyle(context, fontSize: 13, color: _textColorSecondary(context)),
        ),
      ],
    );
  }
  // ADD THIS HELPER METHOD FOR THE DESCRIPTION DIALOG
  void _showFullDescription(
      BuildContext context, String description, String planType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: _cardBgColor(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: _primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Plan Details",
                              style: _getTextStyle(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              planType,
                              style: _getTextStyle(
                                context,
                                fontSize: 12,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      description,
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        color: _textColorPrimary(context),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Got it!',
                        style: _getTextStyle(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
}