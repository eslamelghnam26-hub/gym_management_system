import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/services/payment/payment_gateway.dart';

IconData paymentMethodIcon(PaymentMethod method) => switch (method) {
      PaymentMethod.cash => Icons.payments_outlined,
      PaymentMethod.card => Icons.credit_card,
      PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
      PaymentMethod.bankTransfer => Icons.account_balance_outlined,
    };

/// Method selector + method-specific capture fields (card / wallet / bank).
/// Exposes validated data for the gateway.
class PaymentFieldsPanel extends ConsumerStatefulWidget {
  const PaymentFieldsPanel({super.key, this.preselected});

  final PaymentMethod? preselected;

  @override
  ConsumerState<PaymentFieldsPanel> createState() => PaymentFieldsPanelState();
}

class PaymentFieldsPanelState extends ConsumerState<PaymentFieldsPanel> {
  late PaymentMethod? _method = widget.preselected;
  final _cardNumber = TextEditingController();
  final _cardHolder = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();
  final _walletPhone = TextEditingController();
  final _bankReference = TextEditingController();

  PaymentMethod? get selectedMethod => _method;

  CardDetails? get cardDetails {
    if (_method != PaymentMethod.card) return null;
    return CardDetails(
      number: _cardNumber.text.trim(),
      holder: _cardHolder.text.trim(),
      expiry: _cardExpiry.text.trim(),
      cvv: _cardCvv.text.trim(),
    );
  }

  String? get walletPhone =>
      _method == PaymentMethod.wallet ? _walletPhone.text.trim() : null;

  String? get bankReference =>
      _method == PaymentMethod.bankTransfer ? _bankReference.text.trim() : null;

  /// Returns an error code, or null when the method's fields are valid.
  String? validate() {
    if (_method == null) return 'required';
    switch (_method!) {
      case PaymentMethod.card:
        if (_cardNumber.text.trim().isEmpty) return 'required';
        if (_cardHolder.text.trim().isEmpty) return 'required';
        if (_cardExpiry.text.trim().isEmpty) return 'required';
        if (_cardCvv.text.trim().isEmpty) return 'required';
      case PaymentMethod.wallet:
        if (_walletPhone.text.trim().isEmpty) return 'required';
      case PaymentMethod.bankTransfer:
        if (_bankReference.text.trim().isEmpty) return 'required';
      case PaymentMethod.cash:
        break;
    }
    return null;
  }

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardHolder.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    _walletPhone.dispose();
    _bankReference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.paymentMethod,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in PaymentMethod.values)
              ChoiceChip(
                avatar: Icon(paymentMethodIcon(m), size: 18),
                label: Text(strings.paymentMethodLabel(m)),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
              ),
          ],
        ),
        if (_method == PaymentMethod.card) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _cardNumber,
            label: strings.cardNumber,
            hint: '4242 4242 4242 4242',
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
          ),
          AppTextField(
            controller: _cardHolder,
            label: strings.cardHolder,
            hint: 'AHMED MOHAMED',
            prefixIcon: Icons.person_outline,
          ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _cardExpiry,
                  label: strings.cardExpiry,
                  hint: '12/27',
                  prefixIcon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _cardCvv,
                  label: strings.cardCvv,
                  hint: '123',
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
        if (_method == PaymentMethod.wallet) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _walletPhone,
            label: strings.walletPhone,
            hint: '01011112223',
            prefixIcon: Icons.phone_iphone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
        if (_method == PaymentMethod.bankTransfer) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _bankReference,
            label: strings.bankReference,
            hint: 'TRX-93712',
            prefixIcon: Icons.numbers_outlined,
          ),
        ],
      ],
    );
  }
}