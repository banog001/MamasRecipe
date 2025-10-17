import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'subscription_model.dart';
import 'subscription_service.dart';
import 'subscription_page.dart';

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
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        style: _cardTitleStyle(context).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                  onPressed: () {},
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSubscriptions();
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
