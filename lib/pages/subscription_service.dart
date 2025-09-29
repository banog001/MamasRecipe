import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _stripeSecretKey = 'your_stripe_secret_key'; // Store in environment variables
  static const String _baseUrl = 'https://api.stripe.com/v1';

  // Create subscription plan for dietitian
  Future<String> createSubscriptionPlan({
    required String dietitianId,
    required String planName,
    required double price,
    required String interval,
  }) async {
    try {
      // Calculate revenue split (80% to dietitian, 20% to platform)
      double dietitianAmount = price * 0.8;
      double platformFee = price * 0.2;

      // Create Stripe product and price
      final stripeProductId = await _createStripeProduct(planName, dietitianId);
      final stripePriceId = await _createStripePrice(stripeProductId, price, interval);

      // Create subscription plan in Firestore
      final planId = _firestore.collection('subscription_plans').doc().id;
      final plan = SubscriptionPlan(
        id: planId,
        name: planName,
        price: price,
        interval: interval,
        dietitianId: dietitianId,
        platformFee: platformFee,
        dietitianAmount: dietitianAmount,
      );

      await _firestore.collection('subscription_plans').doc(planId).set({
        ...plan.toMap(),
        'stripeProductId': stripeProductId,
        'stripePriceId': stripePriceId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return planId;
    } catch (e) {
      throw Exception('Failed to create subscription plan: $e');
    }
  }

  // Subscribe user to dietitian
  Future<String> subscribeUser({
    required String userId,
    required String planId,
    required String paymentMethodId,
  }) async {
    try {
      // Get subscription plan details
      final planDoc = await _firestore.collection('subscription_plans').doc(planId).get();
      if (!planDoc.exists) throw Exception('Subscription plan not found');

      final plan = SubscriptionPlan.fromMap(planDoc.data()!);
      final stripePriceId = planDoc.data()!['stripePriceId'];

      // Get or create Stripe customer
      final customerId = await _getOrCreateStripeCustomer(userId);

      // Attach payment method to customer
      await _attachPaymentMethod(paymentMethodId, customerId);

      // Create Stripe subscription with Connect account for revenue splitting
      final stripeSubscriptionId = await _createStripeSubscription(
        customerId: customerId,
        priceId: stripePriceId,
        dietitianId: plan.dietitianId,
        platformFee: plan.platformFee,
      );

      // Create subscription record in Firestore
      final subscriptionId = _firestore.collection('user_subscriptions').doc().id;
      final subscription = UserSubscription(
        id: subscriptionId,
        userId: userId,
        dietitianId: plan.dietitianId,
        planId: planId,
        status: 'active',
        startDate: DateTime.now(),
        stripeSubscriptionId: stripeSubscriptionId,
      );

      await _firestore.collection('user_subscriptions').doc(subscriptionId).set(subscription.toMap());

      return subscriptionId;
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  // Get user's active subscriptions
  Future<List<UserSubscription>> getUserSubscriptions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => UserSubscription.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user subscriptions: $e');
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final subscriptionDoc = await _firestore
          .collection('user_subscriptions')
          .doc(subscriptionId)
          .get();

      if (!subscriptionDoc.exists) throw Exception('Subscription not found');

      final subscription = UserSubscription.fromMap(subscriptionDoc.data()!);

      // Cancel Stripe subscription
      await _cancelStripeSubscription(subscription.stripeSubscriptionId);

      // Update Firestore record
      await _firestore.collection('user_subscriptions').doc(subscriptionId).update({
        'status': 'cancelled',
        'endDate': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  // Private helper methods for Stripe API calls
  Future<String> _createStripeProduct(String name, String dietitianId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'name': name,
        'metadata[dietitian_id]': dietitianId,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create Stripe product');
    }
  }

  Future<String> _createStripePrice(String productId, double price, String interval) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/prices'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'product': productId,
        'unit_amount': (price * 100).toInt().toString(), // Convert to cents
        'currency': 'php',
        'recurring[interval]': interval,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create Stripe price');
    }
  }

  Future<String> _getOrCreateStripeCustomer(String userId) async {
    // Check if customer already exists in Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()!['stripeCustomerId'] != null) {
      return userDoc.data()!['stripeCustomerId'];
    }

    // Create new Stripe customer
    final response = await http.post(
      Uri.parse('$_baseUrl/customers'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'metadata[user_id]': userId,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final customerId = data['id'];

      // Save customer ID to Firestore
      await _firestore.collection('users').doc(userId).update({
        'stripeCustomerId': customerId,
      });

      return customerId;
    } else {
      throw Exception('Failed to create Stripe customer');
    }
  }

  Future<void> _attachPaymentMethod(String paymentMethodId, String customerId) async {
    await http.post(
      Uri.parse('$_baseUrl/payment_methods/$paymentMethodId/attach'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'customer': customerId,
      },
    );
  }

  Future<String> _createStripeSubscription({
    required String customerId,
    required String priceId,
    required String dietitianId,
    required double platformFee,
  }) async {
    // Get dietitian's Stripe Connect account ID
    final dietitianDoc = await _firestore.collection('dietitians').doc(dietitianId).get();
    final stripeAccountId = dietitianDoc.data()!['stripeAccountId'];

    final response = await http.post(
      Uri.parse('$_baseUrl/subscriptions'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Account': stripeAccountId, // This routes payment to dietitian's account
      },
      body: {
        'customer': customerId,
        'items[0][price]': priceId,
        'application_fee_percent': (platformFee / (platformFee + (platformFee * 4)) * 100).toString(), // Calculate percentage
        'expand[]': 'latest_invoice.payment_intent',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create Stripe subscription');
    }
  }

  Future<void> _cancelStripeSubscription(String subscriptionId) async {
    await http.delete(
      Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
      },
    );
  }
}
