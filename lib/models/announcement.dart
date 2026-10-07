enum AnnouncementAudience {
  all('all'),
  members('members'),
  trainers('trainers');

  const AnnouncementAudience(this.key);

  final String key;

  static AnnouncementAudience fromKey(String? key) => AnnouncementAudience.values
      .firstWhere((a) => a.key == key, orElse: () => AnnouncementAudience.all);
}

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.audience = AnnouncementAudience.all,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String body;
  final AnnouncementAudience audience;
  final DateTime createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        audience: AnnouncementAudience.fromKey(json['audience'] as String?),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'audience': audience.key,
        'createdAt': createdAt.toIso8601String(),
      };

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    AnnouncementAudience? audience,
  }) =>
      Announcement(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        audience: audience ?? this.audience,
        createdAt: createdAt,
      );
}