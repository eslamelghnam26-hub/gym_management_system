import 'package:gym_management_system/models/payment.dart';

/// Card data collected from the checkout UI. Never persisted anywhere in the
/// demo build — only the last 4 digits and the receipt reference are stored.
class CardDetails {
  const CardDetails({
    required this.number,
    required this.holder,
    required this.expiry,
    required this.cvv,
  });

  final String number;
  final String holder;

  /// Format "MM/YY".
  final String expiry;
  final String cvv;

  String get last4 {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 4) return '••••';
    return digits.substring(digits.length - 4);
  }
}

class PaymentRequest {
  const PaymentRequest({
    required this.amount,
    required this.method,
    this.card,
    this.walletPhone,
    this.bankReference,
    this.description,
  });

  final double amount;
  final PaymentMethod method;
  final CardDetails? card;
  final String? walletPhone;
  final String? bankReference;
  final String? description;
}

class PaymentReceipt {
  const PaymentReceipt({
    required this.reference,
    required this.amount,
    required this.method,
    required this.status,
    this.cardLast4,
    this.message,
  });

  final String reference;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? cardLast4;
  final String? message;
}

/// Gateway abstraction so the same checkout flow works for cash, bank
/// transfer, mobile wallets and card payments. Duplicating this interface
/// with a real provider (Paymob / Stripe / Fawry) only needs a new
/// implementation + swapping [paymentGatewayProvider] — no UI changes.
abstract class PaymentGateway {
  Future<PaymentReceipt> charge(PaymentRequest request);
}