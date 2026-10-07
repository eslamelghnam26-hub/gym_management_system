import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/widgets/responsive_scaffold.dart';
import 'package:gym_management_system/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:gym_management_system/features/attendance/presentation/attendance_screen.dart';
import 'package:gym_management_system/features/member/presentation/member_dashboard_screen.dart';
import 'package:gym_management_system/features/members/presentation/member_list_screen.dart';
import 'package:gym_management_system/features/payments/presentation/payment_list_screen.dart';
import 'package:gym_management_system/features/profile/presentation/profile_screen.dart';
import 'package:gym_management_system/features/staff/presentation/receptionist_dashboard_screen.dart';
import 'package:gym_management_system/features/staff/presentation/trainer_dashboard_screen.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/providers/auth_provider.dart';

/// Main authenticated shell. Each role gets its own tab set:
/// - Admin → Dashboard (hub) + Profile
/// - Receptionist → Dashboard + Members + Payments + Attendance + Profile
/// - Trainer → Dashboard + Profile
/// - Member → Dashboard + Profile
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.value;
    if (user == null) return const SizedBox.shrink();

    final destinations = _destinationsFor(user, strings);
    final pages = _pagesFor(user);
    final index = _index.clamp(0, destinations.length - 1);

    return ResponsiveScaffold(
      title: destinations[index].label,
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: destinations,
      floatingActionButton: _fabFor(user.role, index, context, strings),
      body: IndexedStack(index: index, children: pages),
    );
  }

  Widget? _fabFor(
    UserRole role,
    int index,
    BuildContext context,
    AppStrings strings,
  ) {
    if (role == UserRole.receptionist) {
      final route = switch (index) {
        _receptionistMembersTab => '/members/form',
        _receptionistPaymentsTab => '/payments/form',
        _ => null,
      };
      if (route == null) return null;
      return FloatingActionButton.extended(
        onPressed: () => context.push(route),
        icon: const Icon(Icons.add),
        label: Text(strings.add),
      );
    }
    return null;
  }

  static const _receptionistMembersTab = 1;
  static const _receptionistPaymentsTab = 2;

  List<ResponsiveDestination> _destinationsFor(
    AppUser user,
    AppStrings strings,
  ) {
    return switch (user.role) {
      UserRole.admin ||
      UserRole.trainer ||
      UserRole.member => [
          ResponsiveDestination(
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard,
            label: strings.dashboard,
          ),
          ResponsiveDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: strings.profile,
          ),
        ],
      UserRole.receptionist => [
          ResponsiveDestination(
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard,
            label: strings.dashboard,
          ),
          ResponsiveDestination(
            icon: Icons.group_outlined,
            selectedIcon: Icons.group,
            label: strings.titleMembers,
          ),
          ResponsiveDestination(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: strings.titlePayments,
          ),
          ResponsiveDestination(
            icon: Icons.event_available_outlined,
            selectedIcon: Icons.event_available,
            label: strings.titleAttendance,
          ),
          ResponsiveDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: strings.profile,
          ),
        ],
    };
  }

  List<Widget> _pagesFor(AppUser user) {
    return switch (user.role) {
      UserRole.admin => const [
          AdminDashboardScreen(),
          ProfileScreen(),
        ],
      UserRole.trainer => const [
          TrainerDashboardScreen(),
          ProfileScreen(),
        ],
      UserRole.receptionist => const [
          ReceptionistDashboardScreen(),
          MemberListScreen(),
          PaymentListScreen(),
          AttendanceScreen(),
          ProfileScreen(),
        ],
      UserRole.member => [
          MemberDashboardScreen(user: user),
          const ProfileScreen(),
        ],
    };
  }
}