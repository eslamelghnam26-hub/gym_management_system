import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/gym_settings.dart';
import 'package:gym_management_system/providers/gym_settings_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

/// Generic gym settings editor — shared with the mobile app's settings.
class GymSettingsPage extends ConsumerStatefulWidget {
  const GymSettingsPage({super.key});

  @override
  ConsumerState<GymSettingsPage> createState() => _GymSettingsPageState();
}

class _GymSettingsPageState extends ConsumerState<GymSettingsPage> {
  final _form = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;
  final _gymName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _openingHours = TextEditingController();
  final _currency = TextEditingController();
  final _reminderDays = TextEditingController();

  @override
  void dispose() {
    _gymName.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _openingHours.dispose();
    _currency.dispose();
    _reminderDays.dispose();
    super.dispose();
  }

  void _init(GymSettings settings) {
    if (_initialized) return;
    _gymName.text = settings.gymName;
    _address.text = settings.address;
    _phone.text = settings.phone;
    _email.text = settings.email;
    _openingHours.text = settings.openingHours;
    _currency.text = settings.currency;
    _reminderDays.text = settings.autoRenewReminderDays.toString();
    _initialized = true;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final current = ref.read(gymSettingsProvider).value;
      if (current == null) return;
      final updated = current.copyWith(
        gymName: _gymName.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        openingHours: _openingHours.text.trim(),
        currency: _currency.text.trim(),
        autoRenewReminderDays: int.parse(_reminderDays.text.trim()),
      );
      await ref.read(gymSettingsProvider.notifier).save(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ — تأكد من البيانات')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(gymSettingsProvider);

    return WebPage(
      title: 'إعدادات الجيم',
      subtitle: 'المعلومات العامة والتجديد التلقائي',
      onRefresh: () => ref.invalidate(gymSettingsProvider),
      actions: [
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('حفظ'),
        ),
      ],
      child: settingsAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل الإعدادات',
          onRetry: () => ref.invalidate(gymSettingsProvider),
        ),
        data: (settings) {
          _init(settings);
          return Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'المعلومات العامة',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        FormRow(children: [
                          TextFormField(
                            controller: _gymName,
                            decoration: const InputDecoration(labelText: 'اسم الجيم *'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                          ),
                          TextFormField(
                            controller: _currency,
                            decoration: const InputDecoration(labelText: 'العملة'),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        FormRow(children: [
                          TextFormField(
                            controller: _phone,
                            decoration: const InputDecoration(labelText: 'الهاتف'),
                          ),
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        FormRow(children: [
                          TextFormField(
                            controller: _address,
                            decoration: const InputDecoration(labelText: 'العنوان'),
                          ),
                          TextFormField(
                            controller: _openingHours,
                            decoration: const InputDecoration(labelText: 'ساعات العمل'),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        FormRow(children: [
                          TextFormField(
                            controller: _reminderDays,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'أيام تذكير التجديد',
                              helperText: 'كم يومًا قبل انتهاء الاشتراك',
                            ),
                            validator: (v) {
                              final n = int.tryParse(v?.trim() ?? '');
                              return (n == null || n < 0 || n > 60) ? 'أيام صالحة' : null;
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}