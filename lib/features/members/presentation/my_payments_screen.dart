import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/widgets/stat_card.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/features/payments/presentation/payment_fields.dart'
    show paymentMethodIcon;
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/providers/current_member_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';

class MyPaymentsScreen extends ConsumerWidget {
  const MyPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final member = ref.watch(currentMemberProvider);
    final result = ref.watch(paymentsControllerProvider);

    if (member == null) {
      return EmptyState(
        icon: Icons.person_off_outlined,
        title: strings.nothingHere,
      );
    }

    final mine = (result.value ?? const <Payment>[])
        .where((p) => p.memberId == member.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final total = mine.fold<double>(0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.payments_outlined,
                  value: Formatters.money(total),
                  label: strings.totalRevenue,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.receipt_long_outlined,
                  value: '${mine.length}',
                  label: strings.paymentCount,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: result.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(paymentsControllerProvider),
            ),
            data: (_) {
              if (mine.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: strings.noPayments,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: mine.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final payment = mine[index];
                  final color = switch (payment.status) {
                    PaymentStatus.paid => AppColors.success,
                    PaymentStatus.pending => AppColors.accent,
                    PaymentStatus.refunded =>
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    PaymentStatus.failed => AppColors.danger,
                  };
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          paymentMethodIcon(payment.method),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        '${strings.paymentMethodLabel(payment.method)} • ${strings.paymentStatusLabel(payment.status)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.dateTime(payment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (payment.note != null)
                            Text(
                              payment.note!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (payment.reference != null)
                            Text(
                              '${strings.reference}: ${payment.reference!}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        Formatters.money(payment.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}