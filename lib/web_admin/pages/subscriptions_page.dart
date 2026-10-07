import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  final _search = TextEditingController();
  SubscriptionStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm(Subscription? subscription) async {
    await showDialog(
      context: context,
      builder: (_) => _SubscriptionFormDialog(initial: subscription),
    );
  }

  Future<void> _renew(Subscription subscription) async {
    final plans = ref.read(plansControllerProvider).value ?? const [];
    final plan = plans.where((p) => p.id == subscription.planId).firstOrNull;
    if (plan == null) return;
    final now = DateTime.now();
    final base = subscription.endDate.isAfter(now)
        ? subscription.endDate
        : now;
    final renewed = subscription.copyWith(
      startDate: now,
      endDate: base.add(Duration(days: plan.durationDays)),
      status: SubscriptionStatus.active,
      method: null,
    );
    await ref
        .read(subscriptionsControllerProvider.notifier)
        .save(renewed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تجديد الاشتراك')),
    );
  }

  Future<void> _cancel(Subscription subscription) async {
    final ok = await confirmAction(
      context,
      title: 'إلغاء الاشتراك',
      message: 'إلغاء هذا الاشتراك؟',
      confirmLabel: 'إلغاء',
      cancelLabel: 'تراجع',
    );
    if (!ok || !mounted) return;
    await ref.read(subscriptionsControllerProvider.notifier).save(
          subscription.copyWith(status: SubscriptionStatus.cancelled),
        );
  }

  Future<void> _delete(Subscription subscription) async {
    final ok = await confirmAction(
      context,
      title: 'حذف اشتراك',
      message: 'حذف هذا الاشتراك نهائياً؟',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(subscriptionsControllerProvider.notifier).delete(subscription.id);
  }

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(subscriptionsControllerProvider);
    final members = ref.watch(membersControllerProvider).value ?? const [];
    final plans = ref.watch(plansControllerProvider).value ?? const [];
    final memberName = {for (final m in members) m.id: m.fullName};
    final planName = {for (final p in plans) p.id: p.name};

    return WebPage(
      title: 'الاشتراكات',
      subtitle: 'اشتراكات الأعضاء والمدفوعات المرتبطة',
      onRefresh: () {
        ref.invalidate(subscriptionsControllerProvider);
        ref.invalidate(membersControllerProvider);
        ref.invalidate(plansControllerProvider);
      },
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add),
          label: const Text('اشتراك جديد'),
        ),
      ],
      child: subsAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل الاشتراكات',
          onRetry: () => ref.invalidate(subscriptionsControllerProvider),
        ),
        data: (subscriptions) {
          final query = _search.text.trim().toLowerCase();
          final filtered = subscriptions.where((s) {
            final name = (memberName[s.memberId] ?? '').toLowerCase();
            final plan = (planName[s.planId] ?? '').toLowerCase();
            final matchesSearch =
                query.isEmpty || name.contains(query) || plan.contains(query);
            final matchesStatus = _status == null || s.status == _status;
            return matchesSearch && matchesStatus;
          }).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return WebTableShell(
            title: 'قائمة الاشتراكات (${filtered.length})',
            searchController: _search,
            searchLabel: 'بحث بالعضو أو الباقة...',
            filters: _filters(context),
            child: filtered.isEmpty
                ? const EmptyState(title: 'لا توجد اشتراكات',
                    subtitle: 'غيّر البحث أو الفلاتر')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('العضو')),
                        DataColumn(label: Text('الباقة')),
                        DataColumn(label: Text('البداية')),
                        DataColumn(label: Text('النهاية')),
                        DataColumn(label: Text('متبقي')),
                        DataColumn(label: Text('السعر')),
                        DataColumn(label: Text('الوسيلة')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final s in filtered)
                          DataRow(cells: [
                            DataCell(Text(memberName[s.memberId] ?? '—',
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(planName[s.planId] ?? '—')),
                            DataCell(Text(Formatters.date(s.startDate))),
                            DataCell(Text(Formatters.date(s.endDate))),
                            DataCell(Text(
                              s.status != SubscriptionStatus.active
                                  ? '—'
                                  : '${s.remainingDays} يوم',
                              style: TextStyle(
                                color: s.remainingDays <= 14
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(Text(Formatters.money(s.price))),
                            DataCell(Text(s.method == null ? '—' : _methodLabel(s.method!))),
                            DataCell(_statusText(s.status)),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openForm(s),
                                ),
                                IconButton(
                                  tooltip: 'تجديد',
                                  icon: const Icon(
                                      Icons.replay_outlined, size: 20),
                                  onPressed: () => _renew(s),
                                ),
                                IconButton(
                                  tooltip: 'إلغاء',
                                  icon: const Icon(
                                      Icons.block_outlined, size: 20),
                                  onPressed: () => _cancel(s),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _delete(s),
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

  Widget _filters(BuildContext context) {
    final chips = <SubscriptionStatus?>[null, ...SubscriptionStatus.values];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final status in chips)
          ChoiceChip(
            label: Text(status == null ? 'الكل' : _statusLabel(status)),
            selected: _status == status,
            onSelected: (_) => setState(() => _status = status),
          ),
      ],
    );
  }
}

String _statusLabel(SubscriptionStatus status) => switch (status) {
      SubscriptionStatus.active => 'نشط',
      SubscriptionStatus.expired => 'منتهي',
      SubscriptionStatus.cancelled => 'ملغي',
    };

String _methodLabel(String key) => switch (key) {
      'cash' => 'نقدي',
      'card' => 'بطاقة',
      'wallet' => 'محفظة',
      'bank_transfer' => 'تحويل بنكي',
      _ => key,
    };

Widget _statusText(SubscriptionStatus status) {
  final color = switch (status) {
    SubscriptionStatus.active => const Color(0xFF2E7D32),
    SubscriptionStatus.expired => const Color(0xFFC62828),
    SubscriptionStatus.cancelled => Colors.blueGrey,
  };
  return Text(
    _statusLabel(status),
    style: TextStyle(color: color, fontWeight: FontWeight.w600),
  );
}

class _SubscriptionFormDialog extends ConsumerStatefulWidget {
  const _SubscriptionFormDialog({this.initial});

  final Subscription? initial;

  @override
  ConsumerState<_SubscriptionFormDialog> createState() =>
      _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState
    extends ConsumerState<_SubscriptionFormDialog> {
  final _form = GlobalKey<FormState>();
  String? _memberId;
  String? _planId;
  late DateTime _start;
  late DateTime _end;
  late double _price;
  late final _priceCtrl = TextEditingController(
      text: (widget.initial?.price ?? 0) == 0
          ? ''
          : (widget.initial?.price ?? 0).toString());
  late final _notes =
      TextEditingController(text: widget.initial?.notes ?? '');
  String? _method;
  late SubscriptionStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _memberId = widget.initial?.memberId;
    _planId = widget.initial?.planId;
    _start = widget.initial?.startDate ?? DateTime.now();
    _end = widget.initial?.endDate ??
        DateTime.now().add(const Duration(days: 30));
    _price = widget.initial?.price ?? 0;
    _method = widget.initial?.method;
    _status = widget.initial?.status ?? SubscriptionStatus.active;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _applyPlan(String? planId) {
    final plans = ref.read(plansControllerProvider).value ?? const [];
    final plan = plans.where((p) => p.id == planId).firstOrNull;
    setState(() {
      _planId = planId;
      if (plan != null) {
        _price = plan.price;
        _priceCtrl.text = plan.price == 0 ? '' : plan.price.toString();
        _end = _start.add(Duration(days: plan.durationDays));
      }
    });
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    _price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final subscription = Subscription(
        id: widget.initial?.id ?? '',
        memberId: _memberId!,
        planId: _planId!,
        startDate: _start,
        endDate: _end,
        price: _price,
        method: _method,
        status: _status,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        createdAt: widget.initial?.createdAt,
      );
      final notifier = ref.read(subscriptionsControllerProvider.notifier);
      if (widget.initial == null) {
        await notifier.add(subscription);
      } else {
        await notifier.save(subscription);
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
    final members = ref.watch(membersControllerProvider).value ?? const [];
    final plans = ref.watch(plansControllerProvider).value ?? const [];

    return WebFormDialog(
      title: widget.initial == null ? 'اشتراك جديد' : 'تعديل الاشتراك',
      saving: _saving,
      onSave: _submit,
      width: 640,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormRow(children: [
              FormDropdown<String>(
                label: 'العضو *',
                value: _memberId,
                items: [
                  for (final m in members)
                    DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                ],
                onChanged: (v) => setState(() => _memberId = v),
              ),
              FormDropdown<String>(
                label: 'الباقة *',
                value: _planId,
                items: [
                  for (final p in plans)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: _applyPlan,
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              FormDateField(
                label: 'تاريخ البداية',
                value: _start,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _start = v;
                    final selected =
                        ref.read(plansControllerProvider).value ?? const [];
                    final plan =
                        selected.where((p) => p.id == _planId).firstOrNull;
                    _end = v.add(Duration(
                        days: plan?.durationDays ?? 30));
                  });
                },
              ),
              FormDateField(
                label: 'تاريخ النهاية',
                value: _end,
                onChanged: (v) => setState(() => _end = v ?? _end),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر (ج.م) *'),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  return (n == null || n < 0) ? 'رقم صالح' : null;
                },
              ),
              FormDropdown<String>(
                label: 'وسيلة الدفع',
                value: _method,
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('—')),
                  for (final m in const ['cash', 'card', 'wallet', 'bank_transfer'])
                    DropdownMenuItem(value: m, child: Text(_methodLabel(m))),
                ],
                onChanged: (v) => setState(() => _method = v),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              FormDropdown<String>(
                label: 'الحالة',
                value: _status.key,
                items: [
                  for (final s in SubscriptionStatus.values)
                    DropdownMenuItem(value: s.key, child: Text(_statusLabel(s))),
                ],
                onChanged: (v) => setState(() => _status = SubscriptionStatus.fromKey(v)),
              ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}