import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/widgets/module_screen.dart';
import 'package:gym_management_system/features/announcements/presentation/announcement_form_screen.dart';
import 'package:gym_management_system/features/announcements/presentation/announcement_list_screen.dart';
import 'package:gym_management_system/features/attendance/presentation/attendance_screen.dart';
import 'package:gym_management_system/features/auth/presentation/forgot_password_screen.dart';
import 'package:gym_management_system/features/auth/presentation/login_screen.dart';
import 'package:gym_management_system/features/auth/presentation/register_screen.dart';
import 'package:gym_management_system/features/expenses/presentation/expense_form_screen.dart';
import 'package:gym_management_system/features/expenses/presentation/expense_list_screen.dart';
import 'package:gym_management_system/features/members/presentation/my_attendance_screen.dart';
import 'package:gym_management_system/features/members/presentation/my_payments_screen.dart';
import 'package:gym_management_system/features/members/presentation/my_subscription_screen.dart';
import 'package:gym_management_system/features/members/presentation/member_details_screen.dart';
import 'package:gym_management_system/features/members/presentation/member_form_screen.dart';
import 'package:gym_management_system/features/members/presentation/member_list_screen.dart';
import 'package:gym_management_system/features/payments/presentation/payment_form_screen.dart';
import 'package:gym_management_system/features/payments/presentation/payment_list_screen.dart';
import 'package:gym_management_system/features/plans/presentation/plan_form_screen.dart';
import 'package:gym_management_system/features/plans/presentation/plan_list_screen.dart';
import 'package:gym_management_system/features/settings/presentation/gym_info_screen.dart';
import 'package:gym_management_system/features/settings/presentation/gym_settings_screen.dart';
import 'package:gym_management_system/features/subscriptions/presentation/subscription_form_screen.dart';
import 'package:gym_management_system/features/subscriptions/presentation/subscription_list_screen.dart';
import 'package:gym_management_system/features/trainers/presentation/trainer_details_screen.dart';
import 'package:gym_management_system/features/trainers/presentation/trainer_form_screen.dart';
import 'package:gym_management_system/features/trainers/presentation/trainer_list_screen.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/screens/coming_soon_screen.dart';
import 'package:gym_management_system/screens/home_shell.dart';
import 'package:gym_management_system/screens/splash_screen.dart';

/// Bridges Riverpod auth state into [GoRouter.refreshListenable] so every
/// auth change re-evaluates the redirects automatically.
class AuthRefresh extends ChangeNotifier {
  void notifyAuthChanged() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRefresh();
  ref.onDispose(refresh.dispose);

  ref.listen(authControllerProvider, (previous, next) {
    refresh.notifyAuthChanged();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;

      final loggedIn = auth.hasValue && auth.value != null;
      final isAuthPage = ['/login', '/register', '/forgot-password']
          .any((path) => state.matchedLocation == path);

      if (loggedIn && isAuthPage) return '/home';
      if (!loggedIn && !isAuthPage && state.matchedLocation != '/splash') {
        return '/login';
      }
      if (loggedIn &&
          state.matchedLocation != '/splash' &&
          !_allowedFor(auth.value!.role, state.matchedLocation)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/coming-soon',
        builder: (context, state) {
          final title = state.extra as String? ?? '';
          return ComingSoonScreen(title: title);
        },
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titleMembers,
          child: const MemberListScreen(),
        ),
      ),
      GoRoute(
        path: '/members/form',
        builder: (context, state) =>
            MemberFormScreen(member: state.extra as Member?),
      ),
      GoRoute(
        path: '/members/detail',
        builder: (context, state) =>
            MemberDetailsScreen(member: state.extra as Member),
      ),
      GoRoute(
        path: '/trainers',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titleTrainers,
          child: const TrainerListScreen(),
        ),
      ),
      GoRoute(
        path: '/trainers/form',
        builder: (context, state) =>
            TrainerFormScreen(trainer: state.extra as Trainer?),
      ),
      GoRoute(
        path: '/trainers/detail',
        builder: (context, state) =>
            TrainerDetailsScreen(trainer: state.extra as Trainer),
      ),
      GoRoute(
        path: '/plans',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titlePlans,
          child: const PlanListScreen(),
        ),
      ),
      GoRoute(
        path: '/plans/form',
        builder: (context, state) =>
            PlanFormScreen(plan: state.extra as MembershipPlan?),
      ),
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titleSubscriptions,
          child: const SubscriptionListScreen(),
        ),
      ),
      GoRoute(
        path: '/subscriptions/form',
        builder: (context, state) => SubscriptionFormScreen(
          args: state.extra as SubscriptionFormArgs? ?? const SubscriptionFormArgs(),
        ),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titlePayments,
          child: const PaymentListScreen(),
        ),
      ),
      GoRoute(
        path: '/payments/form',
        builder: (context, state) =>
            PaymentFormScreen(args: state.extra as PaymentFormArgs? ?? const PaymentFormArgs()),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titleAttendance,
          child: const AttendanceScreen(),
        ),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titleExpenses,
          child: const ExpenseListScreen(),
        ),
      ),
      GoRoute(
        path: '/expenses/form',
        builder: (context, state) => const ExpenseFormScreen(),
      ),
      GoRoute(
        path: '/announcements',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).titleAnnouncements,
          child: const AnnouncementListScreen(),
        ),
      ),
      GoRoute(
        path: '/announcements/form',
        builder: (context, state) => const AnnouncementFormScreen(),
      ),
      GoRoute(
        path: '/settings/gym',
        builder: (context, state) => const GymSettingsScreen(),
      ),
      GoRoute(
        path: '/my/subscription',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).myMembership,
          child: const MySubscriptionScreen(),
        ),
      ),
      GoRoute(
        path: '/my/payments',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).myPayments,
          child: const MyPaymentsScreen(),
        ),
      ),
      GoRoute(
        path: '/my/attendance',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).myAttendance,
          child: const MyAttendanceScreen(),
        ),
      ),
      GoRoute(
        path: '/gym-info',
        builder: (context, state) => ModuleScreen(
          title: ref.read(appStringsProvider).gymInfo,
          child: const GymInfoScreen(),
        ),
      ),
    ],
  );
});

bool _allowedFor(UserRole role, String location) {
  final canAlways = {
    '/home',
    '/coming-soon',
  };
  return switch (role) {
    UserRole.admin => true,
    UserRole.receptionist => canAlways.contains(location) ||
        {
          '/members',
          '/members/form',
          '/members/detail',
          '/subscriptions/form',
          '/subscriptions',
          '/payments',
          '/payments/form',
          '/attendance',
        }.contains(location),
    UserRole.trainer => canAlways.contains(location) ||
        {
          '/members',
          '/members/detail',
        }.contains(location),
    UserRole.member => canAlways.contains(location) ||
        {
          '/my/subscription',
          '/my/payments',
          '/my/attendance',
          '/gym-info',
          '/subscriptions/form',
        }.contains(location),
  };
}