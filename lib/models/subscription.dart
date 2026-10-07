enum SubscriptionStatus {
  active('active'),
  expired('expired'),
  cancelled('cancelled');

  const SubscriptionStatus(this.key);

  final String key;

  static SubscriptionStatus fromKey(String? key) => SubscriptionStatus.values
      .firstWhere((s) => s.key == key, orElse: () => SubscriptionStatus.expired);
}

class Subscription {
  Subscription({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.method,
    this.status = SubscriptionStatus.active,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String memberId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String? method;
  final SubscriptionStatus status;
  final String? notes;
  final DateTime createdAt;

  int get remainingDays {
    final now = DateTime.now();
    final days = endDate.difference(now).inDays;
    return days < 0 ? 0 : days;
  }

  bool get isActive => status == SubscriptionStatus.active;

  int daysLeft(DateTime now) => endDate.difference(now).inDays;

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String? ?? '',
        memberId: json['memberId'] as String? ?? '',
        planId: json['planId'] as String? ?? '',
        startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        method: json['method'] as String?,
        status: SubscriptionStatus.fromKey(json['status'] as String?),
        notes: json['notes'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'planId': planId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'price': price,
        'method': method,
        'status': status.key,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  Subscription copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? method,
    SubscriptionStatus? status,
    String? notes,
  }) =>
      Subscription(
        id: id ?? this.id,
        memberId: memberId,
        planId: planId,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        price: price ?? this.price,
        method: method ?? this.method,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}