import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'createPersonalizedMealPlan.dart';

// Theme Constants
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade50;

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
      Color? color, required double height,
    }) {
  return TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
  );
}

// Main screen that displays the list of meal plan requests
class MealPlanRequestCard extends StatefulWidget {
  final List<QueryDocumentSnapshot>? requests;

  const MealPlanRequestCard({
    Key? key,
    this.requests,
  }) : super(key: key);

  @override
  State<MealPlanRequestCard> createState() => _MealPlanRequestCardState();
}

class _MealPlanRequestCardState extends State<MealPlanRequestCard> {
  List<Map<String, dynamic>> sortedRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndSortRequests();
  }

  Future<void> _loadAndSortRequests() async {
    setState(() => isLoading = true);

    List<Map<String, dynamic>> requestsWithPlan = [];

    final requestsList = widget.requests ?? [];
    final dietitianId = requestsList.isNotEmpty
        ? (requestsList.first.data() as Map<String, dynamic>)['dietitianId']
        : null;

    if (dietitianId == null) {
      setState(() {
        sortedRequests = [];
        isLoading = false;
      });
      return;
    }

    for (var doc in requestsList) {
      final request = doc.data() as Map<String, dynamic>;
      final clientId = request['clientId'];

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(clientId)
            .get();

        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;

        final subscriberDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(dietitianId)
            .collection('subscriber')
            .doc(clientId)
            .get();

        String planType = 'none';
        if (subscriberDoc.exists) {
          final subData = subscriberDoc.data();
          planType = subData?['planType']?.toString().toLowerCase() ?? 'none';
        }

        requestsWithPlan.add({
          'requestData': {
            ...request,
            'requestDocId': doc.id,
          },
          'userData': userData,
          'planType': planType,
        });
      } catch (e) {
        print('Error loading request for client $clientId: $e');
      }
    }

    // Sort by plan priority and date
    requestsWithPlan.sort((a, b) {
      final planPriority = {'yearly': 1, 'monthly': 2, 'weekly': 3, 'none': 4};
      final aPriority = planPriority[a['planType']] ?? 5;
      final bPriority = planPriority[b['planType']] ?? 5;

      if (aPriority != bPriority) return aPriority.compareTo(bPriority);

      try {
        final aDate = (a['requestData']['requestDate'] as Timestamp).toDate();
        final bDate = (b['requestData']['requestDate'] as Timestamp).toDate();
        return aDate.compareTo(bDate);
      } catch (e) {
        return 0;
      }
    });

    setState(() {
      sortedRequests = requestsWithPlan;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: _textColorOnPrimary, size: 28),
        title: Text(
          'Meal Plan Requests',
          style: _getTextStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorOnPrimary, height: 1,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      )
          : sortedRequests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: _primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No meal plan requests found',
              style: _getTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textColorSecondary(context), height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Requests from your clients will appear here',
              style: _getTextStyle(
                context,
                fontSize: 14,
                color: _textColorSecondary(context), height: 1,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedRequests.length,
        itemBuilder: (context, index) {
          final request = sortedRequests[index];
          return _MealPlanCard(
            userData: request['userData'],
            requestData: request['requestData'],
            planType: request['planType'],
          );
        },
      ),
    );
  }
}

