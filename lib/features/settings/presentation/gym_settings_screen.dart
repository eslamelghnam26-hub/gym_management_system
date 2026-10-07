import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/models/gym_settings.dart';
import 'package:gym_management_system/providers/gym_settings_provider.dart';

class GymSettingsScreen extends ConsumerStatefulWidget {
  const GymSettingsScreen({super.key});

  @override
  ConsumerState<GymSettingsScreen> createState() => _GymSettingsScreenState();
}

class _GymSettingsScreenState extends ConsumerState<GymSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _hoursController;
  late final TextEditingController _reminderController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _hoursController = TextEditingController();
    _reminderController = TextEditingController(text: '7');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _hoursController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  void _hydrate(GymSettings settings) {
    if (_nameController.text.isNotEmpty) return;
    _nameController.text = settings.gymName;
    _addressController.text = settings.address;
    _phoneController.text = settings.phone;
    _emailController.text = settings.email;
    _hoursController.text = settings.openingHours;
    _reminderController.text = '${settings.autoRenewReminderDays}';
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    final current = ref.read(gymSettingsProvider).value ??
        GymSettings.defaults;
    final updated = current.copyWith(
      gymName:
          _nameController.text.trim().isEmpty ? current.gymName : _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      openingHours: _hoursController.text.trim(),
      autoRenewReminderDays:
          int.tryParse(_reminderController.text.trim()) ?? 7,
    );
    setState(() => _saving = true);
    try {
      await ref.read(gymSettingsProvider.notifier).save(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(strings.savedSuccess),
        backgroundColor: AppColors.success,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final settingsResult = ref.watch(gymSettingsProvider);
    final settings = settingsResult.value ?? GymSettings.defaults;
    _hydrate(settings);

    return Scaffold(
      appBar: AppBar(title: Text(strings.gymInformation)),
      body: SafeArea(
        child: settingsResult.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ElevatedButton(
              onPressed: () => ref.invalidate(gymSettingsProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ),
          data: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: strings.gymName,
                      hint: strings.gymName,
                      prefixIcon: Icons.fitness_center_outlined,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _addressController,
                      label: strings.gymAddress,
                      hint: strings.gymAddress,
                      prefixIcon: Icons.place_outlined,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _phoneController,
                      label: strings.gymPhone,
                      hint: strings.gymPhone,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _emailController,
                      label: strings.gymEmail,
                      hint: strings.gymEmail,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _hoursController,
                      label: strings.openingHours,
                      hint: strings.openingHours,
                      prefixIcon: Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _reminderController,
                      label: strings.autoRenewDays,
                      hint: strings.autoRenewDays,
                      prefixIcon: Icons.notifications_active_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: strings.saveSettings,
                      loading: _saving,
                      onPressed: _save,
                      icon: Icons.save_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}