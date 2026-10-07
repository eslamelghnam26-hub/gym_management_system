/// Roles drive Role-Based Access Control and role-based routing.
enum UserRole {
  admin('admin', 'مدير', 'Admin'),
  receptionist('receptionist', 'استقبال', 'Receptionist'),
  trainer('trainer', 'مدرب', 'Trainer'),
  member('member', 'عضو', 'Member');

  const UserRole(this.key, this.labelAr, this.labelEn);

  final String key;
  final String labelAr;
  final String labelEn;

  static UserRole fromKey(String? key) =>
      UserRole.values.firstWhere((r) => r.key == key, orElse: () => UserRole.member);
}

class AppUser {
  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    this.role = UserRole.member,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.length <= 1
          ? parts.first.toUpperCase()
          : parts.first.substring(0, 2).toUpperCase();
    }
    return parts.first[0].toUpperCase() + parts.last[0].toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? 'User',
        phone: json['phone'] as String?,
        photoUrl: json['photoUrl'] as String?,
        role: UserRole.fromKey(json['role'] as String?),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'role': role.key,
        'createdAt': createdAt.toIso8601String(),
      };

  AppUser copyWith({String? name, String? phone, String? photoUrl, UserRole? role}) =>
      AppUser(
        uid: uid,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        createdAt: createdAt,
      );
}