// Individual card widget for each meal plan request
class _MealPlanCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> requestData;
  final String planType;

  const _MealPlanCard({
    required this.userData,
    required this.requestData,
    required this.planType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBgColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor,
                  _primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: (userData['profile'] != null &&
                        userData['profile'].toString().isNotEmpty)
                        ? NetworkImage(userData['profile'])
                        : null,
                    backgroundColor: Colors.white,
                    child: (userData['profile'] == null ||
                        userData['profile'].toString().isEmpty)
                        ? Icon(
                      Icons.person,
                      color: _primaryColor,
                      size: 32,
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userData['firstName']} ${userData['lastName']}',
                        style: _getTextStyle(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              userData['email'] ?? '',
                              style: _getTextStyle(
                                context,
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9), height: 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Plan Badge
                _buildPlanBadge(planType),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information
                _buildSectionHeader(context, 'Personal Information', Icons.person_outline),
                const SizedBox(height: 12),
                _buildInfoGrid(context, [
                  _InfoItem(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: '${userData['age']} years',
                    color: Colors.blue,
                  ),
                  _InfoItem(
                    icon: Icons.wc_outlined,
                    label: 'Gender',
                    value: userData['gender'] ?? 'N/A',
                    color: Colors.purple,
                  ),
                  _InfoItem(
                    icon: Icons.height_outlined,
                    label: 'Height',
                    value: '${userData['height']} cm',
                    color: Colors.orange,
                  ),
                  _InfoItem(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value: '${userData['currentWeight']} kg',
                    color: Colors.red,
                  ),
                ]),

                const SizedBox(height: 20),
                Divider(color: _textColorSecondary(context).withOpacity(0.2)),
                const SizedBox(height: 20),

                // Goals & Activity
                _buildSectionHeader(context, 'Goals & Activity', Icons.flag_outlined),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.track_changes_outlined,
                  'Goal',
                  userData['goals'] ?? 'N/A',
                  _primaryColor,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.directions_run_outlined,
                  'Activity Level',
                  userData['activityLevel'] ?? 'N/A',
                  Colors.deepOrange,
                ),

                const SizedBox(height: 20),
                Divider(color: _textColorSecondary(context).withOpacity(0.2)),
                const SizedBox(height: 20),

                // Request Information
                _buildSectionHeader(context, 'Request Details', Icons.info_outline),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.calendar_today_outlined,
                  'Request Date',
                  _formatTimestamp(requestData['requestDate']),
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.bookmark_outline,
                  'Status',
                  requestData['status'] ?? 'N/A',
                  _getStatusColor(requestData['status']),
                ),

                // Message Section
                if (requestData['message'] != null &&
                    requestData['message'].toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader(context, 'Client Message', Icons.message_outlined),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      requestData['message'],
                      style: _getTextStyle(
                        context,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleDecline(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          foregroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: Text(
                          'Decline',
                          style: _getTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCreateMealPlan(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: _primaryColor.withOpacity(0.4),
                        ),
                        icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                        label: Text(
                          'Create Meal Plan',
                          style: _getTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,height: 1,
                          ),
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: _primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: _getTextStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.bold,height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context, List<_InfoItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: item.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: _getTextStyle(
                        context,
                        fontSize: 11,
                        color: _textColorSecondary(context),height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: _getTextStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _getTextStyle(
                    context,
                    fontSize: 12,
                    color: _textColorSecondary(context),height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: _getTextStyle(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String planType) {
    Color badgeColor;
    IconData icon;

    switch (planType.toLowerCase()) {
      case 'yearly':
        badgeColor = Colors.purple;
        icon = Icons.workspace_premium;
        break;
      case 'monthly':
        badgeColor = Colors.blue;
        icon = Icons.calendar_month;
        break;
      case 'weekly':
        badgeColor = Colors.orange;
        icon = Icons.calendar_today;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            planType.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: _primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'N/A';
      }

      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _handleDecline(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: _cardBgColor(dialogContext),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Decline Request',
                        style: _getTextStyle(
                          dialogContext,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you sure you want to decline this meal plan request?',
                        style: _getTextStyle(
                          dialogContext,
                          fontSize: 15, height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Reason for declining',
                        style: _getTextStyle(
                          dialogContext,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 4,
                        maxLength: 200,
                        style: _getTextStyle(dialogContext, height: 1),
                        decoration: InputDecoration(
                          hintText: 'Enter reason for declining...',
                          hintStyle: _getTextStyle(
                            dialogContext,
                            color: _textColorSecondary(dialogContext), height: 1,
                          ),
                          filled: true,
                          fillColor: _scaffoldBgColor(dialogContext),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            reasonController.dispose();
                            Navigator.pop(dialogContext);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: _getTextStyle(
                              dialogContext,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textColorSecondary(dialogContext), height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final reason = reasonController.text.trim();

                            if (reason.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please provide a reason for declining'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(dialogContext);

                            try {
                              final requestId = requestData['requestDocId'];
                              final clientId = requestData['clientId'];

                              if (requestId == null || requestId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error: Invalid request ID'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              final dietitianDoc = await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .get();

                              final dietitianData = dietitianDoc.data() ?? {};
                              final dietitianName =
                              '${dietitianData['firstName'] ?? ''} ${dietitianData['lastName'] ?? ''}'
                                  .trim();

                              await FirebaseFirestore.instance
                                  .collection('mealPlanRequests')
                                  .doc(requestId)
                                  .update({
                                'status': 'rejected',
                                'message': reason,
                                'rejectedAt': FieldValue.serverTimestamp(),
                                'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
                              });

                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(clientId)
                                  .collection('notifications')
                                  .add({
                                'isRead': false,
                                'title': 'Meal Plan Request Declined',
                                'message':
                                '${dietitianName.isEmpty ? "Your dietitian" : dietitianName} declined your meal plan request. Reason: $reason',
                                'receiverId': clientId,
                                'receiverName':
                                '${userData['firstName']} ${userData['lastName']}',
                                'receiverProfile': userData['profile'] ?? '',
                                'senderId': FirebaseAuth.instance.currentUser?.uid ?? '',
                                'senderName':
                                dietitianName.isEmpty ? 'Your Dietitian' : dietitianName,
                                'senderProfile': dietitianData['profile'] ?? '',
                                'timestamp': FieldValue.serverTimestamp(),
                                'type': 'meal_plan_declined',
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Request declined successfully',
                                            style: TextStyle(
                                              fontFamily: _primaryFontFamily,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );

                                Navigator.pop(context);
                              }
                            } catch (e) {
                              print('Error declining request: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Error declining request: $e',
                                            style: const TextStyle(
                                              fontFamily: _primaryFontFamily,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              reasonController.dispose();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.red.withOpacity(0.4),
                          ),
                          child: Text(
                            'Decline',
                            style: _getTextStyle(
                              dialogContext,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, height: 1,
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
        );
      },
    );
  }

  void _handleCreateMealPlan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Creating meal plan for ${userData['firstName']} ${userData['lastName']}',
                style: const TextStyle(
                  fontFamily: _primaryFontFamily,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePersonalizedMealPlanPage(
          userData: userData,
          requestData: {
            ...requestData,
            'requestId': requestData['requestDocId'],
          },
        ),
      ),
    );
  }
}

// Helper class for info items in the grid
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}