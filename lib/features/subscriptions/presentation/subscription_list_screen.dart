import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/features/subscriptions/presentation/subscription_form_screen.dart'
    show SubscriptionFormArgs;

class SubscriptionListScreen extends ConsumerStatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  ConsumerState<SubscriptionListScreen> createState() =>
      _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends ConsumerState<SubscriptionListScreen> {
  SubscriptionStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final subsResult = ref.watch(subscriptionsControllerProvider);
    final membersResult = ref.watch(membersControllerProvider);
    final plansResult = ref.watch(plansControllerProvider);

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
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final status in SubscriptionStatus.values) ...[
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(strings.subStatusLabel(status)),
                  selected: _filter == status,
                  onSelected: (_) => setState(() => _filter = status),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: subsResult.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(subscriptionsControllerProvider),
            ),
            data: (subscriptions) {
              final memberMap = <String, Member>{
                for (final m in membersResult.value ?? const <Member>[]) m.id: m,
              };
              final planMap = <String, MembershipPlan>{
                for (final p in plansResult.value ?? const <MembershipPlan>[])
                  p.id: p,
              };
              final filtered = subscriptions
                  .where((s) => _filter == null || s.status == _filter)
                  .toList();
              if (filtered.isEmpty) {
                return const EmptyState(
                  icon: Icons.card_membership_outlined,
                  title: 'لا توجد اشتراكات',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sub = filtered[index];
                  final memberName =
                      memberMap[sub.memberId]?.fullName ?? sub.memberId;
                  final planName = planMap[sub.planId]?.name ?? sub.planId;
                  return _SubscriptionCard(
                    sub: sub,
                    strings: strings,
                    memberName: memberName,
                    planName: planName,
                    onRenew: () => context.push('/subscriptions/form',
                        extra: SubscriptionFormArgs(memberId: sub.memberId)),
                    onDelete: () => _delete(context, strings, sub),
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
    AppStrings strings,
    Subscription sub,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: strings.deleteConfirmTitle,
      message: strings.deleteConfirmBody,
      confirmLabel: strings.delete,
      cancelLabel: strings.cancel,
    );
    if (!confirmed) return;
    await ref.read(subscriptionsControllerProvider.notifier).delete(sub.id);
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.sub,
    required this.memberName,
    required this.planName,
    required this.onRenew,
    required this.onDelete,
    required this.strings,
  });

  final Subscription sub;
  final String memberName;
  final String planName;
  final VoidCallback onRenew;
  final VoidCallback onDelete;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expired = !sub.isActive;
    return Card(
      color: expired ? theme.colorScheme.surfaceContainerHighest : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                memberName.isNotEmpty ? memberName[0] : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    planName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.money(sub.price)} • ${strings.subStatusLabel(sub.status)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${strings.expiresOn} ${Formatters.date(sub.endDate)} • ${sub.remainingDays} ${strings.days}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: strings.renewal,
              onPressed: onRenew,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: strings.delete,
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}