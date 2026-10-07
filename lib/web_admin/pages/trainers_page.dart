import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class TrainersPage extends ConsumerStatefulWidget {
  const TrainersPage({super.key});

  @override
  ConsumerState<TrainersPage> createState() => _TrainersPageState();
}

class _TrainersPageState extends ConsumerState<TrainersPage> {
  Future<void> _openForm(Trainer? trainer) async {
    await showDialog(
      context: context,
      builder: (_) => _TrainerFormDialog(initial: trainer),
    );
  }

  Future<void> _delete(Trainer trainer) async {
    final ok = await confirmAction(
      context,
      title: 'حذف مدرب',
      message: 'هل تريد حذف «${trainer.name}»؟',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(trainersControllerProvider.notifier).delete(trainer.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المدرب')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(trainersControllerProvider);
    final members = ref.watch(membersControllerProvider).value ?? const [];

    final assigned = <String, int>{};
    for (final m in members) {
      final tid = m.trainerId;
      if (tid != null) {
        assigned.update(tid, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    return WebPage(
      title: 'المدربين',
      subtitle: 'فريق التدريب ورواتبهم',
      onRefresh: () => ref.invalidate(trainersControllerProvider),
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add),
          label: const Text('إضافة مدرب'),
        ),
      ],
      child: trainersAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل المدربين',
          onRetry: () => ref.invalidate(trainersControllerProvider),
        ),
        data: (trainers) => WebTableShell(
          title: 'قائمة المدربين (${trainers.length})',
          child: trainers.isEmpty
              ? const EmptyState(
                  title: 'لا يوجد مدربون', subtitle: 'أضف أول مدرب')
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('الاسم')),
                      DataColumn(label: Text('الهاتف')),
                      DataColumn(label: Text('التخصص')),
                      DataColumn(label: Text('الراتب')),
                      DataColumn(label: Text('الجدول')),
                      DataColumn(label: Text('أعضاء معينون')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final trainer in trainers)
                        DataRow(cells: [
                          DataCell(Text(trainer.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Text(trainer.phone)),
                          DataCell(Text(trainer.specialization ?? '—')),
                          DataCell(Text(
                            trainer.salary > 0
                                ? Formatters.money(trainer.salary)
                                : '—',
                          )),
                          DataCell(Text(trainer.schedule ?? '—')),
                          DataCell(Text('${assigned[trainer.id] ?? 0}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'تعديل',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openForm(trainer),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _delete(trainer),
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

class _TrainerFormDialog extends ConsumerStatefulWidget {
  const _TrainerFormDialog({this.initial});

  final Trainer? initial;

  @override
  ConsumerState<_TrainerFormDialog> createState() => _TrainerFormDialogState();
}

class _TrainerFormDialogState extends ConsumerState<_TrainerFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _specialization =
      TextEditingController(text: widget.initial?.specialization ?? '');
  late final _salary = TextEditingController(
      text: (widget.initial?.salary ?? 0).toString());
  late final _schedule = TextEditingController(text: widget.initial?.schedule ?? '');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _specialization, _salary, _schedule]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final trainer = Trainer(
        id: widget.initial?.id ?? '',
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        specialization:
            _specialization.text.trim().isEmpty ? null : _specialization.text.trim(),
        salary: double.tryParse(_salary.text.trim()) ?? 0,
        schedule: _schedule.text.trim().isEmpty ? null : _schedule.text.trim(),
        createdAt: widget.initial?.createdAt,
      );
      final notifier = ref.read(trainersControllerProvider.notifier);
      if (widget.initial == null) {
        await notifier.add(trainer);
      } else {
        await notifier.save(trainer);
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
      title: widget.initial == null ? 'إضافة مدرب' : 'تعديل المدرب',
      saving: _saving,
      onSave: _submit,
      width: 600,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormRow(children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'الاسم *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'الهاتف *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              TextFormField(
                controller: _specialization,
                decoration: const InputDecoration(labelText: 'التخصص'),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              TextFormField(
                controller: _salary,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الراتب (ج.م)'),
              ),
              TextFormField(
                controller: _schedule,
                decoration: const InputDecoration(labelText: 'الجدول'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}