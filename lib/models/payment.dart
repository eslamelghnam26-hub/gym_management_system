enum PaymentMethod {
  cash('cash'),
  card('card'),
  wallet('wallet'),
  bankTransfer('bank_transfer');

  const PaymentMethod(this.key);

  final String key;

  static PaymentMethod fromKey(String? key) => PaymentMethod.values
      .firstWhere((m) => m.key == key, orElse: () => PaymentMethod.cash);
}

enum PaymentStatus {
  paid('paid'),
  pending('pending'),
  refunded('refunded'),
  failed('failed');

  const PaymentStatus(this.key);

  final String key;

  static PaymentStatus fromKey(String? key) => PaymentStatus.values
      .firstWhere((s) => s.key == key, orElse: () => PaymentStatus.pending);
}

/// A payment record linked to a member and (optionally) a subscription.
/// `method` + the gateway receipt reference make every payment auditable.
class Payment {
  Payment({
    required this.id,
    required this.memberId,
    this.subscriptionId,
    required this.amount,
    required this.method,
    this.status = PaymentStatus.paid,
    this.reference,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String memberId;
  final String? subscriptionId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final String? note;
  final DateTime createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String? ?? '',
        memberId: json['memberId'] as String? ?? '',
        subscriptionId: json['subscriptionId'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        method: PaymentMethod.fromKey(json['method'] as String?),
        status: PaymentStatus.fromKey(json['status'] as String?),
        reference: json['reference'] as String?,
        note: json['note'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'subscriptionId': subscriptionId,
        'amount': amount,
        'method': method.key,
        'status': status.key,
        'reference': reference,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  Payment copyWith({
    String? id,
    String? subscriptionId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? reference,
    String? note,
  }) =>
      Payment(
        id: id ?? this.id,
        memberId: memberId,
        subscriptionId: subscriptionId ?? this.subscriptionId,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        status: status ?? this.status,
        reference: reference ?? this.reference,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}