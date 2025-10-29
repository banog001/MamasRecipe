import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF0D63F5);

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : Colors.grey.shade100;

Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFAAAAAA)
        : Colors.black54;

Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
    }) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    fontFamily: _primaryFontFamily,
  );
}

TextStyle _cardSubtitleStyle(BuildContext context) => TextStyle(
  fontFamily: _primaryFontFamily,
  fontSize: 12,
  color: _textColorSecondary(context),
);

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  Future<String?> _fetchUserProfile(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['profile'] as String?;
      }
    } catch (e) {
      print("[v0] Error fetching user profile: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "App Feedback & Ratings",
                style: _getTextStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "View feedback from users and dietitians",
                style: _cardSubtitleStyle(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: _primaryColor,
                  unselectedLabelColor: _textColorSecondary(context),
                  indicatorColor: _primaryColor,
                  tabs: const [
                    Tab(icon: Icon(Icons.person), text: "User Feedback"),
                    Tab(
                      icon: Icon(Icons.health_and_safety),
                      text: "Dietitian Feedback",
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUserFeedbackTab(context),
                      _buildDietitianFeedbackTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserFeedbackTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appRatings')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feedback_outlined, size: 80, color: _textColorSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  "No user feedback yet",
                  style: _getTextStyle(context, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final userFeedbacks = snapshot.data!.docs
            .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userRole = data['userRole'] as String?;
          return userRole == null || userRole != 'dietitian';
        })
            .toList();

        if (userFeedbacks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feedback_outlined, size: 80, color: _textColorSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  "No user feedback yet",
                  style: _getTextStyle(context, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: userFeedbacks.length,
          itemBuilder: (context, index) {
            final feedback =
            userFeedbacks[index].data() as Map<String, dynamic>;
            final userId = feedback['userId'] as String?;
            return _buildFeedbackCard(context, feedback, 'user', userId);
          },
        );
      },
    );
  }

  Widget _buildDietitianFeedbackTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appRatings')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feedback_outlined, size: 80, color: _textColorSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  "No dietitian feedback yet",
                  style: _getTextStyle(context, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final dietitianFeedbacks = snapshot.data!.docs
            .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userRole = data['userRole'] as String?;
          return userRole == 'dietitian';
        })
            .toList();

        if (dietitianFeedbacks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feedback_outlined, size: 80, color: _textColorSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  "No dietitian feedback yet",
                  style: _getTextStyle(context, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dietitianFeedbacks.length,
          itemBuilder: (context, index) {
            final feedback =
            dietitianFeedbacks[index].data() as Map<String, dynamic>;
            final userId = feedback['userId'] as String?;
            return _buildFeedbackCard(context, feedback, 'dietitian', userId);
          },
        );
      },
    );
  }

  Widget _buildFeedbackCard(
      BuildContext context,
      Map<String, dynamic> feedback,
      String type,
      String? userId,
      ) {
    final rating = feedback['rating'] as int? ?? 0;
    final description = feedback['description'] as String? ?? '';
    final email = feedback['email'] as String? ?? '';
    final fullName = feedback['fullName'] as String? ?? '';
    final timestamp = feedback['timestamp'] as Timestamp?;
    final cardColor = type == 'user' ? _primaryColor : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _textColorSecondary(context).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<String?>(
                  future: userId != null ? _fetchUserProfile(userId) : Future.value(null),
                  builder: (context, snapshot) {
                    final profileUrl = snapshot.data;

                    if (profileUrl != null && profileUrl.isNotEmpty) {
                      return CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(profileUrl),
                        onBackgroundImageError: (exception, stackTrace) {
                          // Fallback to icon if image fails to load
                        },
                      );
                    }

                    // Fallback to icon
                    return CircleAvatar(
                      backgroundColor: cardColor.withOpacity(0.2),
                      radius: 24,
                      child: Icon(
                        type == 'user' ? Icons.person : Icons.health_and_safety,
                        color: cardColor,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'Anonymous' : fullName,
                        style: _getTextStyle(
                          context,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        email,
                        style: _cardSubtitleStyle(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type == 'user' ? 'User' : 'Dietitian',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cardColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ...List.generate(
                  5,
                      (index) => Icon(
                    index < rating ? Icons.star : Icons.star_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$rating/5',
                  style: _getTextStyle(
                    context,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _textColorSecondary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _textColorSecondary(context).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  description,
                  style: _getTextStyle(context, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              timestamp != null
                  ? DateFormat('MMM dd, yyyy hh:mm a').format(timestamp.toDate())
                  : 'Unknown',
              style: _getTextStyle(
                context,
                fontSize: 12,
                color: _textColorSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
