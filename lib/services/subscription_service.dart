import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Create a new subscription
  static Future<void> createSubscription({
    required String dietitianId,
    required String subscriptionType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final plan = _getSubscriptionPlan(subscriptionType);
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: plan['days']));

    await _db.collection('subscriptions').add({
      'dietitianId': dietitianId,
      'userId': user.uid,
      'subscriptionType': subscriptionType,
      'status': 'active',
      'price': plan['price'],
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': FieldValue.serverTimestamp(),
      'cancelledAt': null,
    });

    // Update dietitian stats
    await _updateDietitianStats(dietitianId);
  }

  /// Cancel a subscription
  static Future<void> cancelSubscription(String subscriptionId) async {
    final subDoc = await _db.collection('subscriptions').doc(subscriptionId).get();
    final dietitianId = subDoc.data()?['dietitianId'];

    await _db.collection('subscriptions').doc(subscriptionId).update({
      'status': 'canceled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    if (dietitianId != null) {
      await _updateDietitianStats(dietitianId);
    }
  }

  /// Mark expired subscriptions
  static Future<void> markExpiredSubscriptions() async {
    final now = Timestamp.now();

    final expired = await _db
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .where('endDate', isLessThanOrEqualTo: now)
        .get();

    final batch = _db.batch();

    for (var doc in expired.docs) {
      batch.update(doc.reference, {'status': 'expired'});
    }

    await batch.commit();
  }

  /// Get user's active subscriptions
  static Future<List<QueryDocumentSnapshot>> getUserSubscriptions(
      String userId,
      ) async {
    final snapshot = await _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs;
  }

  /// Get dietitian's commission data
  static Future<Map<String, dynamic>> getDietitianCommissions(
      String dietitianId,
      ) async {
    final subscriptions = await _db
        .collection('subscriptions')
        .where('dietitianId', isEqualTo: dietitianId)
        .get();

    double totalRevenue = 0;
    int activeCount = 0;
    int weeklyCount = 0;
    int monthlyCount = 0;
    int yearlyCount = 0;

    for (var doc in subscriptions.docs) {
      final data = doc.data();
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final type = data['subscriptionType'];
      final status = data['status'];

      totalRevenue += price;

      if (status == 'active') activeCount++;

      switch (type) {
        case 'weekly':
          weeklyCount++;
          break;
        case 'monthly':
          monthlyCount++;
          break;
        case 'yearly':
          yearlyCount++;
          break;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalCommission': totalRevenue * 0.10,
      'activeCount': activeCount,
      'weeklyCount': weeklyCount,
      'monthlyCount': monthlyCount,
      'yearlyCount': yearlyCount,
    };
  }

  /// Helper: Get subscription plan data
  static Map<String, dynamic> _getSubscriptionPlan(String type) {
    switch (type.toLowerCase()) {
      case 'weekly':
        return {'price': 7.99, 'days': 7};
      case 'monthly':
        return {'price': 29.99, 'days': 30};
      case 'yearly':
        return {'price': 99.99, 'days': 365};
      default:
        throw Exception('Invalid subscription type');
    }
  }

  /// Helper: Update dietitian stats after subscription change
  static Future<void> _updateDietitianStats(String dietitianId) async {
    final commissions = await getDietitianCommissions(dietitianId);

    await _db.collection('Users').doc(dietitianId).update({
      'activeSubscriptions': commissions['activeCount'],
      'totalRevenue': commissions['totalRevenue'],
      'totalCommission': commissions['totalCommission'],
      'subscriptionBreakdown': {
        'weekly': commissions['weeklyCount'],
        'monthly': commissions['monthlyCount'],
        'yearly': commissions['yearlyCount'],
      },
    });
  }
}