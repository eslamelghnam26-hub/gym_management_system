import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/expenses_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/web_admin/widgets/charts.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';
import 'package:gym_management_system/web_admin/widgets/web_stat_card.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  static const _monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  ReportPeriod _period = ReportPeriod.monthly;

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case ReportPeriod.daily:
        return (today, today);
      case ReportPeriod.weekly:
        return (today.subtract(const Duration(days: 6)), today);
      case ReportPeriod.monthly:
        return (DateTime(today.year, today.month, 1), today);
      case ReportPeriod.yearly:
        return (DateTime(today.year, 1, 1), today);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsControllerProvider);
    final expensesAsync = ref.watch(expensesControllerProvider);

    if (paymentsAsync.isLoading || expensesAsync.isLoading) {
      return WebPage(
        title: 'التقارير',
        child: const AppLoadingView(label: 'جارٍ التحميل...'),
      );
    }
    if (paymentsAsync.hasError || expensesAsync.hasError) {
      return WebPage(
        title: 'التقارير',
        child: ErrorView(
          message: 'تعذر تحميل بيانات التقارير',
          onRetry: () {
            ref.invalidate(paymentsControllerProvider);
            ref.invalidate(expensesControllerProvider);
          },
        ),
      );
    }

    final (start, end) = _range;
    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    final payments = paymentsAsync.value ?? const <Payment>[];
    final paid =
        payments.where((p) => p.status == PaymentStatus.paid && inRange(p.createdAt));
    final revenue = paid.fold<double>(0, (sum, p) => sum + p.amount);
    final paymentCount = paid.length;

    final expenses = expensesAsync.value ?? const <Expense>[];
    final rangeExpenses = expenses.where((e) => inRange(e.date)).toList();
    final expenseTotal = rangeExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final profit = revenue - expenseTotal;

    final subscriptions = ref.watch(subscriptionsControllerProvider).value ?? const [];
    final newSubs = subscriptions.where((s) => inRange(s.createdAt)).length;

    final members = ref.watch(membersControllerProvider).value ?? const [];
    final memberName = {for (final m in members) m.id: m.fullName};

    final todayAttendance = ref.watch(attendanceControllerProvider).value?.length ?? 0;

    final buckets = _buckets(start, end, paid, rangeExpenses);
    final series = [
      BarSeries(name: 'الإيراد', color: AppColors.primary, values: buckets.revenue),
      BarSeries(name: 'المصروف', color: AppColors.danger, values: buckets.expenses),
      BarSeries(name: 'الصافي', color: AppColors.primaryBright, values: buckets.net),
    ];

    final topPayments = paid.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return WebPage(
      title: 'التقارير',
      subtitle: 'الفترة: ${Formatters.date(start)} → ${Formatters.date(end)}',
      onRefresh: () {
        ref.invalidate(paymentsControllerProvider);
        ref.invalidate(expensesControllerProvider);
        ref.invalidate(subscriptionsControllerProvider);
        ref.invalidate(membersControllerProvider);
        ref.invalidate(attendanceControllerProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ReportPeriod>(
                segments: const [
                  ButtonSegment(
                      value: ReportPeriod.daily, label: Text('يومي')),
                  ButtonSegment(
                      value: ReportPeriod.weekly, label: Text('أسبوعي')),
                  ButtonSegment(
                      value: ReportPeriod.monthly, label: Text('شهري')),
                  ButtonSegment(
                      value: ReportPeriod.yearly, label: Text('سنوي')),
                ],
                selected: {_period},
                onSelectionChanged: (selection) =>
                    setState(() => _period = selection.first),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final cardWidth = _cardWidth(constraints.maxWidth);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: WebStatCard(
                    icon: Icons.trending_up,
                    label: 'الإيراد المدفوع',
                    value: Formatters.money(revenue),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: WebStatCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'المصروفات',
                    value: Formatters.money(expenseTotal),
                    color: AppColors.danger,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: WebStatCard(
                    icon: Icons.insights_outlined,
                    label: 'صافي الربح',
                    value: Formatters.money(profit),
                    color: profit >= 0 ? AppColors.primaryBright : AppColors.danger,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: WebStatCard(
                    icon: Icons.assignment_outlined,
                    label: 'اشتراكات جديدة',
                    value: '$newSubs',
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: WebStatCard(
                    icon: Icons.payments_outlined,
                    label: 'عدد الدفعات',
                    value: '$paymentCount',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: WebStatCard(
                    icon: Icons.fact_check_outlined,
                    label: 'حضور اليوم',
                    value: '$todayAttendance',
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'التوزيع خلال الفترة',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  GroupedBarChart(
                    labels: buckets.labels,
                    series: series,
                    height: 260,
                    ySuffix: 'K',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final paymentsTable = _paymentsTable(
              context,
              'أعلى الدفعات',
              topPayments.take(15).toList(),
              memberName,
            );
            final expensesTable =
                _expensesTable(context, 'المصروفات', rangeExpenses);
            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  paymentsTable,
                  const SizedBox(height: 16),
                  expensesTable,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: paymentsTable),
                const SizedBox(width: 16),
                Expanded(child: expensesTable),
              ],
            );
          }),
        ],
      ),
    );
  }

  ({List<String> labels, List<double> revenue, List<double> expenses, List<double> net})
      _buckets(DateTime start, DateTime end, Iterable<Payment> paid, List<Expense> expenses) {
    final labels = <String>[];
    final revenue = <double>[];
    final expenseVals = <double>[];
    final net = <double>[];

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    double sumOf(DateTime bucketStart, DateTime bucketEnd, Iterable<Payment> src) {
      double s = 0;
      for (final p in src) {
        if (!p.createdAt.isBefore(bucketStart) && !p.createdAt.isAfter(bucketEnd)) {
          s += p.amount;
        }
      }
      return s;
    }

    double sumOfE(DateTime bucketStart, DateTime bucketEnd, List<Expense> src) {
      double s = 0;
      for (final e in src) {
        if (!e.date.isBefore(bucketStart) && !e.date.isAfter(bucketEnd)) {
          s += e.amount;
        }
      }
      return s;
    }

    if (_period == ReportPeriod.yearly) {
      for (var m = start.month; m <= end.month; m++) {
        final bucketStart = DateTime(start.year, m, 1);
        final bucketEnd = m == end.month ? end : DateTime(start.year, m + 1, 0);
        final r = sumOf(bucketStart, bucketEnd, paid);
        final e = sumOfE(bucketStart, bucketEnd, expenses);
        labels.add(_monthNames[m - 1]);
        revenue.add(r);
        expenseVals.add(e);
        net.add(r - e);
      }
      return (labels: labels, revenue: revenue, expenses: expenseVals, net: net);
    }

    final days = end.difference(start).inDays + 1;
    for (var i = 0; i < days; i++) {
      final day = end.subtract(Duration(days: days - 1 - i));
      double r = 0;
      double e = 0;
      for (final p in paid) {
        if (sameDay(p.createdAt, day)) r += p.amount;
      }
      for (final x in expenses) {
        if (sameDay(x.date, day)) e += x.amount;
      }
      labels.add('${day.day}/${day.month}');
      revenue.add(r);
      expenseVals.add(e);
      net.add(r - e);
    }
    return (labels: labels, revenue: revenue, expenses: expenseVals, net: net);
  }

  Widget _paymentsTable(
      BuildContext context, String title, List<Payment> rows, Map<String, String> memberName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tableTitle(context, title),
            const SizedBox(height: 10),
            rows.isEmpty
                ? _tableEmpty(context, 'لا توجد دفعات في هذه الفترة')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('العضو')),
                        DataColumn(label: Text('المبلغ')),
                        DataColumn(label: Text('الوسيلة')),
                        DataColumn(label: Text('التاريخ')),
                      ],
                      rows: [
                        for (final p in rows)
                          DataRow(cells: [
                            DataCell(Text(memberName[p.memberId] ?? '—')),
                            DataCell(Text(Formatters.money(p.amount),
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(_methodLabel(p.method))),
                            DataCell(Text(Formatters.date(p.createdAt))),
                          ]),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _expensesTable(BuildContext context, String title, List<Expense> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tableTitle(context, title),
            const SizedBox(height: 10),
            rows.isEmpty
                ? _tableEmpty(context, 'لا توجد مصروفات في هذه الفترة')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('الفئة')),
                        DataColumn(label: Text('المبلغ')),
                        DataColumn(label: Text('التاريخ')),
                      ],
                      rows: [
                        for (final e in rows)
                          DataRow(cells: [
                            DataCell(Text(_categoryLabel(e.category))),
                            DataCell(Text(Formatters.money(e.amount),
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(Formatters.date(e.date))),
                          ]),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _tableTitle(BuildContext context, String title) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      );

  Widget _tableEmpty(BuildContext context, String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(message, style: Theme.of(context).textTheme.bodySmall),
        ),
      );
}

double _cardWidth(double maxWidth, {double min = 240, double gap = 12}) {
  final cols = (maxWidth / min).floor().clamp(1, 4);
  return (maxWidth - gap * (cols - 1)) / cols;
}

String _methodLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.card => 'بطاقة',
      PaymentMethod.wallet => 'محفظة',
      PaymentMethod.bankTransfer => 'تحويل بنكي',
    };

String _categoryLabel(ExpenseCategory category) => switch (category) {
      ExpenseCategory.salary => 'رواتب',
      ExpenseCategory.rent => 'إيجار',
      ExpenseCategory.equipment => 'معدات',
      ExpenseCategory.utilities => 'خدمات',
      ExpenseCategory.other => 'أخرى',
    };