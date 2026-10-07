import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/services/payment/demo_payment_gateway.dart';
import 'package:gym_management_system/services/payment/payment_gateway.dart';

/// Swap this with a real gateway (Paymob / Fawry / Stripe) for production;
/// the checkout UI reads from this single provider.
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return DemoPaymentGateway();
});