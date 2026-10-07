import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/features/payments/presentation/payment_fields.dart';
import 'package:gym_management_system/features/payments/presentation/receipt_dialog.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/current_member_provider.dart';
import 'package:gym_management_system/providers/payment_gateway_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/services/payment/payment_gateway.dart';

class MySubscriptionScreen extends ConsumerWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final member = ref.watch(currentMemberProvider);
    final subsResult = ref.watch(subscriptionsControllerProvider);

    if (member == null) {
      return EmptyState(
        icon: Icons.person_off_outlined,
        title: strings.nothingHere,
      );
    }

    final subs = subsResult.value ?? const <Subscription>[];
    final mine = subs.where((s) => s.memberId == member.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final current = mine.isEmpty ? null : mine.first;

    return subsResult.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        retryLabel: strings.retry,
        onRetry: () => ref.invalidate(subscriptionsControllerProvider),
      ),
      data: (_) {
        if (current == null) {
          return EmptyState(
            icon: Icons.event_note_outlined,
            title: strings.noSubscriptionsForYou,
          );
        }
        final plan = ref
            .read(plansControllerProvider.notifier)
            .byId(current.planId);
        final active = current.status == SubscriptionStatus.active &&
            current.endDate.isAfter(DateTime.now());
        final daysLeft =
            current.endDate.difference(DateTime.now()).inDays.clamp(0, 9999);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan?.name ?? current.planId,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _StatusBadge(
                        status: current.status,
                        label: current.status == SubscriptionStatus.active
                            ? strings.statusActive
                            : strings.statusExpired,
                      ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: strings.startsOn, value: Formatters.date(current.startDate)),
                    _InfoRow(label: strings.expiresOn, value: Formatters.date(current.endDate)),
                    _InfoRow(
                      label: strings.remainingDays,
                      value: active ? '$daysLeft ${strings.days}' : strings.statusExpired,
                    ),
                    _InfoRow(label: strings.amount, value: Formatters.money(current.price)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!active)
              AppButton(
                label: strings.renewSubscription,
                icon: Icons.refresh,
                onPressed: active
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: _RenewSheet(subscription: current, planName: plan?.name),
                        ),
                      ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined,
                        color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.subActive,
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final SubscriptionStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = status == SubscriptionStatus.active
        ? AppColors.success
        : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RenewSheet extends ConsumerStatefulWidget {
  const _RenewSheet({required this.subscription, this.planName});

  final Subscription subscription;
  final String? planName;

  @override
  ConsumerState<_RenewSheet> createState() => _RenewSheetState();
}

class _RenewSheetState extends ConsumerState<_RenewSheet> {
  final _panelKey = GlobalKey<PaymentFieldsPanelState>();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final plan = ref
        .read(plansControllerProvider.notifier)
        .byId(widget.subscription.planId);
    final price = plan?.price ?? widget.subscription.price;
    final start = DateTime.now();
    final end = start.add(Duration(days: plan?.durationDays ?? 30));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${strings.renewSubscription} • ${widget.planName ?? widget.subscription.planId}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.amount}: ${Formatters.money(price)} • ${strings.myMembership} ${Formatters.date(start)} → ${Formatters.date(end)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          PaymentFieldsPanel(key: _panelKey),
          const SizedBox(height: 24),
          AppButton(
            label: _submitting ? strings.processing : strings.payNow,
            loading: _submitting,
            icon: Icons.lock_outline,
            onPressed: () => _submit(strings, price, start, end),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    AppStrings strings,
    double price,
    DateTime start,
    DateTime end,
  ) async {
    final panel = _panelKey.currentState;
    if (panel == null) return;
    final method = panel.selectedMethod;
    if (method == null) {
      _snack(strings.errorHint('required'));
      return;
    }
    final panelError = panel.validate();
    if (panelError != null) {
      _snack(strings.errorHint(panelError));
      return;
    }
    final request = PaymentRequest(
      amount: price,
      method: method,
      card: panel.cardDetails,
      walletPhone: panel.walletPhone,
      bankReference: panel.bankReference,
    );
    setState(() => _submitting = true);
    try {
      final receipt = await ref.read(paymentGatewayProvider).charge(request);
      final ok = receipt.status == PaymentStatus.paid ||
          receipt.status == PaymentStatus.pending;
      if (!mounted) return;
      if (!ok) {
        _snack(strings.errorMessage(receipt.message ?? 'unknown'));
        return;
      }
      final subId = await ref
          .read(subscriptionsControllerProvider.notifier)
          .add(Subscription(
            id: '',
            memberId: widget.subscription.memberId,
            planId: widget.subscription.planId,
            startDate: start,
            endDate: end,
            price: price,
            method: receipt.method.key,
            status: SubscriptionStatus.active,
          ));
      await ref.read(paymentsControllerProvider.notifier).add(Payment(
            id: '',
            memberId: widget.subscription.memberId,
            subscriptionId: subId,
            amount: price,
            method: receipt.method,
            status: receipt.status,
            reference: receipt.reference,
            note: '${strings.renewal} ${widget.subscription.planId}',
          ));
      if (!mounted) return;
      await showReceiptDialog(context, receipt: receipt, strings: strings);
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      final code = e is AppException ? e.code : 'unknown';
      _snack(strings.errorMessage(code));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.danger,
    ));
  }
}