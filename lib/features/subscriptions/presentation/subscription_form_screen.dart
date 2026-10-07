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
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payment_gateway_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/services/payment/payment_gateway.dart';

class SubscriptionFormArgs {
  const SubscriptionFormArgs({this.memberId, this.memberName});

  final String? memberId;
  final String? memberName;
}

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key, required this.args});

  final SubscriptionFormArgs args;

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _memberId;
  String? _planId;
  DateTime _startDate = DateTime.now();
  late final TextEditingController _amountController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _memberId = widget.args.memberId;
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  DateTime get _endDate {
    final plan = _planId == null
        ? null
        : ref.read(plansControllerProvider.notifier).byId(_planId!);
    if (plan == null) return _startDate;
    return _startDate.add(Duration(days: plan.durationDays));
  }

  double get _effectiveAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: ref.read(appStringsProvider).startDate,
    );
    if (picked != null) setState(() => _startDate = picked);
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
    final request = PaymentRequest(
      amount: _effectiveAmount,
      method: method,
      card: panel.cardDetails,
      walletPhone: panel.walletPhone,
      bankReference: panel.bankReference,
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
      final subId = await ref
          .read(subscriptionsControllerProvider.notifier)
          .add(Subscription(
            id: '',
            memberId: _memberId!,
            planId: _planId!,
            startDate: _startDate,
            endDate: _endDate,
            price: _effectiveAmount,
            method: receipt.method.key,
            status: SubscriptionStatus.active,
          ));
      await ref.read(paymentsControllerProvider.notifier).add(Payment(
            id: '',
            memberId: _memberId!,
            subscriptionId: subId,
            amount: _effectiveAmount,
            method: receipt.method,
            status: receipt.status,
            reference: receipt.reference,
            note: _paymentNote(receipt),
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

  String _paymentNote(PaymentReceipt receipt) {
    if (receipt.cardLast4 != null) {
      return 'بطاقة •••• ${receipt.cardLast4}';
    }
    if (receipt.method == PaymentMethod.wallet) {
      return 'محفظة ${_panelKey.currentState?.walletPhone ?? ''}';
    }
    if (receipt.method == PaymentMethod.bankTransfer) {
      return 'تحويل ${_panelKey.currentState?.bankReference ?? ''}';
    }
    return 'كاش';
  }

  final _panelKey = GlobalKey<PaymentFieldsPanelState>();

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final membersResult = ref.watch(membersControllerProvider);
    final plansResult = ref.watch(plansControllerProvider);
    final members = membersResult.value ?? const <Member>[];
    final plans = plansResult.value ?? const <MembershipPlan>[];
    final selectedPlan = _planId == null
        ? null
        : plans.where((p) => p.id == _planId).isEmpty
            ? null
            : plans.firstWhere((p) => p.id == _planId);

    return Scaffold(
      appBar: AppBar(title: Text(strings.newSubscription)),
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
                    const SizedBox(height: 16),
                    Text(strings.choosePlan,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _planId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.card_membership_outlined),
                      ),
                      items: [
                        for (final p in plans)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} — ${Formatters.money(p.price)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _planId = v;
                          final match = plans.where((p) => p.id == v);
                          if (match.isNotEmpty) {
                            final plan = match.first;
                            _amountController.text =
                                plan.price == plan.price.roundToDouble()
                                    ? '${plan.price.toInt()}'
                                    : '${plan.price}';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedPlan != null)
                      Text(
                        '${strings.planDuration}: ${selectedPlan.durationDays} ${strings.days}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TapPicker(
                            label: strings.startDate,
                            value: Formatters.date(_startDate),
                            onTap: _pickStart,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TapPicker(
                            label: strings.endDate,
                            value: Formatters.date(_endDate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _amountController,
                      label: strings.amount,
                      hint: strings.amount,
                      prefixIcon: Icons.payments_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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

class _TapPicker extends StatelessWidget {
  const _TapPicker({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
          ),
          child: Text(value),
        ),
      ),
    );
  }
}