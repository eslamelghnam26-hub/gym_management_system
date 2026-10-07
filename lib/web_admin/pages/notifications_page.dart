import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/gym_notification.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/notifications_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

/// Compose and manage in-app notifications delivered to the mobile app.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  Future<void> _openCompose() async {
    await showDialog(
      context: context,
      builder: (_) => const _ComposeNotificationDialog(),
    );
  }

  Future<void> _delete(GymNotification notification) async {
    final ok = await confirmAction(
      context,
      title: 'حذف إشعار',
      message: 'حذف «${notification.title}»؟',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(notificationsControllerProvider.notifier).delete(notification.id);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsControllerProvider);
    final membersAsync = ref.watch(membersControllerProvider);
    final membersByName = <String, String>{
      for (final m in (membersAsync.value ?? const [])) m.id: m.fullName,
    };

    return WebPage(
      title: 'الإشعارات',
      subtitle: 'رسائل داخل التطبيق لكل الأعضاء أو لشخص محدد',
      onRefresh: () => ref.invalidate(notificationsControllerProvider),
      actions: [
        FilledButton.icon(
          onPressed: _openCompose,
          icon: const Icon(Icons.send_outlined),
          label: const Text('إرسال إشعار'),
        ),
      ],
      child: notificationsAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل الإشعارات',
          onRetry: () => ref.invalidate(notificationsControllerProvider),
        ),
        data: (notifications) =>
            notifications.isEmpty
                ? const EmptyState(title: 'لا توجد إشعارات', subtitle: 'أرسل أول إشعار')
                : WebTableShell(
                    title: 'قائمة الإشعارات (${notifications.length})',
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('العنوان')),
                          DataColumn(label: Text('المحتوى')),
                          DataColumn(label: Text('المستلم')),
                          DataColumn(label: Text('التاريخ')),
                          DataColumn(label: Text('')),
                        ],
                        rows: [
                          for (final n in notifications)
                            DataRow(cells: [
                              DataCell(Text(n.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 360),
                                child: Text(n.body,
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(Text(_targetLabel(n.target, membersByName))),
                              DataCell(Text(Formatters.dateTime(n.createdAt))),
                              DataCell(IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _delete(n),
                              )),
                            ]),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

String _targetLabel(String target, Map<String, String> membersByName) {
  if (target == 'all') return 'الكل';
  return membersByName[target] ?? target;
}

class _ComposeNotificationDialog extends ConsumerStatefulWidget {
  const _ComposeNotificationDialog();

  @override
  ConsumerState<_ComposeNotificationDialog> createState() =>
      _ComposeNotificationDialogState();
}

class _ComposeNotificationDialogState
    extends ConsumerState<_ComposeNotificationDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _target = 'all';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(notificationsControllerProvider.notifier)
          .add(GymNotification(title: _title.text.trim(), body: _body.text.trim(), target: _target));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الإرسال — حاول مرة أخرى')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersControllerProvider).value ?? const [];

    return WebFormDialog(
      title: 'إرسال إشعار',
      hint: 'يظهر الإشعار داخل التطبيق عند فتحه',
      saving: _saving,
      onSave: _submit,
      width: 560,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'العنوان *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _body,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'المحتوى *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 14),
            FormDropdown<String>(
              label: 'المستلم',
              value: _target,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('جميع المستخدمين')),
                for (final m in members)
                  DropdownMenuItem(value: m.id, child: Text('عضو: ${m.fullName}')),
              ],
              onChanged: (v) => setState(() => _target = v ?? 'all'),
            ),
          ],
        ),
      ),
    );
  }
}