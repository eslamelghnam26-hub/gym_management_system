import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/widgets/stat_card.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';

class ReceptionistDashboardScreen extends ConsumerWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(authControllerProvider).value;
    final attendanceResult = ref.watch(attendanceControllerProvider);
    final membersResult = ref.watch(membersControllerProvider);
    final paymentsResult = ref.watch(paymentsControllerProvider);

    final records = attendanceResult.value ?? const [];
    final members = membersResult.value ?? const <Member>[];
    final present = records.where((r) => r.isCheckedIn).length;
    final absent = members
        .where((m) => m.status == MemberStatus.active)
        .length - present;
    final now = DateTime.now();
    final todayRevenue = (paymentsResult.value ?? const <Payment>[])
        .where((p) =>
            p.status == PaymentStatus.paid &&
            p.createdAt.year == now.year &&
            p.createdAt.month == now.month &&
            p.createdAt.day == now.day)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final actions = [
      _Action(
        icon: Icons.add_card_outlined,
        color: AppColors.primary,
        label: strings.newPayment,
        route: '/payments/form',
      ),
      _Action(
        icon: Icons.event_repeat,
        color: AppColors.success,
        label: strings.newSubscription,
        route: '/subscriptions/form',
      ),
      _Action(
        icon: Icons.event_available_outlined,
        color: AppColors.accent,
        label: strings.titleAttendance,
        route: '/attendance',
      ),
      _Action(
        icon: Icons.person_add_outlined,
        color: AppColors.primaryBright,
        label: strings.titleMembers,
        route: '/members/form',
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(attendanceControllerProvider);
        ref.invalidate(paymentsControllerProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${strings.welcome} ${user?.name ?? ''} 👋',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.roleReceptionist,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.how_to_reg_outlined,
                  value: '$present',
                  label: strings.present,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.event_busy_outlined,
                  value: '$absent',
                  label: strings.absent,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatCard(
            icon: Icons.payments_outlined,
            value: Formatters.money(todayRevenue),
            label: strings.todayRevenue,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            strings.quickActions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(action.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action.icon, color: action.color, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Action {
  const _Action({
    required this.icon,
    required this.color,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String route;
}