/// Single-document gym configuration, editable by admins and later consumed
/// by the web dashboard connected to the same data source.
class GymSettings {
  GymSettings({
    this.gymName = 'Gym Pro',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.openingHours = '',
    this.currency = 'ج.م',
    this.autoRenewReminderDays = 7,
    List<String>? services,
    List<String>? rules,
    List<KnowledgeFaq>? faqs,
  })  : services = services ?? const [],
        rules = rules ?? const [],
        faqs = faqs ?? const [];

  final String gymName;
  final String address;
  final String phone;
  final String email;
  final String openingHours;
  final String currency;
  final int autoRenewReminderDays;

  /// Knowledge base used by the admin "AI" assistant: gym services, house
  /// rules and frequently asked questions. Pure additive fields — the mobile
  /// app keeps working when these are missing.
  final List<String> services;
  final List<String> rules;
  final List<KnowledgeFaq> faqs;

  static final GymSettings defaults = GymSettings();

  factory GymSettings.fromJson(Map<String, dynamic> json) => GymSettings(
        gymName: json['gymName'] as String? ?? 'Gym Pro',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        openingHours: json['openingHours'] as String? ?? '',
        currency: json['currency'] as String? ?? 'ج.م',
        autoRenewReminderDays: (json['autoRenewReminderDays'] as num?)?.toInt() ?? 7,
        services: toList(json['services']),
        rules: toList(json['rules']),
        faqs: [
          for (final f in (json['faqs'] as List? ?? const []))
            if (f is Map<String, dynamic>) KnowledgeFaq.fromJson(f),
        ],
      );

  Map<String, dynamic> toJson() => {
        'gymName': gymName,
        'address': address,
        'phone': phone,
        'email': email,
        'openingHours': openingHours,
        'currency': currency,
        'autoRenewReminderDays': autoRenewReminderDays,
        'services': services,
        'rules': rules,
        'faqs': [for (final f in faqs) f.toJson()],
      };

  GymSettings copyWith({
    String? gymName,
    String? address,
    String? phone,
    String? email,
    String? openingHours,
    String? currency,
    int? autoRenewReminderDays,
    List<String>? services,
    List<String>? rules,
    List<KnowledgeFaq>? faqs,
  }) =>
      GymSettings(
        gymName: gymName ?? this.gymName,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        openingHours: openingHours ?? this.openingHours,
        currency: currency ?? this.currency,
        autoRenewReminderDays: autoRenewReminderDays ?? this.autoRenewReminderDays,
        services: services ?? this.services,
        rules: rules ?? this.rules,
        faqs: faqs ?? this.faqs,
      );

  static List<String> toList(dynamic value) => [
        for (final item in value is List ? value : const <dynamic>[])
          if (item is String) item,
      ];
}

/// A single knowledge-base Q&A entry used by the AI assistant.
class KnowledgeFaq {
  const KnowledgeFaq({required this.question, required this.answer});

  final String question;
  final String answer;

  factory KnowledgeFaq.fromJson(Map<String, dynamic> json) => KnowledgeFaq(
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}