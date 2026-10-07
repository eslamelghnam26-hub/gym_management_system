import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/widgets/stat_card.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/providers/expenses_provider.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final expensesResult = ref.watch(expensesControllerProvider);
    final expenses = expensesResult.value ?? const <Expense>[];
    final now = DateTime.now();
    final thisMonth = expenses
        .where((e) =>
            e.date.year == now.year && e.date.month == now.month)
        .toList();
    final monthTotal =
        thisMonth.fold<double>(0, (sum, e) => sum + e.amount);
    final sorted = [...expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.savings_outlined,
                  value: Formatters.money(monthTotal),
                  label: strings.thisMonth,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.receipt_long_outlined,
                  value: '${expenses.length}',
                  label: strings.paymentCount,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: expensesResult.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(expensesControllerProvider),
            ),
            data: (_) {
              if (sorted.isEmpty) {
                return EmptyState(
                  icon: Icons.savings_outlined,
                  title: strings.noExpenses,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                itemCount: sorted.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final expense = sorted[index];
                  return _ExpenseCard(
                    expense: expense,
                    strings: strings,
                    onDelete: () => _delete(context, ref, strings, expense),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    Expense expense,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: strings.deleteConfirmTitle,
      message: strings.deleteConfirmBody,
      confirmLabel: strings.delete,
      cancelLabel: strings.cancel,
    );
    if (!confirmed) return;
    await ref.read(expensesControllerProvider.notifier).delete(expense.id);
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.strings,
    required this.onDelete,
  });

  final Expense expense;
  final AppStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.errorContainer,
          child: Icon(
            switch (expense.category) {
              ExpenseCategory.salary => Icons.payments_outlined,
              ExpenseCategory.rent => Icons.home_outlined,
              ExpenseCategory.equipment => Icons.fitness_center_outlined,
              ExpenseCategory.utilities => Icons.bolt_outlined,
              ExpenseCategory.other => Icons.more_horiz,
            },
            color: theme.colorScheme.error,
          ),
        ),
        title: Text(expense.note?.isNotEmpty == true
            ? expense.note!
            : strings.expenseCategoryLabel(expense.category)),
        subtitle: Text(
          '${strings.expenseCategoryLabel(expense.category)} • ${Formatters.date(expense.date)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '- ${Formatters.money(expense.amount)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: strings.delete,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}