import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/features/dashboard/data/admin_stats.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/dashboard_provider.dart';
import 'package:gym_management_system/providers/expenses_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/web_admin/widgets/charts.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';
import 'package:gym_management_system/web_admin/widgets/web_stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    WebPage sheet() {
      final members = ref.watch(membersControllerProvider).value ?? const [];
      final subscriptions = ref.watch(subscriptionsControllerProvider).value ?? const [];
      final payments = ref.watch(paymentsControllerProvider).value ?? const [];
      final plans = ref.watch(plansControllerProvider).value ?? const [];
      final expenses = ref.watch(expensesControllerProvider).value ?? const [];
      final attendance = ref.watch(attendanceControllerProvider).value ?? const [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final paidPayments = payments.where((p) => p.status == PaymentStatus.paid);

      double revenueOn(DateTime d) => paidPayments
          .where((p) => _sameDay(p.createdAt, d))
          .fold<double>(0, (sum, p) => sum + p.amount);
      double expensesOn(DateTime d) => expenses
          .where((e) => _sameDay(e.date, d))
          .fold<double>(0, (sum, e) => sum + e.amount);

      final todayRevenue = revenueOn(today);
      final monthRevenue = paidPayments
          .where((p) => _sameMonth(p.createdAt, today))
          .fold<double>(0, (sum, p) => sum + p.amount);
      final todayExpenses = expensesOn(today);
      final monthExpenses = expenses
          .where((e) => _sameMonth(e.date, today))
          .fold<double>(0, (sum, e) => sum + e.amount);
      final monthProfit = monthRevenue - monthExpenses;

      final stats = statsAsync.value ?? AdminStats.empty;

      final last7 = [
        for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
      ];

      final revenueSeries = BarSeries(
        name: 'الإيراد',
        color: AppColors.primary,
        values: [for (final d in last7) revenueOn(d)],
      );
      final expenseSeries = BarSeries(
        name: 'المصروف',
        color: AppColors.danger,
        values: [for (final d in last7) expensesOn(d)],
      );
      final profitSeries = BarSeries(
        name: 'الصافي',
        color: AppColors.primaryBright,
        values: [
          for (var i = 0; i < 7; i++) revenueOn(last7[i]) - expensesOn(last7[i]),
        ],
      );

      final attendanceBins = <double>[];
      for (var h = 6; h <= 22; h++) {
        attendanceBins.add(attendance
            .where((r) => (r.checkIn?.hour ?? -1) == h)
            .length
            .toDouble());
      }

      final activeSubs = subscriptions.where((s) => s.isActive).length;
      final expiredSubs = subscriptions
          .where((s) => s.status == SubscriptionStatus.expired || s.endDate.isBefore(now))
          .length;
      final cancelledSubs =
          subscriptions.where((s) => s.status == SubscriptionStatus.cancelled).length;

      final planMembers = <String, int>{};
      for (final m in members) {
        planMembers.update(m.planId ?? '', (v) => v + 1, ifAbsent: () => 1);
      }
      final planItems = <({String label, double value, Color color})>[
        (label: 'بدون باقة', value: planMembers['']?.toDouble() ?? 0, color: Colors.blueGrey),
        for (var i = 0; i < plans.length; i++)
          (
            label: plans[i].name,
            value: (planMembers[plans[i].id] ?? 0).toDouble(),
            color: AppColors.primary.withValues(alpha: 0.55 + 0.15 * (i % 3)),
          ),
      ];

      final memberName = {for (final m in members) m.id: m.fullName};
      final recentPayments = paidPayments.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recent = recentPayments.take(8).toList();

      return WebPage(
        title: 'لوحة التحكم',
        subtitle: AppConfig.isFirebase
            ? 'نظرة عامة على البيانات من قاعدة الشبكة'
            : 'وضع تجريبي محلي — البيانات للتجربة فقط',
        onRefresh: () {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(membersControllerProvider);
          ref.invalidate(plansControllerProvider);
          ref.invalidate(subscriptionsControllerProvider);
          ref.invalidate(paymentsControllerProvider);
          ref.invalidate(expensesControllerProvider);
          ref.invalidate(attendanceControllerProvider);
        },
        child: LayoutBuilder(builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 900;
          final cardWidth = _gridCardWidth(constraints.maxWidth, min: 230);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (AppConfig.isFirebase == false) _demoBanner(context),
              if (AppConfig.isFirebase == false) const SizedBox(height: 14),
              _kpiGrid(cardWidth, context, now: now, stats: stats,
                  todayRevenue: todayRevenue, monthRevenue: monthRevenue,
                  monthExpenses: monthExpenses, monthProfit: monthProfit,
                  todayExpenses: todayExpenses),
              const SizedBox(height: 16),
              if (twoCol)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _panel(
                        context,
                        title: 'الإيراد والمصروف والصافي — آخر 7 أيام',
                        child: GroupedBarChart(
                          labels: [for (final d in last7) _weekLabel(d)],
                          series: [revenueSeries, expenseSeries, profitSeries],
                          ySuffix: 'K',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _panel(
                        context,
                        title: 'الحضور اليوم حسب الساعة',
                        child: attendance.isNotEmpty
                            ? AreaChart(values: attendanceBins)
                            : _emptyChart(context),
                      ),
                    ),
                  ],
                )
              else ...[
                _panel(
                  context,
                  title: 'الإيراد والمصروف والصافي — آخر 7 أيام',
                  child: GroupedBarChart(
                    labels: [for (final d in last7) _weekLabel(d)],
                    series: [revenueSeries, expenseSeries, profitSeries],
                    ySuffix: 'K',
                  ),
                ),
                const SizedBox(height: 16),
                _panel(
                  context,
                  title: 'الحضور اليوم حسب الساعة',
                  child: attendance.isNotEmpty
                      ? AreaChart(values: attendanceBins)
                      : _emptyChart(context),
                ),
              ],
              const SizedBox(height: 16),
              _rowOrColumn(
                twoCol: true,
                first: _panel(
                  context,
                  title: 'حالة الاشتراكات',
                  child: ProportionalBars(
                    items: [
                      (label: 'نشط', value: activeSubs.toDouble(), color: AppColors.success),
                      (label: 'منتهي', value: expiredSubs.toDouble(), color: AppColors.danger),
                      (label: 'ملغي', value: cancelledSubs.toDouble(), color: Colors.blueGrey),
                    ],
                  ),
                ),
                second: _panel(
                  context,
                  title: 'الأعضاء حسب الباقة',
                  child: ProportionalBars(
                    items: [for (final item in planItems) (label: item.label, value: item.value, color: item.color)],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _panel(
                context,
                title: 'أحدث المدفوعات',
                child: recent.isEmpty
                    ? _emptyChart(context)
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('العضو')),
                            DataColumn(label: Text('المبلغ')),
                            DataColumn(label: Text('الوسيلة')),
                            DataColumn(label: Text('الحالة')),
                            DataColumn(label: Text('التاريخ')),
                          ],
                          rows: [
                            for (final p in recent)
                              DataRow(cells: [
                                DataCell(Text(memberName[p.memberId] ?? '—')),
                                DataCell(Text(
                                  Formatters.money(p.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                )),
                                DataCell(Text(_methodLabel(p.method))),
                                DataCell(_statusText(p.status)),
                                DataCell(Text(Formatters.date(p.createdAt))),
                              ]),
                          ],
                        ),
                      ),
              ),
            ],
          );
        }),
      );
    }

    if (statsAsync.isLoading && statsAsync.value == null) {
      return WebPage(
        title: 'لوحة التحكم',
        child: const AppLoadingView(label: 'جارٍ التحميل...'),
      );
    }
    if (statsAsync.hasError && statsAsync.value == null) {
      return WebPage(
        title: 'لوحة التحكم',
        child: ErrorView(
          message: 'تعذر تحميل البيانات',
          onRetry: () => ref.invalidate(adminStatsProvider),
        ),
      );
    }
    return sheet();
  }

  Widget _kpiGrid(double cardWidth, BuildContext context,
      {required DateTime now,
      required AdminStats stats,
      required double todayRevenue,
      required double monthRevenue,
      required double monthExpenses,
      required double monthProfit,
      required double todayExpenses}) {
    final cards = [
      WebStatCard(
        icon: Icons.people_outline, label: 'إجمالي الأعضاء',
        value: '${stats.totalMembers}'),
      WebStatCard(
        icon: Icons.check_circle_outline, label: 'الأعضاء النشطون',
        value: '${stats.activeMembers}',
        color: AppColors.success, hint: 'من ${stats.totalMembers}'),
      WebStatCard(
        icon: Icons.cancel_outlined, label: 'اشتراكات منتهية',
        value: '${stats.expiredSubscriptions}', color: AppColors.danger),
      WebStatCard(
        icon: Icons.schedule_outlined, label: 'تنتهي قريباً (14 يوم)',
        value: '${stats.expiringSoonSubscriptions}', color: AppColors.accent),
      WebStatCard(
        icon: Icons.fact_check_outlined, label: 'حضور اليوم',
        value: '${stats.todayAttendance}'),
      WebStatCard(
        icon: Icons.payments_outlined, label: 'إيراد اليوم',
        value: Formatters.money(todayRevenue), hint: 'المدفوع'),
      WebStatCard(
        icon: Icons.receipt_long_outlined, label: 'مصروفات اليوم',
        value: Formatters.money(todayExpenses), color: AppColors.danger),
      WebStatCard(
        icon: Icons.trending_up, label: 'إيراد الشهر',
        value: Formatters.money(monthRevenue), hint: _monthLabel(now)),
      WebStatCard(
        icon: Icons.pie_chart_outline, label: 'صافي ربح الشهر',
        value: Formatters.money(monthProfit),
        color: monthProfit >= 0 ? AppColors.primaryBright : AppColors.danger),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final card in cards) SizedBox(width: cardWidth, child: card)],
    );
  }

  Widget _demoBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'الموقع غير متصل بقاعدة بيانات Firebase بعد — البيانات المعروضة تجريبية. كل ما تحتاجه هو تعبئة lib/firebase_options.dart ثم التشغيل بـ --dart-define=DATA_SOURCE=firebase.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

