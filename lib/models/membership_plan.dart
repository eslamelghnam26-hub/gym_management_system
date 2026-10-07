class MembershipPlan {
  MembershipPlan({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    this.sessions = 0,
    this.features = const [],
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final int durationDays;
  final double price;
  /// Number of included sessions; `0` means unlimited.
  final int sessions;
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;

  bool get isUnlimitedSessions => sessions <= 0;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        sessions: (json['sessions'] as num?)?.toInt() ?? 0,
        features: [
          for (final f in (json['features'] as List<dynamic>? ?? []))
            if (f is String) f,
        ],
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'durationDays': durationDays,
        'price': price,
        'sessions': sessions,
        'features': features,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  MembershipPlan copyWith({
    String? id,
    String? name,
    int? durationDays,
    double? price,
    int? sessions,
    List<String>? features,
    bool? isActive,
  }) =>
      MembershipPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        durationDays: durationDays ?? this.durationDays,
        price: price ?? this.price,
        sessions: sessions ?? this.sessions,
        features: features ?? this.features,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}