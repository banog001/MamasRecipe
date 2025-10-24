import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'subscription_model.dart';
import 'subscription_service.dart';
import '../Dietitians/dietitianPublicProfile.dart';
import 'dart:async';

// --- Theme Helpers (Copied from other files) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white; // Changed to white

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
      double? height, // Added height parameter
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
    height: height, // Use height parameter
  );
}
// --- End Theme Helpers ---

// --- Background Shapes Widget ---
Widget _buildBackgroundShapes(BuildContext context) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: _scaffoldBgColor(context), // Use theme background color
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
// --- End Background Shapes Widget ---


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
    backgroundColor: _cardBgColor(context), // Use theme color
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Consistent radius
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40), // Adjusted padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Subscription Options',
              style: _getTextStyle( // Use theme helper
                context,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColorPrimary(context),
              ),
            ),
            const SizedBox(height: 24), // Increased spacing

            // Browse Dietitians Button
            SizedBox(
              width: double.infinity,
              height: 56, // Standard height
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Consistent radius
                  ),
                  elevation: 4, // Consistent elevation
                  shadowColor: _primaryColor.withOpacity(0.3),
                ),
                icon: const Icon(Icons.person_search_rounded, size: 22),
                label: Text(
                  'Browse Dietitians',
                  style: _getTextStyle( // Use theme helper
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColorOnPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // Consistent spacing

            // My Subscriptions Button (Outlined Style)
            SizedBox(
              width: double.infinity,
              height: 56, // Standard height
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
                  side: const BorderSide(color: _primaryColor, width: 1.5), // Consistent border
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Consistent radius
                  ),
                ),
                icon: const Icon(Icons.subscriptions_outlined, size: 22),
                label: Text(
                  'My Subscriptions',
                  style: _getTextStyle( // Use theme helper
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
            // Removed extra SizedBox
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
      backgroundColor: _scaffoldBgColor(context), // Use theme color
      appBar: AppBar(
        title: Text(
          'Choose Your Dietitian',
          style: _getTextStyle( // Use theme helper
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary,
          ),
        ),
        backgroundColor: _primaryColor, // Use theme color
        foregroundColor: _textColorOnPrimary, // Use theme color
        elevation: 1,
        leading: IconButton( // Added back button consistent styling
          icon: const Icon(Icons.arrow_back, color: _textColorOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack( // <-- Wrap body with Stack
        children: [
          _buildBackgroundShapes(context), // <-- Add background shapes
          StreamBuilder<QuerySnapshot>(
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
                // Styled Empty State
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_outlined, // Changed icon
                        size: 80,
                        color: _primaryColor.withOpacity(0.3), // Use theme color opacity
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Dietitians Found',
                        style: _getTextStyle( // Use theme helper
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColorPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for available dietitians.',
                        style: _getTextStyle( // Use theme helper
                          context,
                          fontSize: 14,
                          color: _textColorSecondary(context),
                        ),
                        textAlign: TextAlign.center,
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

                  // Styled Card
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0, // Remove elevation for flat design
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Consistent radius
                        side: BorderSide(color: Colors.grey.shade300, width: 1) // Subtle border
                    ),
                    color: _cardBgColor(context), // Use theme color
                    child: InkWell(
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
                      borderRadius: BorderRadius.circular(16), // Match shape radius
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Styled Avatar
                            CircleAvatar(
                              radius: 30, // Slightly smaller
                              backgroundColor: _primaryColor.withOpacity(0.1), // Lighter background
                              backgroundImage: profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl.isEmpty
                                  ? const Icon(
                                Icons.health_and_safety_outlined, // Changed icon
                                size: 28, // Adjusted size
                                color: _primaryColor,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Styled Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? "Dietitian" : name, // Removed "Dr." prefix for consistency
                                    style: _getTextStyle( // Use theme helper
                                      context,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _textColorPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    specialization,
                                    style: _getTextStyle( // Use theme helper
                                      context,
                                      fontSize: 13,
                                      color: _textColorSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Removed "View Plans" Container, implied by tap
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
        ],
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
  Timer? _expireTimer;

  // --- Functions (Unchanged Logic, Adjusted Dialog Styling) ---
  Future<void> _updateExpiredSubscriptions() async {
    // ... (Your existing logic is correct)
    try {
      final now = DateTime.now();
      print('Current device time: $now');

      final userSubsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('subscribeTo')
          .get();

      for (var doc in userSubsSnapshot.docs) {
        final subData = doc.data();
        final expirationDate = (subData["expirationDate"] as Timestamp).toDate();
        final status = subData["status"] ?? "";

        print('Subscription ${doc.id} - Expiration date: $expirationDate, Status: $status');
        print('Is expired: ${expirationDate.isBefore(now)}');

        if (expirationDate.isBefore(now) && status != "expired") {
          final dietitianId = subData["dietitianId"];

          try {
            final userRef = FirebaseFirestore.instance
                .collection('Users')
                .doc(widget.userId)
                .collection('subscribeTo')
                .doc(doc.id);

            final dietitianRef = FirebaseFirestore.instance
                .collection('Users')
                .doc(dietitianId)
                .collection('subscriber')
                .doc(widget.userId);

            await FirebaseFirestore.instance.runTransaction((transaction) async {
              transaction.update(userRef, {'status': 'expired'});
              transaction.update(dietitianRef, {'status': 'expired'});
            });

            print('Updated subscription ${doc.id} to expired');
          } catch (e) {
            print('Error updating single subscription: $e');
          }
        }
      }
    } catch (e) {
      print('Error updating expired subscriptions: $e');
    }
  }

  Future<void> _cancelSubscription(String subscriptionId, String dietitianId) async {
    // ... (Your existing logic is correct)
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

  // --- Updated Cancel Dialog Styling ---
  void _showCancelDialog(String subscriptionId, String dietitianId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Consistent barrier
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Consistent shape
          backgroundColor: Colors.transparent, // For background shapes
          child: ClipRRect( // Clip for background
            borderRadius: BorderRadius.circular(24),
            child: Stack( // Stack for background
              children: [
                // Background Shapes
                Positioned.fill(
                  child: Container(
                    color: _cardBgColor(dialogContext),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50, left: -80,
                          child: Container( width: 200, height: 200,
                            decoration: BoxDecoration( color: Colors.red.withOpacity(0.06), shape: BoxShape.circle,),
                          ),
                        ),
                        Positioned(
                          bottom: -60, right: -90,
                          child: Container( width: 250, height: 250,
                            decoration: BoxDecoration( color: Colors.red.withOpacity(0.06), shape: BoxShape.circle,),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(32.0), // Consistent padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration( color: Colors.red.withOpacity(0.1), shape: BoxShape.circle,),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text('Cancel Subscription?',
                        style: _getTextStyle(dialogContext, fontSize: 22, fontWeight: FontWeight.bold, color: _textColorPrimary(dialogContext)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Message
                      Text(
                        'Are you sure? You will lose access to premium meal plans from this dietitian.',
                        style: _getTextStyle(dialogContext, fontSize: 15, color: _textColorSecondary(dialogContext)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _textColorSecondary(dialogContext),
                                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text('No', style: _getTextStyle(dialogContext, fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  await _cancelSubscription(subscriptionId, dietitianId);
                                },
                                child: Text('Yes, Cancel', style: _getTextStyle(dialogContext, fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
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
  // --- End Updated Dialog Styling ---

  @override
  void initState() {
    super.initState();
    _updateExpiredSubscriptions();
    _expireTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _updateExpiredSubscriptions();
      }
    });
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context), // Use theme color
      appBar: AppBar(
        title: Text('My Subscriptions', style: _getTextStyle(context, fontSize: 20, fontWeight: FontWeight.bold, color: _textColorOnPrimary)),
        backgroundColor: _primaryColor, // Use theme color
        foregroundColor: _textColorOnPrimary, // Use theme color
        elevation: 1,
        leading: IconButton( // Added back button consistent styling
          icon: const Icon(Icons.arrow_back, color: _textColorOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack( // <-- Wrap body with Stack
        children: [
          _buildBackgroundShapes(context), // <-- Add background shapes
          StreamBuilder<QuerySnapshot>(
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
                // Styled Empty State
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.subscriptions_outlined, size: 80, color: _primaryColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No Subscriptions Yet',
                        style: _getTextStyle(context, fontSize: 18, fontWeight: FontWeight.bold, color: _textColorPrimary(context)),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Subscribe to a dietitian to get personalized meal plans.',
                          style: _getTextStyle(context, fontSize: 14, color: _textColorSecondary(context)),
                          textAlign: TextAlign.center,
                        ),
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
                  var status = subData["status"] ?? "";

                  final now = DateTime.now();
                  final daysLeft =
                  expirationDate.difference(now).inDays.clamp(0, 9999);

                  if (expirationDate.isBefore(now) && status != "expired" && status != "cancelled") {
                    status = "expired";
                  }

                  // Function to get status color
                  Color getStatusColor(String currentStatus) {
                    switch (currentStatus.toLowerCase()) {
                      case 'approved': return Colors.green.shade600;
                      case 'cancelled': return Colors.redAccent;
                      case 'expired': return Colors.grey.shade600;
                      case 'pending': return Colors.orange.shade700;
                      default: return _textColorSecondary(context);
                    }
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("Users")
                        .doc(dietitianId)
                        .get(),
                    builder: (context, dietitianSnap) {
                      if (dietitianSnap.connectionState == ConnectionState.waiting) {
                        return const SizedBox( height: 100, child: Center( child: CircularProgressIndicator(color: _primaryColor)),);
                      }
                      if (!dietitianSnap.hasData || !dietitianSnap.data!.exists) {
                        // Optionally show a placeholder if dietitian data is missing
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300, width: 1)
                          ),
                          color: _cardBgColor(context),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Dietitian data not found.', style: _getTextStyle(context, color: Colors.redAccent)),
                          ),
                        );
                      }

                      final dietitianData =
                      dietitianSnap.data!.data() as Map<String, dynamic>;
                      final name =
                      "${dietitianData["firstName"] ?? ""} ${dietitianData["lastName"] ?? ""}"
                          .trim();
                      final profileUrl = dietitianData["profile"] ?? "";

                      // Styled Card
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0, // Flat design
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade300, width: 1) // Subtle border
                        ),
                        color: _cardBgColor(context), // Theme color
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align top
                            children: [
                              // Profile Avatar
                              CircleAvatar(
                                radius: 30, // Slightly smaller
                                backgroundColor: _primaryColor.withOpacity(0.1),
                                backgroundImage: profileUrl.isNotEmpty
                                    ? NetworkImage(profileUrl)
                                    : null,
                                child: profileUrl.isEmpty
                                    ? const Icon(Icons.person_outline, // Changed icon
                                    color: _primaryColor, size: 28) // Adjusted size
                                    : null,
                              ),
                              const SizedBox(width: 16),

                              // Subscription Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text( // Dietitian Name
                                      name.isEmpty ? "Dietitian" : name,
                                      style: _getTextStyle(context, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    // Plan and Price Row
                                    Row(
                                      children: [
                                        _buildDetailChip(context, Icons.description_outlined, planType),
                                        const SizedBox(width: 8),
                                        _buildDetailChip(context, Icons.sell_outlined, price),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Status Text
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: getStatusColor(status)),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Status: ${status[0].toUpperCase()}${status.substring(1)}", // Capitalized status
                                          style: _getTextStyle(context,
                                            fontSize: 13,
                                            color: getStatusColor(status),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Days Left Text
                                    if (status != "cancelled" && status != "expired") ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 16, color: daysLeft > 7 ? _primaryColor : Colors.orange.shade700),
                                          const SizedBox(width: 6),
                                          Text(
                                            daysLeft > 0 ? "$daysLeft days left" : "Expires today",
                                            style: _getTextStyle(context,
                                              fontSize: 13,
                                              color: daysLeft > 7 ? _primaryColor : Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Cancel Button
                                    if (status != "cancelled" && status != "expired") ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: () => _showCancelDialog(subscriptionId, dietitianId),
                                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                                          label: Text("Cancel Subscription",
                                              style: _getTextStyle(context, color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
        ],
      ),
    );
  }

  // Helper widget for Plan/Price chips
  Widget _buildDetailChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: _getTextStyle(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

