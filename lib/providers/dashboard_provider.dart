import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/features/dashboard/data/admin_stats.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/expenses_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';

/// KPI snapshot composed from the live domain controllers, so the dashboard
/// always reflects current data regardless of the data source (demo/Firestore).
class AdminStatsController extends AsyncNotifier<AdminStats> {
  @override
  Future<AdminStats> build() async {
    final members = await ref.watch(membersControllerProvider.future);
    final subscriptions = await ref.watch(subscriptionsControllerProvider.future);
    final payments = await ref.watch(paymentsControllerProvider.future);
    final attendance = await ref.watch(attendanceControllerProvider.future);
    final expenses = await ref.watch(expensesControllerProvider.future);

    final now = DateTime.now();
    final activeMembers = members
        .where((m) => m.status == MemberStatus.active)
        .length;
    final expiredSubscriptions = subscriptions
        .where((s) =>
            s.status == SubscriptionStatus.expired ||
            s.endDate.isBefore(now))
        .length;
    final expiringSoon = subscriptions
        .where((s) =>
            s.endDate.isAfter(now) &&
            s.endDate.difference(now).inDays <= 14)
        .length;
    final totalRevenue = payments
        .where((p) => p.status == PaymentStatus.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalExpenses =
        expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return AdminStats(
      totalMembers: members.length,
      activeMembers: activeMembers,
      expiredSubscriptions: expiredSubscriptions,
      expiringSoonSubscriptions: expiringSoon,
      todayAttendance: attendance.length,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: totalRevenue - totalExpenses,
    );
  }
}

final adminStatsProvider =
    AsyncNotifierProvider<AdminStatsController, AdminStats>(
        AdminStatsController.new);