import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/features/payments/presentation/payment_fields.dart';
import 'package:gym_management_system/features/payments/presentation/receipt_dialog.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payment_gateway_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/services/payment/payment_gateway.dart';

class PaymentFormArgs {
  const PaymentFormArgs({this.memberId, this.memberName});

  final String? memberId;
  final String? memberName;
}

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key, required this.args});

  final PaymentFormArgs args;

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panelKey = GlobalKey<PaymentFieldsPanelState>();
  String? _memberId;
  String? _subscriptionId;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _memberId = widget.args.memberId;
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    if (!_formKey.currentState!.validate()) return;
    if (_memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.errorHint('required')),
          backgroundColor: AppColors.danger));
      return;
    }
    final panel = _panelKey.currentState;
    if (panel == null) return;
    final method = panel.selectedMethod;
    if (method == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.errorHint('required')),
          backgroundColor: AppColors.danger));
      return;
    }
    final panelError = panel.validate();
    if (panelError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.errorHint(panelError)),
          backgroundColor: AppColors.danger));
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final request = PaymentRequest(
      amount: amount,
      method: method,
      card: panel.cardDetails,
      walletPhone: panel.walletPhone,
      bankReference: panel.bankReference,
      description: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    setState(() => _submitting = true);
    try {
      final receipt = await ref.read(paymentGatewayProvider).charge(request);
      final succeeded =
          receipt.status == PaymentStatus.paid || receipt.status == PaymentStatus.pending;
      if (!mounted) return;
      if (!succeeded) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(strings.errorMessage(receipt.message ?? 'unknown')),
            backgroundColor: AppColors.danger));
        return;
      }
      await ref.read(paymentsControllerProvider.notifier).add(Payment(
            id: '',
            memberId: _memberId!,
            subscriptionId: _subscriptionId,
            amount: amount,
            method: receipt.method,
            status: receipt.status,
            reference: receipt.reference,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ));
      if (!mounted) return;
      await showReceiptDialog(context, receipt: receipt, strings: strings);
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      final code = e is AppException ? e.code : 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.errorMessage(code)),
          backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final membersResult = ref.watch(membersControllerProvider);
    final subsResult = ref.watch(subscriptionsControllerProvider);
    final members = membersResult.value ?? const <Member>[];
    final memberSubs = _memberId == null
        ? const <Subscription>[]
        : subsResult.value
            ?.where((s) => s.memberId == _memberId)
            .toList() ??
            const <Subscription>[];

    return Scaffold(
      appBar: AppBar(title: Text(strings.newPayment)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(strings.chooseMember,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _memberId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        for (final m in members)
                          DropdownMenuItem(
                            value: m.id,
                            child: Text(m.fullName,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: widget.args.memberId == null
                          ? (v) => setState(() => _memberId = v)
                          : null,
                    ),
                    if (memberSubs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(strings.newSubscription,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _subscriptionId,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(strings.noLink,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ),
                          for (final s in memberSubs)
                            DropdownMenuItem(
                              value: s.id,
                              child:
                                  Text('${s.planId} — ${Formatters.date(s.endDate)}'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _subscriptionId = v),
                      ),
                    ],
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _amountController,
                      label: strings.amount,
                      hint: strings.amount,
                      prefixIcon: Icons.payments_outlined,
                      validator: (value) =>
                          (double.tryParse(value?.trim() ?? '') ?? 0) <= 0
                              ? 'required'
                              : null,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _noteController,
                      label: strings.notes,
                      hint: strings.notes,
                      prefixIcon: Icons.notes,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    PaymentFieldsPanel(key: _panelKey),
                    const SizedBox(height: 24),
                    AppButton(
                      label: _submitting
                          ? strings.processing
                          : strings.payNow,
                      loading: _submitting,
                      onPressed: _submit,
                      icon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}