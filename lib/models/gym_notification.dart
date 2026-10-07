/// In-app notification pushed to the mobile app. `target` is either the
/// reserved string `all` (everyone) or a specific user uid.
class GymNotification {
  GymNotification({
    this.id = '',
    required this.title,
    required this.body,
    this.target = 'all',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String body;
  final String target;
  final DateTime createdAt;

  factory GymNotification.fromJson(Map<String, dynamic> json) => GymNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        target: json['target'] as String? ?? 'all',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'target': target,
        'createdAt': createdAt.toIso8601String(),
      };

  GymNotification copyWith({String? id}) =>
      GymNotification(id: id ?? this.id, title: title, body: body, target: target, createdAt: createdAt);
}