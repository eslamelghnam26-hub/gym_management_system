import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/theme/app_theme.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/app_logo.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/providers/locale_provider.dart';
import 'package:gym_management_system/providers/theme_provider.dart';
import 'package:gym_management_system/web_admin/admin_login_screen.dart';
import 'package:gym_management_system/web_admin/admin_shell.dart';

/// Root of the web admin dashboard. Mirrors the mobile [GymApp] shell but
/// gates the UI to staff roles (member accounts are blocked on the web).
class WebAdminApp extends ConsumerWidget {
  const WebAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider).toFlutterThemeMode;
    final auth = ref.watch(authControllerProvider);

    return MaterialApp(
      title: '${strings.appName} — Admin',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: _AuthGate(auth),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate(this.auth);

  final AsyncValue<AppUser?> auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = auth.value;

    if (user == null) {
      if (auth.isLoading) return const _BootScreen();
      if (auth.hasError) {
        final code =
            (auth.error is AppException ? (auth.error as AppException).code : null) ??
                'auth';
        return Scaffold(
          body: Center(
            child: ErrorView(
              message: ref.read(appStringsProvider).errorMessage(code),
              onRetry: () => ref.invalidate(authControllerProvider),
            ),
          ),
        );
      }
      return const AdminLoginScreen();
    }

    if (user.role == UserRole.member) return const MemberForbiddenScreen();
    return const AdminShell();
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 88),
            SizedBox(height: 28),
            AppLoadingView(),
          ],
        ),
      ),
    );
  }
}

class MemberForbiddenScreen extends ConsumerWidget {
  const MemberForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'لوحة التحكم للكوادر فقط',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'حساب الأعضاء لا يدخل على نظام الإدارة — استخدم تطبيق الجيم.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}