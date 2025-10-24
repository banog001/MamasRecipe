import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/home.dart';
import 'package:intl/intl.dart';
import '../plan/choosePlan.dart';

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

  @override
  State<DietitianPublicProfile> createState() => _DietitianPublicProfileState();
}

class _DietitianPublicProfileState extends State<DietitianPublicProfile> {
  bool _isFollowing = false;
  int _followerCount = 0;
  int _uploadCount = 0;
  String _bio = "";
  bool _isLoadingBio = true;

  // NEW: Subscription status
  String _subscriptionStatus = '';
  bool _isLoadingSubscription = true;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
    _getFollowerCount();
    _getUploadCount();
    _getDietitianBio();
    _checkSubscriptionStatus(); // NEW
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
          setState(() => _followerCount = doc.data()?['followerCount'] ?? 0);
        }
      });
    } catch (e) { debugPrint('Error fetching follower count: $e'); }
  }

  Future<void> _toggleFollow() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Please log in to follow dietitians')),);
      return;
    }
    if (user.uid == widget.dietitianId) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('You cannot follow yourself')), );
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
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error: $e')),);

      if (mounted) {
        setState(() {
          _isFollowing = previousFollowingState;
          _followerCount = previousFollowerCount;
        });
      }
    }
  }

  Future<void> _getUploadCount() async {
    try {
      _firestore.collection('mealPlans').where('owner', isEqualTo: widget.dietitianId).snapshots().listen((snapshot) {
        if (mounted) {
          setState(() => _uploadCount = snapshot.docs.length);
        }
      });
    } catch (e) { debugPrint('Error fetching upload count: $e'); }
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

  // UPDATED: Meal Plan List Item with lock overlay
  Widget _buildMealPlanListItem(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      String ownerId,
      String currentUserId,
      bool isLocked,
      ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      color: _cardBgColor(context),
      child: Stack(
        children: [
          Opacity(
            opacity: isLocked ? 0.5 : 1.0,
            child: InkWell(
              onTap: isLocked
                  ? () async {
                // Navigate to ChoosePlanPage when locked
                try {
                  final dietitianDoc = await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(widget.dietitianId)
                      .get();

                  if (!dietitianDoc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dietitian not found')),
                    );
                    return;
                  }

                  final dietitianData = dietitianDoc.data()!;
                  final dietitianEmail = dietitianData['email'] ?? 'No email';

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
                  : () {
                // TODO: Add navigation for unlocked meal plans if needed
              },
              borderRadius: BorderRadius.circular(16),
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
                            data["planType"] ?? "Meal Plan",
                            style: _getTextStyle(context, fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor),
                          ),
                        ),
                        // Show time
                        if (data["timestamp"] != null && data["timestamp"] is Timestamp)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormat('hh:mm a').format((data["timestamp"] as Timestamp).toDate()),
                              style: _getTextStyle(
                                context,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Date
                    if (data["timestamp"] != null && data["timestamp"] is Timestamp)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format((data["timestamp"] as Timestamp).toDate()),
                          style: _getTextStyle(context, fontSize: 12, color: _textColorSecondary(context)),
                        ),
                      ),
                    const Divider(height: 16),
                    if (data["breakfast"] != null && data["breakfast"].isNotEmpty)
                      _buildMealDetailRow(context, "🍳", "Breakfast", data["breakfast"], isLocked),
                    if (data["amSnack"] != null && data["amSnack"].isNotEmpty)
                      _buildMealDetailRow(context, "🍎", "AM Snack", data["amSnack"], isLocked),
                    if (data["lunch"] != null && data["lunch"].isNotEmpty)
                      _buildMealDetailRow(context, "🥗", "Lunch", data["lunch"], isLocked),
                    if (data["pmSnack"] != null && data["pmSnack"].isNotEmpty)
                      _buildMealDetailRow(context, "🥜", "PM Snack", data["pmSnack"], isLocked),
                    if (data["dinner"] != null && data["dinner"].isNotEmpty)
                      _buildMealDetailRow(context, "🍛", "Dinner", data["dinner"], isLocked),
                    if (data["midnightSnack"] != null && data["midnightSnack"].isNotEmpty)
                      _buildMealDetailRow(context, "🍪", "Midnight Snack", data["midnightSnack"], isLocked),
                  ],
                ),
              ),
            ),
          ),
          // Lock overlay when content is locked
          if (isLocked)
            Positioned.fill(
              child: InkWell(
                onTap: () async {
                  // Navigate to ChoosePlanPage when tapping the lock overlay
                  try {
                    final dietitianDoc = await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(widget.dietitianId)
                        .get();

                    if (!dietitianDoc.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dietitian not found')),
                      );
                      return;
                    }

                    final dietitianData = dietitianDoc.data()!;
                    final dietitianEmail = dietitianData['email'] ?? 'No email';

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: _primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subscribe to unlock',
                          style: _getTextStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view plans',
                          style: _getTextStyle(
                            context,
                            fontSize: 12,
                            color: _textColorSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // UPDATED: Helper for meal detail row with blur effect when locked
  Widget _buildMealDetailRow(BuildContext context, String emoji, String label, String value, bool isLocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLocked ? "$label: ••••••••••" : "$label: ${value.trim()}",
              style: _getTextStyle(context, fontSize: 14, color: _textColorPrimary(context)),
            ),
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
                                    if (!doc.exists) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Dietitian not found')),); return; }
                                    final data = doc.data()!;
                                    final dietitianEmail = data['email'] ?? 'No email';
                                    if (mounted) {
                                      Navigator.push( context, MaterialPageRoute( builder: (context) => ChoosePlanPage( dietitianName: widget.dietitianName, dietitianEmail: dietitianEmail, dietitianProfile: widget.dietitianProfile,),),);
                                    }
                                  } catch (e) { debugPrint('Error navigating to choose plan: $e'); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error: $e')),); }
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
                      const SizedBox(height: 32),

                      if (_isLoadingBio)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: _primaryColor),
                        )
                      else if (_bio.isNotEmpty && _bio != 'No bio available')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "About",
                              style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _bio,
                              style: _getTextStyle(context, fontSize: 14, color: _textColorSecondary(context), height: 1.5),
                            ),
                            const SizedBox(height: 24),
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
                      _isLoadingSubscription
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: _primaryColor),
                        ),
                      )
                          : StreamBuilder<QuerySnapshot>(
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
                      const SizedBox(height: 20),
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
}