class SubscriptionConfig {
  // Subscription types and pricing
  static const Map<String, SubscriptionPlan> plans = {
    'weekly': SubscriptionPlan(
      name: 'Weekly Plan',
      duration: Duration(days: 7),
      price: 7.99,
      description: '7-day access',
      icon: 'Icons.calendar_view_week',
    ),
    'monthly': SubscriptionPlan(
      name: 'Monthly Plan',
      duration: Duration(days: 30),
      price: 29.99,
      description: '30-day access',
      icon: 'Icons.calendar_view_month',
    ),
    'yearly': SubscriptionPlan(
      name: 'Yearly Plan',
      duration: Duration(days: 365),
      price: 99.99,
      description: '365-day access',
      icon: 'Icons.calendar_today',
    ),
  };

  // Commission percentage (10%)
  static const double commissionPercentage = 0.10;

  // Get subscription by type
  static SubscriptionPlan? getplan(String type) => plans[type.toLowerCase()];

  // Get all plans
  static List<SubscriptionPlan> getAllPlans() => plans.values.toList();

  // Calculate commission
  static double calculateCommission(double revenue) {
    return revenue * commissionPercentage;
  }
}

class SubscriptionPlan {
  final String name;
  final Duration duration;
  final double price;
  final String description;
  final String icon;

  const SubscriptionPlan({
    required this.name,
    required this.duration,
    required this.price,
    required this.description,
    required this.icon,
  });

  int get days => duration.inDays;

  double get commission => price * 0.10;
}