enum ExpenseCategory {
  salary('salary'),
  rent('rent'),
  equipment('equipment'),
  utilities('utilities'),
  other('other');

  const ExpenseCategory(this.key);

  final String key;

  static ExpenseCategory fromKey(String? key) => ExpenseCategory.values
      .firstWhere((c) => c.key == key, orElse: () => ExpenseCategory.other);
}

class Expense {
  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String? ?? '',
        category: ExpenseCategory.fromKey(json['category'] as String?),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        note: json['note'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.key,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  Expense copyWith({
    String? id,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? note,
  }) =>
      Expense(
        id: id ?? this.id,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}