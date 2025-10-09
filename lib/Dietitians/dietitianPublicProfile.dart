import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/home.dart';

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

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
    _getFollowerCount();
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
                        children: const [
                          Text(
                            "2",
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "uploads",
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
                        onPressed: () {},
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
                ],
              ),
            ),
            const SizedBox(height: 80),
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
