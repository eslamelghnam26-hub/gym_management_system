import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/providers/announcements_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  Future<void> _openForm(Announcement? announcement) async {
    await showDialog(
      context: context,
      builder: (_) => _AnnouncementFormDialog(initial: announcement),
    );
  }

  Future<void> _delete(Announcement announcement) async {
    final ok = await confirmAction(
      context,
      title: 'حذف إعلان',
      message: 'حذف «${announcement.title}»؟ سيختفي من تطبيقات الأعضاء.',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(announcementsControllerProvider.notifier).delete(announcement.id);
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsControllerProvider);

    return WebPage(
      title: 'الإعلانات',
      subtitle: 'تظهر مباشرة على تطبيق الجيم',
      onRefresh: () => ref.invalidate(announcementsControllerProvider),
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add),
          label: const Text('إعلان جديد'),
        ),
      ],
      child: announcementsAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل الإعلانات',
          onRetry: () => ref.invalidate(announcementsControllerProvider),
        ),
        data: (announcements) => announcements.isEmpty
            ? const EmptyState(
                title: 'لا توجد إعلانات', subtitle: 'أضف أول إعلان')
            : WebTableShell(
                title: 'قائمة الإعلانات (${announcements.length})',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('العنوان')),
                      DataColumn(label: Text('المحتوى')),
                      DataColumn(label: Text('الجمهور')),
                      DataColumn(label: Text('التاريخ')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final a in announcements)
                        DataRow(cells: [
                          DataCell(Text(a.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Text(
                              a.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                          DataCell(Text(_audienceLabel(a.audience))),
                          DataCell(Text(Formatters.dateTime(a.createdAt))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'تعديل',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openForm(a),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _delete(a),
                              ),
                            ],
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

String _audienceLabel(AnnouncementAudience audience) => switch (audience) {
      AnnouncementAudience.all => 'الكل',
      AnnouncementAudience.members => 'الأعضاء',
      AnnouncementAudience.trainers => 'المدربون',
    };

class _AnnouncementFormDialog extends ConsumerStatefulWidget {
  const _AnnouncementFormDialog({this.initial});

  final Announcement? initial;

  @override
  ConsumerState<_AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState
    extends ConsumerState<_AnnouncementFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late final _body = TextEditingController(text: widget.initial?.body ?? '');
  late AnnouncementAudience _audience;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _audience = widget.initial?.audience ?? AnnouncementAudience.all;
  }

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
      final announcement = Announcement(
        id: widget.initial?.id ?? '',
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: _audience,
        createdAt: widget.initial?.createdAt,
      );
      final notifier = ref.read(announcementsControllerProvider.notifier);
      if (widget.initial == null) {
        await notifier.add(announcement);
      } else {
        await notifier.save(announcement);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ — حاول مرة أخرى')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebFormDialog(
      title: widget.initial == null ? 'إعلان جديد' : 'تعديل الإعلان',
      saving: _saving,
      onSave: _submit,
      width: 560,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormRow(children: [
              Expanded(
                child: TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'العنوان *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FormDropdown<String>(
                  label: 'الجمهور',
                  value: _audience.key,
                  items: [
                    for (final a in AnnouncementAudience.values)
                      DropdownMenuItem(
                          value: a.key, child: Text(_audienceLabel(a))),
                  ],
                  onChanged: (v) =>
                      setState(() => _audience = AnnouncementAudience.fromKey(v)),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _body,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'المحتوى *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }
}