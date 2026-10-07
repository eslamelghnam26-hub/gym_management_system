import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/widgets/stat_card.dart';
import 'package:gym_management_system/features/dashboard/data/admin_stats.dart';
import 'package:gym_management_system/features/payments/presentation/payment_fields.dart'
    show paymentMethodIcon;
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/providers/dashboard_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(authControllerProvider).value;
    final statsResult = ref.watch(adminStatsProvider);
    final paymentsResult = ref.watch(paymentsControllerProvider);
    final membersResult = ref.watch(membersControllerProvider);

    final memberMap = <String, Member>{
      for (final m in membersResult.value ?? const <Member>[]) m.id: m,
    };
    final recent = [...(paymentsResult.value ?? const <Payment>[])]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminStatsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${strings.welcome} 👋',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.invalidate(adminStatsProvider);
                  ref.invalidate(paymentsControllerProvider);
                },
                icon: const Icon(Icons.refresh),
                label: Text(strings.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          statsResult.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: AppLoadingView(),
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(adminStatsProvider),
            ),
            data: (stats) => _StatsGrid(stats: stats),
          ),
          const SizedBox(height: 24),
          Text(
            strings.managementModules,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _ModulesGrid(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.recentPayments,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/payments'),
                child: Text(strings.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (recent.isEmpty)
            Text(
              strings.noPayments,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final payment in recent.take(5))
              _PaymentTile(
                payment: payment,
                memberName:
                    memberMap[payment.memberId]?.fullName ?? payment.memberId,
                strings: strings,
              ),
        ],
      ),
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 700
                  ? 3
                  : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 178,
          children: [
            StatCard(
              icon: Icons.people_outline,
              value: '${stats.totalMembers}',
              label: strings.totalMembers,
            ),
            StatCard(
              icon: Icons.check_circle_outline,
              value: '${stats.activeMembers}',
              label: strings.activeMembers,
              color: AppColors.success,
            ),
            StatCard(
              icon: Icons.block_outlined,
              value: '${stats.expiredSubscriptions}',
              label: strings.expiredSubscriptions,
              color: AppColors.danger,
            ),
            StatCard(
              icon: Icons.warning_amber_outlined,
              value: '${stats.expiringSoonSubscriptions}',
              label: strings.expiringSoonSubscriptions,
              color: AppColors.accent,
            ),
            StatCard(
              icon: Icons.how_to_reg_outlined,
              value: '${stats.todayAttendance}',
              label: strings.todayAttendance,
              color: AppColors.accent,
            ),
            StatCard(
              icon: Icons.payments_outlined,
              value: Formatters.money(stats.totalRevenue),
              label: strings.totalRevenue,
              color: AppColors.primaryBright,
            ),
            StatCard(
              icon: Icons.receipt_long_outlined,
              value: Formatters.money(stats.totalExpenses),
              label: strings.totalExpenses,
              color: AppColors.danger,
            ),
            StatCard(
              icon: Icons.trending_up,
              value: Formatters.money(stats.netProfit),
              label: strings.netProfit,
            ),
          ],
        );
      },
    );
  }
}

class _ModulesGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final tiles = [
      _ModuleTile(
        icon: Icons.group_outlined,
        color: AppColors.primary,
        label: strings.titleMembers,
        route: '/members',
      ),
      _ModuleTile(
        icon: Icons.fitness_center_outlined,
        color: AppColors.primaryBright,
        label: strings.titleTrainers,
        route: '/trainers',
      ),
      _ModuleTile(
        icon: Icons.card_membership_outlined,
        color: AppColors.accent,
        label: strings.titlePlans,
        route: '/plans',
      ),
      _ModuleTile(
        icon: Icons.event_repeat,
        color: AppColors.success,
        label: strings.titleSubscriptions,
        route: '/subscriptions',
      ),
      _ModuleTile(
        icon: Icons.payments_outlined,
        color: AppColors.primary,
        label: strings.titlePayments,
        route: '/payments',
      ),
      _ModuleTile(
        icon: Icons.event_available_outlined,
        color: AppColors.accent,
        label: strings.titleAttendance,
        route: '/attendance',
      ),
      _ModuleTile(
        icon: Icons.savings_outlined,
        color: AppColors.danger,
        label: strings.titleExpenses,
        route: '/expenses',
      ),
      _ModuleTile(
        icon: Icons.campaign_outlined,
        color: AppColors.primaryBright,
        label: strings.titleAnnouncements,
        route: '/announcements',
      ),
      _ModuleTile(
        icon: Icons.settings_outlined,
        color: AppColors.success,
        label: strings.gymInformation,
        route: '/settings/gym',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final tile = tiles[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(tile.route),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tile.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tile.icon, color: tile.color, size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tile.label,
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
        );
      },
    );
  }
}

class _ModuleTile {
  const _ModuleTile({
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

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.memberName,
    required this.strings,
  });

  final Payment payment;
  final String memberName;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = payment.status == PaymentStatus.paid
        ? AppColors.success
        : payment.status == PaymentStatus.refunded
            ? theme.colorScheme.onSurfaceVariant
            : AppColors.accent;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            paymentMethodIcon(payment.method),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          memberName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${strings.paymentMethodLabel(payment.method)} • ${Formatters.dateTime(payment.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          Formatters.money(payment.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}