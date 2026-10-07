import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/core/widgets/app_logo.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/providers/gym_settings_provider.dart';
import 'package:gym_management_system/web_admin/pages/ai_knowledge_page.dart';
import 'package:gym_management_system/web_admin/pages/announcements_page.dart';
import 'package:gym_management_system/web_admin/pages/attendance_page.dart';
import 'package:gym_management_system/web_admin/pages/dashboard_page.dart';
import 'package:gym_management_system/web_admin/pages/expenses_page.dart';
import 'package:gym_management_system/web_admin/pages/members_page.dart';
import 'package:gym_management_system/web_admin/pages/notifications_page.dart';
import 'package:gym_management_system/web_admin/pages/payments_page.dart';
import 'package:gym_management_system/web_admin/pages/plans_page.dart';
import 'package:gym_management_system/web_admin/pages/reports_page.dart';
import 'package:gym_management_system/web_admin/pages/settings_page.dart';
import 'package:gym_management_system/web_admin/pages/subscriptions_page.dart';
import 'package:gym_management_system/web_admin/pages/trainers_page.dart';
import 'package:gym_management_system/web_admin/pages/users_page.dart';

/// Registered web admin sections. Roles decide which sections are visible.
enum AdminPageId {
  dashboard,
  members,
  plans,
  subscriptions,
  attendance,
  payments,
  trainers,
  expenses,
  reports,
  announcements,
  knowledge,
  notifications,
  users,
  settings,
}

class AdminNavItem {
  const AdminNavItem(this.id, this.label, this.icon);

  final AdminPageId id;
  final String label;
  final IconData icon;
}

const _allNavItems = <AdminNavItem>[
  AdminNavItem(AdminPageId.dashboard, 'لوحة التحكم', Icons.dashboard_outlined),
  AdminNavItem(AdminPageId.members, 'الأعضاء', Icons.people_outline),
  AdminNavItem(AdminPageId.plans, 'الباقات', Icons.card_membership_outlined),
  AdminNavItem(AdminPageId.subscriptions, 'الاشتراكات', Icons.assignment_outlined),
  AdminNavItem(AdminPageId.attendance, 'الحضور', Icons.fact_check_outlined),
  AdminNavItem(AdminPageId.payments, 'المدفوعات', Icons.payments_outlined),
  AdminNavItem(AdminPageId.trainers, 'المدربين', Icons.fitness_center_outlined),
  AdminNavItem(AdminPageId.expenses, 'المصروفات', Icons.receipt_long_outlined),
  AdminNavItem(AdminPageId.reports, 'التقارير', Icons.insights_outlined),
  AdminNavItem(AdminPageId.announcements, 'الإعلانات', Icons.campaign_outlined),
  AdminNavItem(AdminPageId.knowledge, 'ذكاء الجيم (AI)', Icons.auto_awesome_outlined),
  AdminNavItem(AdminPageId.notifications, 'الإشعارات', Icons.notifications_outlined),
  AdminNavItem(AdminPageId.users, 'المستخدمون والصلاحيات', Icons.manage_accounts_outlined),
  AdminNavItem(AdminPageId.settings, 'إعدادات الجيم', Icons.settings_outlined),
];

bool canAccessAdminSection(UserRole role, AdminPageId page) {
  switch (page) {
    case AdminPageId.dashboard:
      return true;
    case AdminPageId.members:
      return role != UserRole.member;
    case AdminPageId.attendance:
      return role != UserRole.member;
    case AdminPageId.plans:
      return role == UserRole.admin || role == UserRole.receptionist;
    case AdminPageId.subscriptions:
    case AdminPageId.payments:
    case AdminPageId.reports:
      return role == UserRole.admin || role == UserRole.receptionist;
    case AdminPageId.trainers:
    case AdminPageId.expenses:
    case AdminPageId.announcements:
    case AdminPageId.knowledge:
    case AdminPageId.notifications:
    case AdminPageId.users:
    case AdminPageId.settings:
      return role == UserRole.admin;
  }
}

/// Persistent layout for the web dashboard: sidebar navigation + top bar on
/// wide screens, hamburger drawer + app bar on narrow ones.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  Widget buildPage(AdminPageId id) {
    switch (id) {
      case AdminPageId.dashboard:
        return const DashboardPage();
      case AdminPageId.members:
        return const MembersPage();
      case AdminPageId.plans:
        return const PlansPage();
      case AdminPageId.trainers:
        return const TrainersPage();
      case AdminPageId.subscriptions:
        return const SubscriptionsPage();
      case AdminPageId.payments:
        return const PaymentsPage();
      case AdminPageId.attendance:
        return const AttendancePage();
      case AdminPageId.expenses:
        return const ExpensesPage();
      case AdminPageId.reports:
        return const ReportsPage();
      case AdminPageId.announcements:
        return const AnnouncementsPage();
      case AdminPageId.knowledge:
        return const AiKnowledgePage();
      case AdminPageId.notifications:
        return const NotificationsPage();
      case AdminPageId.users:
        return const UsersPage();
      case AdminPageId.settings:
        return const GymSettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value!;
    final settings = ref.watch(gymSettingsProvider).value;
    final gymName = settings?.gymName ?? 'Gym Pro';
    void logout() {
      ref.read(authControllerProvider.notifier).signOut();
    }

    final allowed = [
      for (final item in _allNavItems)
        if (canAccessAdminSection(user.role, item.id)) item,
    ];
    if (_index >= allowed.length) _index = 0;
    final selected = allowed[_index];
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final body = buildPage(selected.id);

    if (!wide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(selected.label),
          actions: [
            const _SourceBadge(),
            _UserMenu(user: user, onLogout: logout),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(child: _SidebarContent(gymName: gymName, user: user, items: allowed, index: _index, onSelect: (i) => setState(() => _index = i), onLogout: logout)),
        body: body,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 264,
            child: _SidebarContent(
              gymName: gymName,
              user: user,
              items: allowed,
              index: _index,
              onSelect: (i) => setState(() => _index = i),
              onLogout: logout,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: selected.label, user: user, onLogout: logout),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.gymName,
    required this.user,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.onLogout,
  });

  final String gymName;
  final AppUser user;
  final List<AdminNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const AppLogo(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      gymName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final selected = i == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Material(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 22,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.initials,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          user.role.labelAr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'تسجيل الخروج',
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.user, required this.onLogout});

  final String title;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const _SourceBadge(),
          const SizedBox(width: 12),
          _UserMenu(user: user, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebase = AppConfig.isFirebase;
    final color = firebase ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Tooltip(
        message: AppConfig.isFirebase
            ? 'متصل بـ Firestore حقيقية'
            : 'وضع تجريبي — املأ lib/firebase_options.dart للاتصال',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 6),
            Text(
              firebase ? 'Firebase' : 'Demo',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'الحساب',
      offset: const Offset(0, 48),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(user.email, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 10),
              Text('تسجيل الخروج'),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'logout') onLogout();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                user.initials,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              user.name,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}