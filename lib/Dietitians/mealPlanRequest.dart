import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'createPersonalizedMealPlan.dart';

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

    // Keep the original QueryDocumentSnapshot so we can access doc.id
    final requestsList = widget.requests ?? [];

    // Get current dietitian ID from the first request
    final dietitianId = requestsList.isNotEmpty ? (requestsList.first.data() as Map<String, dynamic>)['dietitianId'] : null;

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
        // Get user data
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(clientId)
            .get();

        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;

        // Get subscription plan
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

        // Add request with Firestore doc ID
        requestsWithPlan.add({
          'requestData': {
            ...request,
            'requestDocId': doc.id, // <-- now valid
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
      appBar: AppBar(
        title: const Text('Meal Plan Requests'),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedRequests.isEmpty
          ? const Center(
        child: Text(
          'No meal plan requests found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile picture and plan badge
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    userData['profile'] ?? '',
                  ),
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userData['firstName']} ${userData['lastName']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildPlanBadge(planType),
              ],
            ),
            const Divider(height: 24),

            // Personal Information Section
            _buildInfoSection(
              'Personal Information',
              [
                _buildInfoRow('Age', '${userData['age']} years old'),
                _buildInfoRow('Gender', userData['gender'] ?? 'N/A'),
                _buildInfoRow('Height', '${userData['height']} cm'),
                _buildInfoRow('Current Weight', '${userData['currentWeight']} kg'),
              ],
            ),
            const SizedBox(height: 12),

            // Goals and Activity Section
            _buildInfoSection(
              'Goals & Activity',
              [
                _buildInfoRow('Goal', userData['goals'] ?? 'N/A'),
                _buildInfoRow('Activity Level', userData['activityLevel'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 12),

            // Request Information
            _buildInfoSection(
              'Request Details',
              [
                _buildInfoRow(
                  'Request Date',
                  _formatTimestamp(requestData['requestDate']),
                ),
                _buildInfoRow(
                  'Status',
                  requestData['status'] ?? 'N/A',
                  valueColor: _getStatusColor(requestData['status']),
                ),
              ],
            ),

            // Message if available
            if (requestData['message'] != null &&
                requestData['message'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        requestData['message'],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Handle decline action
                    _handleDecline(context);
                  },
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Handle create meal plan action
                    _handleCreateMealPlan(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Meal Plan'),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            planType.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Decline Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to decline this meal plan request?'),
              const SizedBox(height: 16),
              const Text(
                'Please provide a reason:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Enter reason for declining...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                reasonController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
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

                  // Get dietitian's information
                  final dietitianDoc = await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .get();

                  final dietitianData = dietitianDoc.data() ?? {};
                  final dietitianName = '${dietitianData['firstName'] ?? ''} ${dietitianData['lastName'] ?? ''}'.trim();

                  // Update mealPlanRequest status to 'rejected' and add reason
                  await FirebaseFirestore.instance
                      .collection('mealPlanRequests')
                      .doc(requestId)
                      .update({
                    'status': 'rejected',
                    'message': reason,
                    'rejectedAt': FieldValue.serverTimestamp(),
                    'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
                  });

                  // Send notification to the client
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(clientId)
                      .collection('notifications')
                      .add({
                    'isRead': false,
                    'title': 'Meal Plan Request Declined',
                    'message': '${dietitianName.isEmpty ? "Your dietitian" : dietitianName} declined your meal plan request. Reason: $reason',
                    'receiverId': clientId,
                    'receiverName': '${userData['firstName']} ${userData['lastName']}',
                    'receiverProfile': userData['profile'] ?? '',
                    'senderId': FirebaseAuth.instance.currentUser?.uid ?? '',
                    'senderName': dietitianName.isEmpty ? 'Your Dietitian' : dietitianName,
                    'senderProfile': dietitianData['profile'] ?? '',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'meal_plan_declined',
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request declined successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Refresh the list by popping back
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Error declining request: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error declining request: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } finally {
                  reasonController.dispose();
                }
              },
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleCreateMealPlan(BuildContext context) {
    // TODO: Navigate to meal plan creation screen with user data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating meal plan for ${userData['firstName']} ${userData['lastName']}'),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePersonalizedMealPlanPage(
          userData: userData,
          requestData: {
            ...requestData,
            'requestId': requestData['requestDocId'], // ✅ Pass the requestId
          },
        ),
      ),
    );
  }
}