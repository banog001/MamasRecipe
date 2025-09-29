class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String interval; // 'month', 'week', etc.
  final String dietitianId;
  final double platformFee;
  final double dietitianAmount;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'PHP',
    this.interval = 'month',
    required this.dietitianId,
    required this.platformFee,
    required this.dietitianAmount,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'PHP',
      interval: map['interval'] ?? 'month',
      dietitianId: map['dietitianId'] ?? '',
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      dietitianAmount: (map['dietitianAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'interval': interval,
      'dietitianId': dietitianId,
      'platformFee': platformFee,
      'dietitianAmount': dietitianAmount,
    };
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final String dietitianId;
  final String planId;
  final String status; // 'active', 'cancelled', 'past_due'
  final DateTime startDate;
  final DateTime? endDate;
  final String stripeSubscriptionId;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.dietitianId,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.stripeSubscriptionId,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      dietitianId: map['dietitianId'] ?? '',
      planId: map['planId'] ?? '',
      status: map['status'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      stripeSubscriptionId: map['stripeSubscriptionId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dietitianId': dietitianId,
      'planId': planId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'stripeSubscriptionId': stripeSubscriptionId,
    };
  }
}
