import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/services/payment/payment_gateway.dart';

/// Offline payment simulator so the portfolio app demonstrates the *full*
/// checkout UX (cash / card / mobile wallet / bank transfer) without a
/// gateway account. Card validation mirrors a real acquirer:
/// - 13–16 digits, valid Luhn checksum
/// - expiry in the future
/// - 3–4 digit CVC
/// and a test "decline" trigger for cards whose last digit is `0` so the
/// failure path is visible too.
///
/// Swap this provider for a real gateway (Paymob/Fawry/Stripe via the web
/// backend) when production keys are available — the UI stays identical.
class DemoPaymentGateway implements PaymentGateway {
  DemoPaymentGateway({this.delay = const Duration(milliseconds: 1200)});

  final Duration delay;

  static const String declineCardsEndingIn = '0';

  @override
  Future<PaymentReceipt> charge(PaymentRequest request) async {
    await Future<void>.delayed(delay);
    final reference = _reference();
    switch (request.method) {
      case PaymentMethod.cash:
      case PaymentMethod.bankTransfer:
      case PaymentMethod.wallet:
        return PaymentReceipt(
          reference: reference,
          amount: request.amount,
          method: request.method,
          status: PaymentStatus.paid,
          message: 'approved',
        );
      case PaymentMethod.card:
        return _chargeCard(request, reference);
    }
  }

  PaymentReceipt _chargeCard(PaymentRequest request, String reference) {
    final card = request.card;
    if (card == null) {
      return PaymentReceipt(
        reference: reference,
        amount: request.amount,
        method: request.method,
        status: PaymentStatus.failed,
        message: 'card_incomplete',
      );
    }
    final digits = card.number.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 13 || digits.length > 16) {
      return _decline(request, reference, 'card_invalid_number');
    }
    if (!_luhn(digits)) {
      return _decline(request, reference, 'card_invalid_number');
    }
    if (!_validExpiry(card.expiry)) {
      return _decline(request, reference, 'card_expired');
    }
    final cvv = card.cvv.trim();
    if (cvv.length < 3 || cvv.length > 4 || !RegExp(r'^\d+$').hasMatch(cvv)) {
      return _decline(request, reference, 'card_invalid_cvv');
    }
    if (digits.endsWith(declineCardsEndingIn)) {
      return _decline(request, reference, 'card_declined');
    }
    return PaymentReceipt(
      reference: reference,
      amount: request.amount,
      method: request.method,
      status: PaymentStatus.paid,
      cardLast4: card.last4,
      message: 'approved',
    );
  }

  PaymentReceipt _decline(
    PaymentRequest request,
    String reference,
    String message,
  ) =>
      PaymentReceipt(
        reference: reference,
        amount: request.amount,
        method: request.method,
        status: PaymentStatus.failed,
        message: message,
      );

  bool _luhn(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  bool _validExpiry(String expiry) {
    final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(expiry.trim());
    if (match == null) return false;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final now = DateTime.now();
    return year > now.year || (year == now.year && month >= now.month);
  }

  String _reference() =>
      'DEMO-${DateTime.now().millisecondsSinceEpoch.toString()}';
}