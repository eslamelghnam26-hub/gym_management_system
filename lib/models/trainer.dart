class Trainer {
  Trainer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.specialization,
    this.salary = 0,
    this.schedule,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? specialization;
  final double salary;
  final String? schedule;
  final DateTime createdAt;

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        specialization: json['specialization'] as String?,
        salary: (json['salary'] as num?)?.toDouble() ?? 0,
        schedule: json['schedule'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'specialization': specialization,
        'salary': salary,
        'schedule': schedule,
        'createdAt': createdAt.toIso8601String(),
      };

  Trainer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? specialization,
    double? salary,
    String? schedule,
  }) =>
      Trainer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        specialization: specialization ?? this.specialization,
        salary: salary ?? this.salary,
        schedule: schedule ?? this.schedule,
        createdAt: createdAt,
      );
}