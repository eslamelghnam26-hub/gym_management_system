import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/features/subscriptions/presentation/subscription_form_screen.dart'
    show SubscriptionFormArgs;
import 'package:gym_management_system/providers/current_member_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final member = ref.watch(currentMemberProvider);
    final subsResult = ref.watch(subscriptionsControllerProvider);
    final plansResult = ref.watch(plansControllerProvider);

    final subs = subsResult.value ?? const <Subscription>[];
    final mine = subs.where((s) => s.memberId == (member?.id ?? '')).toList();
    final current = mine.isEmpty
        ? null
        : mine.reduce((a, b) => b.createdAt.isAfter(a.createdAt) ? b : a);
    final active = current != null &&
        current.status == SubscriptionStatus.active &&
        current.endDate.isAfter(DateTime.now());
    MembershipPlan? plan;
    if (current != null) {
      final list = plansResult.value;
      if (list != null) {
        for (final p in list) {
          if (p.id == current.planId) {
            plan = p;
            break;
          }
        }
      }
    }

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
                        plan?.name ??
                            (current == null
                                ? strings.noSubscriptions
                                : current.planId),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        active ? strings.statusActive : strings.statusExpired,
                        style: TextStyle(
                          color: active ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CardRow(label: strings.membershipStatus,
                    value: active ? strings.statusActive : strings.statusExpired),
                _CardRow(
                  label: strings.currentPlan,
                  value: plan?.name ?? (current?.planId ?? strings.noSubscriptions),
                ),
                if (current != null) ...[
                  _CardRow(
                    label: strings.remainingDays,
                    value: active
                        ? '${current.endDate.difference(DateTime.now()).inDays.clamp(0, 9999)} ${strings.days}'
                        : strings.statusExpired,
                  ),
                  _CardRow(
                    label: strings.endDate,
                    value: Formatters.date(current.endDate),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          strings.quickAccess,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final items = _quickLinks(strings);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _QuickLinkCard(
                  icon: item.icon,
                  label: item.label,
                  color: item.color,
                  onTap: () => context.push(item.route),
                );
              },
            );
          },
        ),
        if (!active && member != null) ...[
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.notification_important_outlined),
              title: Text(strings.noSubscriptionsForYou),
              trailing: FilledButton(
                onPressed: () => context.push(
                  '/subscriptions/form',
                  extra:
                      SubscriptionFormArgs(memberId: member.id),
                ),
                child: Text(strings.renewSubscription),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<_QuickLink> _quickLinks(AppStrings strings) => [
        _QuickLink(
          Icons.card_membership_outlined,
          strings.myMembership,
          AppColors.primary,
          '/my/subscription',
        ),
        _QuickLink(
          Icons.receipt_long_outlined,
          strings.myPayments,
          AppColors.success,
          '/my/payments',
        ),
        _QuickLink(
          Icons.event_available_outlined,
          strings.myAttendance,
          AppColors.accent,
          '/my/attendance',
        ),
        _QuickLink(
          Icons.storefront_outlined,
          strings.gymInfo,
          AppColors.primaryBright,
          '/gym-info',
        ),
      ];
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
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

class _QuickLink {
  const _QuickLink(this.icon, this.label, this.color, this.route);

  final IconData icon;
  final String label;
  final Color color;
  final String route;
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}