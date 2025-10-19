import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'subscription_model.dart';
import 'subscription_service.dart';
import '../Dietitians/dietitianPublicProfile.dart';

const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

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

TextStyle _sectionTitleStyle(BuildContext context) => TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: _textColorPrimary(context),
  fontFamily: _primaryFontFamily,
);

TextStyle _cardTitleStyle(BuildContext context) => TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: _textColorPrimary(context),
  fontFamily: _primaryFontFamily,
);

TextStyle _cardSubtitleStyle(BuildContext context) => TextStyle(
  fontSize: 14,
  color: _textColorSecondary(context),
  fontFamily: _primaryFontFamily,
);

TextStyle _cardBodyTextStyle(BuildContext context) => TextStyle(
  fontSize: 14,
  color: _textColorPrimary(context),
  fontFamily: _primaryFontFamily,
);

void showSubscriptionOptions(BuildContext context, String userId) {
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
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(userId)
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
                        isSubscribed ? Icons.check_circle : Icons.info_outline,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DietitiansListPage(),
                    ),
                  );
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MySubscriptionsPage(userId: userId),
                    ),
                  );
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
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: _cardBgColor(context),
                child: // Replace the InkWell onTap in DietitiansListPage with this:

                InkWell(
                  onTap: () {
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
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                            backgroundImage: profileUrl.isNotEmpty
                                ? NetworkImage(profileUrl)
                                : null,
                            child: profileUrl.isEmpty
                                ? const Icon(
                              Icons.health_and_safety,
                              size: 32,
                              color: _primaryColor,
                            )
                                : null,
                          ),
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
                                ).copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
                )
              );
            },
          );
        },
      ),
    );
  }
}

//My Subscription Page
class MySubscriptionsPage extends StatefulWidget {
  final String userId;
  const MySubscriptionsPage({super.key, required this.userId});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  Future<void> _cancelSubscription(String subscriptionId, String dietitianId) async {
    try {
      // Update both sides atomically
      final userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('subscribeTo')
          .doc(subscriptionId);

      final dietitianRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(dietitianId)
          .collection('subscriber')
          .doc(widget.userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(userRef, {'status': 'cancelled'});
        transaction.update(dietitianRef, {'status': 'cancelled'});
      });

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
        print('$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(String subscriptionId, String dietitianId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardBgColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cancel Subscription', style: _sectionTitleStyle(context)),
          content: Text(
            'Are you sure you want to cancel this subscription?\nYou will lose access to premium meal plans.',
            style: _cardBodyTextStyle(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: TextStyle(color: _textColorSecondary(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _cancelSubscription(subscriptionId, dietitianId);
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(widget.userId)
            .collection("subscribeTo")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Subscriptions',
                    style: _sectionTitleStyle(context).copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subscribe to a dietitian to get personalized meal plans',
                    style: _cardSubtitleStyle(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final subscriptions = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subData = subscriptions[index].data() as Map<String, dynamic>;
              final subscriptionId = subscriptions[index].id;
              final dietitianId = subData["dietitianId"];
              final expirationDate =
              (subData["expirationDate"] as Timestamp).toDate();
              final planType = subData["planType"] ?? "";
              final price = subData["price"] ?? "";
              final status = subData["status"] ?? "";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(dietitianId)
                    .get(),
                builder: (context, dietitianSnap) {
                  if (dietitianSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(
                          child: CircularProgressIndicator(color: _primaryColor)),
                    );
                  }

                  if (!dietitianSnap.hasData || !dietitianSnap.data!.exists) {
                    return const SizedBox();
                  }

                  final dietitianData =
                  dietitianSnap.data!.data() as Map<String, dynamic>;
                  final name =
                  "${dietitianData["firstName"] ?? ""} ${dietitianData["lastName"] ?? ""}"
                      .trim();
                  final profileUrl = dietitianData["profile"] ?? "";
                  final now = DateTime.now();
                  final daysLeft =
                  expirationDate.difference(now).inDays.clamp(0, 9999);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: _cardBgColor(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: _primaryColor.withOpacity(0.2),
                            backgroundImage: profileUrl.isNotEmpty
                                ? NetworkImage(profileUrl)
                                : null,
                            child: profileUrl.isEmpty
                                ? const Icon(Icons.person,
                                color: _primaryColor, size: 32)
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Dietitian info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dr. ${name.isEmpty ? "Dietitian" : name}",
                                  style: _cardTitleStyle(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Plan: $planType", style: _cardSubtitleStyle(context)),
                                Text("Price: $price", style: _cardSubtitleStyle(context)),
                                const SizedBox(height: 6),
                                Text(
                                  "Status: $status",
                                  style: _cardSubtitleStyle(context).copyWith(
                                    color: status == "approved"
                                        ? Colors.green
                                        : status == "cancelled"
                                        ? Colors.red
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (status != "cancelled")
                                  TextButton.icon(
                                    onPressed: () => _showCancelDialog(subscriptionId, dietitianId),
                                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                    label: const Text("Cancel",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                              ],
                            ),
                          ),

                          // Countdown
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer, color: _primaryColor),
                              const SizedBox(height: 6),
                              Text(
                                daysLeft > 0 ? "$daysLeft days left" : "Expired",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: daysLeft > 0 ? _primaryColor : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


