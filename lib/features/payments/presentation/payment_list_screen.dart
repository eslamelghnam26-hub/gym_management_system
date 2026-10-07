import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/features/payments/presentation/payment_fields.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  PaymentMethod? _methodFilter;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final paymentsResult = ref.watch(paymentsControllerProvider);
    final membersResult = ref.watch(membersControllerProvider);

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            children: [
              FilterChip(
                label: Text(strings.all),
                selected: _methodFilter == null,
                onSelected: (_) => setState(() => _methodFilter = null),
              ),
              for (final m in PaymentMethod.values) ...[
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(paymentMethodIcon(m), size: 16),
                  label: Text(strings.paymentMethodLabel(m)),
                  selected: _methodFilter == m,
                  onSelected: (_) => setState(() => _methodFilter = m),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: paymentsResult.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(paymentsControllerProvider),
            ),
            data: (payments) {
              final memberMap = <String, Member>{
                for (final m in membersResult.value ?? const <Member>[]) m.id: m,
              };
              final filtered = payments
                  .where((p) =>
                      _methodFilter == null || p.method == _methodFilter)
                  .toList();
              if (filtered.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'لا توجد مدفوعات',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final payment = filtered[index];
                  final member =
                      memberMap[payment.memberId]?.fullName ?? payment.memberId;
                  return _PaymentCard(
                    payment: payment,
                    memberName: member,
                    strings: strings,
                    onRefund: () => _refund(context, strings, payment),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _refund(
    BuildContext context,
    AppStrings strings,
    Payment payment,
  ) async {
    if (payment.status == PaymentStatus.refunded) return;
    final confirmed = await confirmAction(
      context,
      title: strings.markRefunded,
      message: strings.deleteConfirmBody,
      confirmLabel: strings.confirm,
      cancelLabel: strings.cancel,
    );
    if (!confirmed) return;
    await ref.read(paymentsControllerProvider.notifier).refund(payment.id);
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.memberName,
    required this.strings,
    required this.onRefund,
  });

  final Payment payment;
  final String memberName;
  final AppStrings strings;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (payment.status) {
      PaymentStatus.paid => AppColors.success,
      PaymentStatus.pending => AppColors.accent,
      PaymentStatus.refunded => theme.colorScheme.onSurfaceVariant,
      PaymentStatus.failed => AppColors.danger,
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(paymentMethodIcon(payment.method),
              color: theme.colorScheme.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                memberName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              Formatters.money(payment.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${strings.paymentMethodLabel(payment.method)} • ${Formatters.dateTime(payment.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (payment.reference != null)
              Text(
                '${strings.reference}: ${payment.reference!}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: payment.status != PaymentStatus.refunded
            ? IconButton(
                tooltip: strings.markRefunded,
                onPressed: onRefund,
                icon: const Icon(Icons.replay),
              )
            : null,
      ),
    );
  }
}