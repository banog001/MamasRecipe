import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/home.dart';
import 'package:intl/intl.dart';
import '../plan/choosePlan.dart';

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
  static const Color _primaryColor = Color(0xFF4CAF50);
  static const Color _textColor = Colors.black87;
  static const Color _textColorOnPrimary = Colors.white;
  static const String _fontFamily = 'PlusJakartaSans';

  bool _isFollowing = false;
  int _followerCount = 0;
  int _uploadCount = 0;
  String _bio = "";

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
    _getFollowerCount();
    _getUploadCount();
    _getDietitianBio();
  }

  Future<void> _checkIfFollowing() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('following')
        .doc(widget.dietitianId)
        .get();

    setState(() {
      _isFollowing = doc.exists;
    });
  }

  Future<void> _getFollowerCount() async {
    final dietitianDoc =
    await _firestore.collection('Users').doc(widget.dietitianId).get();
    if (dietitianDoc.exists) {
      setState(() {
        _followerCount = dietitianDoc.data()?['followerCount'] ?? 0;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('Users').doc(user.uid);
    final dietitianRef = _firestore.collection('Users').doc(widget.dietitianId);

    final followingRef =
    userRef.collection('following').doc(widget.dietitianId);
    final followerRef =
    dietitianRef.collection('followers').doc(user.uid);

    final batch = _firestore.batch();

    if (_isFollowing) {
      // 🔹 Unfollow
      batch.delete(followingRef);
      batch.delete(followerRef);

      batch.update(userRef, {
        'followingCount': FieldValue.increment(-1),
      });
      batch.update(dietitianRef, {
        'followerCount': FieldValue.increment(-1),
      });

      setState(() {
        _isFollowing = false;
        _followerCount--;
      });
    } else {
      // 🔹 Follow
      batch.set(followingRef, {
        'dietitianId': widget.dietitianId,
        'dietitianName': widget.dietitianName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.set(followerRef, {
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.update(userRef, {
        'followingCount': FieldValue.increment(1),
      });
      batch.update(dietitianRef, {
        'followerCount': FieldValue.increment(1),
      });

      setState(() {
        _isFollowing = true;
        _followerCount++;
      });
    }

    await batch.commit();
  }

  Future<void> _getUploadCount() async {
    final snapshot = await _firestore
        .collection('mealPlans')
        .where('owner', isEqualTo: widget.dietitianId)
        .get();

    setState(() {
      _uploadCount = snapshot.docs.length;
    });
  }

  Future<void> _getDietitianBio() async {
    final doc = await _firestore.collection('Users').doc(widget.dietitianId).get();
    if (doc.exists) {
      setState(() {
        _bio = doc.data()?['bio'] ?? 'No bio available';
      });
    }
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
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // TODO: Add navigation to full meal plan details page if needed
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data["planType"] ?? "Meal Plan",
                style: const TextStyle(
                  fontFamily: _fontFamily,
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
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const Divider(height: 20),
              if (data["breakfast"] != null)
                Text("🍳 Breakfast: ${data["breakfast"]}",
                    style: const TextStyle(fontFamily: _fontFamily)),
              if (data["lunch"] != null)
                Text("🥗 Lunch: ${data["lunch"]}",
                    style: const TextStyle(fontFamily: _fontFamily)),
              if (data["dinner"] != null)
                Text("🍛 Dinner: ${data["dinner"]}",
                    style: const TextStyle(fontFamily: _fontFamily)),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: widget.dietitianProfile.isNotEmpty
                        ? NetworkImage(widget.dietitianProfile)
                        : const NetworkImage(
                        "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.dietitianName,
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Uploads / Followers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            "$_uploadCount",
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            "Uploads",
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            "$_followerCount",
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            "followers",
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Follow / Subscribe buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? Colors.grey.shade300
                              : _primaryColor,
                          foregroundColor:
                          _isFollowing ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(_isFollowing ? "Following" : "Follow"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final doc = await FirebaseFirestore.instance
                              .collection('Users')
                              .doc(widget.dietitianId)
                              .get();

                          if (!doc.exists) return;

                          final data = doc.data()!;
                          final dietitianEmail = data['email'] ?? 'No email';

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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Subscribe"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Column(
                    children: [
                      Text(
                        _bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(
                        thickness: 1,
                        color: Colors.grey,
                        indent: 20,
                        endIndent: 20,
                      ),
                      const SizedBox(height: 10),

                      // 🔹 Meal Plan List Section
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('mealPlans')
                            .where('ownerId', isEqualTo: widget.dietitianId)
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
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Text(
                                "No meal plan available.",
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

                          return Column(
                            children: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final ownerId = data['ownerId'] ?? '';
                              return _buildMealPlanListItem(
                                context,
                                doc,
                                data,
                                ownerId,
                                currentUserId,
                                false, // dietitian public profile → not showing locked items
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          backgroundColor: _primaryColor,
          selectedItemColor: _textColorOnPrimary.withOpacity(0.6),
          unselectedItemColor: _textColorOnPrimary.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => home(initialIndex: index)),
            );
          },
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
    );
  }
}
