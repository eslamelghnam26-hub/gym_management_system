import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/validators.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_logo.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/repositories/demo_auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
          );
      if (!mounted) return;
      context.go('/home');
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(Exception e) {
    final strings = ref.read(appStringsProvider);
    final code = e is AppException ? e.code : 'unknown';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.errorMessage(code)),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/gym_images/gym_dark.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.55, 1.0],
                colors: [
                  Color(0xE60A2E14),
                  Color(0xED10351C),
                  Color(0xF51B5E20),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 84)),
                      const SizedBox(height: 20),
                      Text(
                        strings.appName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.appSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.94,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              strings.login,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: AutofillGroup(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextField(
                                      controller: _emailController,
                                      label: strings.email,
                                      hint: 'mail@example.com',
                                      prefixIcon: Icons.mail_outline,
                                      validator: Validators.email,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email
                                      ],
                                    ),
                                    AppTextField(
                                      controller: _passwordController,
                                      label: strings.password,
                                      hint: '******',
                                      prefixIcon: Icons.lock_outline,
                                      obscure: true,
                                      validator: Validators.password,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password
                                      ],
                                      onSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 20),
                                    AppButton(
                                      label: strings.login,
                                      loading: _submitting,
                                      onPressed: _submit,
                                      icon: Icons.login,
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton(
                                      onPressed: () =>
                                          context.push('/forgot-password'),
                                      child: Text(strings.forgotPassword),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          strings.doNotHaveAccount,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.push('/register'),
                                          child: Text(strings.signUp),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!AppConfig.isFirebase) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              _DemoAccounts(onFilled: (email, password) {
                                _emailController.text = email;
                                _passwordController.text = password;
                                setState(() {});
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoAccounts extends ConsumerWidget {
  const _DemoAccounts({required this.onFilled});

  final void Function(String email, String password) onFilled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.demoAccounts,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.demoHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final account in DemoAuthRepository.demoAccounts)
                ActionChip(
                  avatar: Icon(
                    _roleIcon(account.role),
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(_roleLabel(strings, account.role)),
                  onPressed: () => onFilled(account.email, account.password),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _roleIcon(dynamic role) => Icons.account_circle;

String _roleLabel(AppStrings strings, dynamic role) => switch (role.key) {
      'admin' => strings.roleAdmin,
      'receptionist' => strings.roleReceptionist,
      'trainer' => strings.roleTrainer,
      _ => strings.roleMember,
    };