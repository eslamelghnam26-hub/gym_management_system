import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key});

  @override
  ConsumerState<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends ConsumerState<PlansPage> {
  Future<void> _openForm(MembershipPlan? plan) async {
    await showDialog(
      context: context,
      builder: (_) => _PlanFormDialog(initial: plan),
    );
  }

  Future<void> _toggle(MembershipPlan plan) async {
    await ref
        .read(plansControllerProvider.notifier)
        .save(plan.copyWith(isActive: !plan.isActive));
  }

  Future<void> _delete(MembershipPlan plan) async {
    final ok = await confirmAction(
      context,
      title: 'حذف باقة',
      message: 'حذف «${plan.name}»؟ سيؤثر على الاشتراكات المرتبطة بها.',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(plansControllerProvider.notifier).delete(plan.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الباقة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansControllerProvider);

    return WebPage(
      title: 'الباقات',
      subtitle: 'باقات الاشتراك والأسعار',
      onRefresh: () => ref.invalidate(plansControllerProvider),
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add),
          label: const Text('باقة جديدة'),
        ),
      ],
      child: plansAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل الباقات',
          onRetry: () => ref.invalidate(plansControllerProvider),
        ),
        data: (plans) {
          final sorted = [...plans]
            ..sort((a, b) {
              if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
              return a.name.compareTo(b.name);
            });
          return WebTableShell(
            title: 'قائمة الباقات (${plans.length})',
            child: sorted.isEmpty
                ? const EmptyState(title: 'لا توجد باقات', subtitle: 'أضف أول باقة')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('الباقة')),
                        DataColumn(label: Text('المدة')),
                        DataColumn(label: Text('الجلسات')),
                        DataColumn(label: Text('السعر')),
                        DataColumn(label: Text('المزايا')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final plan in sorted)
                          DataRow(cells: [
                            DataCell(Text(plan.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text('${plan.durationDays} يوم')),
                            DataCell(Text(plan.isUnlimitedSessions
                                ? 'غير محدود'
                                : '${plan.sessions}')),
                            DataCell(Text(Formatters.money(plan.price),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final feature in plan.features)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        feature,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Switch(
                              value: plan.isActive,
                              onChanged: (_) => _toggle(plan),
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openForm(plan),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _delete(plan),
                                ),
                              ],
                            )),
                          ]),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _PlanFormDialog extends ConsumerStatefulWidget {
  const _PlanFormDialog({this.initial});

  final MembershipPlan? initial;

  @override
  ConsumerState<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends ConsumerState<_PlanFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _duration = TextEditingController(
      text: (widget.initial?.durationDays ?? 30).toString());
  late final _price = TextEditingController(
      text: (widget.initial?.price ?? 0).toString());
  late final _sessions = TextEditingController(
      text: (widget.initial?.sessions ?? 0).toString());
  late final List<TextEditingController> _features = [
    for (final f in widget.initial?.features ?? const <String>[])
      TextEditingController(text: f),
  ];
  late bool _active = widget.initial?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _price.dispose();
    _sessions.dispose();
    for (final c in _features) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final plan = MembershipPlan(
        id: widget.initial?.id ?? '',
        name: _name.text.trim(),
        durationDays: int.parse(_duration.text.trim()),
        price: double.parse(_price.text.trim()),
        sessions: int.tryParse(_sessions.text.trim()) ?? 0,
        features: [for (final c in _features) c.text.trim()],
        isActive: _active,
        createdAt: widget.initial?.createdAt,
      );
      final notifier = ref.read(plansControllerProvider.notifier);
      if (widget.initial == null) {
        await notifier.add(plan);
      } else {
        await notifier.save(plan);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ — تحقق من الأرقام')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebFormDialog(
      title: widget.initial == null ? 'باقة جديدة' : 'تعديل الباقة',
      saving: _saving,
      onSave: _submit,
      width: 560,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم الباقة *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 14),
            FormRow(children: [
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'المدة بالأيام *'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return (n == null || n <= 0) ? 'رقم صحيح موجب' : null;
                },
              ),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر (ج.م) *'),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  return (n == null || n < 0) ? 'رقم صالح' : null;
                },
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sessions,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الجلسات الشامل (0 = غير محدود)',
                hintText: 'مثال: 12 أو 0 لغير المحدود',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text('باقة نشطة'),
                ),
                Switch(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('المزايا', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (var i = 0; i < _features.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _features[i],
                        decoration:
                            InputDecoration(labelText: 'ميزة ${i + 1}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'حذف الميزة',
                      onPressed: () => setState(() {
                        _features.removeAt(i).dispose();
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _features.add(TextEditingController()));
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة ميزة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}