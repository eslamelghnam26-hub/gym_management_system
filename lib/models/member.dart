/// Subscription lifecycle of a member.
enum MemberStatus {
  active('active', 'نشط', 'Active'),
  expired('expired', 'منتهي', 'Expired'),
  pending('pending', 'معلق', 'Pending'),
  cancelled('cancelled', 'ملغي', 'Cancelled');

  const MemberStatus(this.key, this.labelAr, this.labelEn);

  final String key;
  final String labelAr;
  final String labelEn;

  static MemberStatus fromKey(String? key) => MemberStatus.values.firstWhere(
        (s) => s.key == key,
        orElse: () => MemberStatus.pending,
      );
}

/// A gym member profile. `trainerId` / `planId` reference records owned by the
/// Trainers and Membership Plans modules; names are resolved in the UI layer.
class Member {
  Member({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.profileImageUrl,
    this.emergencyContact,
    this.notes,
    this.trainerId,
    this.planId,
    required this.startDate,
    required this.endDate,
    this.status = MemberStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? profileImageUrl;
  final String? emergencyContact;
  final String? notes;
  final String? trainerId;
  final String? planId;
  final DateTime startDate;
  final DateTime endDate;
  final MemberStatus status;
  final DateTime createdAt;

  int get remainingDays => endDate.difference(DateTime.now()).inDays;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? ''),
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        emergencyContact: json['emergencyContact'] as String?,
        notes: json['notes'] as String?,
        trainerId: json['trainerId'] as String?,
        planId: json['planId'] as String?,
        startDate: DateTime.tryParse(json['startDate'] as String? ?? '')
            ?.toLocal() ??
            DateTime.now(),
        endDate: DateTime.tryParse(json['endDate'] as String? ?? '')
                ?.toLocal() ??
            DateTime.now(),
        status: MemberStatus.fromKey(json['status'] as String?),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'address': address,
        'profileImageUrl': profileImageUrl,
        'emergencyContact': emergencyContact,
        'notes': notes,
        'trainerId': trainerId,
        'planId': planId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': status.key,
        'createdAt': createdAt.toIso8601String(),
      };

  Member copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? profileImageUrl,
    String? emergencyContact,
    String? notes,
    String? trainerId,
    String? planId,
    DateTime? startDate,
    DateTime? endDate,
    MemberStatus? status,
  }) =>
      Member(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        address: address ?? this.address,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        emergencyContact: emergencyContact ?? this.emergencyContact,
        notes: notes ?? this.notes,
        trainerId: trainerId ?? this.trainerId,
        planId: planId ?? this.planId,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}