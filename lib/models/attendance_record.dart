/// A single day attendance record: one member, one check-in, optional
/// check-out. `date` is normalized to yyyy-MM-dd for grouping.
class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.date,
    this.checkIn,
    this.checkOut,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String memberId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime createdAt;

  bool get isCheckedIn => checkIn != null;
  bool get isCheckedOut => checkOut != null;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String? ?? '',
        memberId: json['memberId'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        checkIn: DateTime.tryParse(json['checkIn'] as String? ?? ''),
        checkOut: DateTime.tryParse(json['checkOut'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'date': _dayKey(date),
        'checkIn': checkIn?.toIso8601String(),
        'checkOut': checkOut?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  static String dayKey(DateTime d) => _dayKey(d);

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}