double _gridCardWidth(double maxWidth, {double min = 230, double gap = 12}) {
  final cols = math.max(1, (maxWidth / min).floor());
  return (maxWidth - gap * (cols - 1)) / cols;
}

Widget _rowOrColumn({required bool twoCol, required Widget first, required Widget second}) {
  if (!twoCol) {
    return Column(
      children: [
        first,
        const SizedBox(height: 16),
        second,
      ],
    );
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: first),
      const SizedBox(width: 16),
      Expanded(child: second),
    ],
  );
}

Widget _panel(BuildContext context, {required String title, required Widget child}) {
  final theme = Theme.of(context);
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

Widget _emptyChart(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'لا توجد بيانات بعد',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

String _weekLabel(DateTime d) => '${d.day}/${d.month}';

String _monthLabel(DateTime d) => '${d.month}/${d.year}';

String _methodLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.card => 'بطاقة',
      PaymentMethod.wallet => 'محفظة',
      PaymentMethod.bankTransfer => 'تحويل بنكي',
    };

Widget _statusText(PaymentStatus status) {
  final color = switch (status) {
    PaymentStatus.paid => AppColors.success,
    PaymentStatus.pending => AppColors.accent,
    PaymentStatus.refunded => Colors.blueGrey,
    PaymentStatus.failed => AppColors.danger,
  };
  return Text(
    switch (status) {
      PaymentStatus.paid => 'مدفوع',
      PaymentStatus.pending => 'معلق',
      PaymentStatus.refunded => 'مسترجع',
      PaymentStatus.failed => 'فاشل',
    },
    style: TextStyle(color: color, fontWeight: FontWeight.w600),
  );
}