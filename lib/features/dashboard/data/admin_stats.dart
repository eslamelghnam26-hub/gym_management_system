/// Read-only snapshot of the admin dashboard KPIs. Computed live by
/// [AdminStatsController] from the domain controllers (members, subscriptions,
/// payments, attendance, expenses) — so it always mirrors the real data.
class AdminStats {
  const AdminStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredSubscriptions,
    required this.expiringSoonSubscriptions,
    required this.todayAttendance,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });

  final int totalMembers;
  final int activeMembers;
  final int expiredSubscriptions;
  final int expiringSoonSubscriptions;
  final int todayAttendance;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  static const AdminStats demo = AdminStats(
    totalMembers: 124,
    activeMembers: 96,
    expiredSubscriptions: 18,
    expiringSoonSubscriptions: 11,
    todayAttendance: 38,
    totalRevenue: 184500,
    totalExpenses: 96200,
    netProfit: 88300,
  );

  static const AdminStats empty = AdminStats(
    totalMembers: 0,
    activeMembers: 0,
    expiredSubscriptions: 0,
    expiringSoonSubscriptions: 0,
    todayAttendance: 0,
    totalRevenue: 0,
    totalExpenses: 0,
    netProfit: 0,
  );
}