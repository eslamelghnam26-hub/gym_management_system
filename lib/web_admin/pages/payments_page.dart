import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/payments_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/subscriptions_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _search = TextEditingController();
  PaymentStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm(Payment? payment) async {
    await showDialog(
      context: context,
      builder: (_) => _PaymentFormDialog(initial: payment),
    );
  }

  Future<void> _refund(Payment payment) async {
    final ok = await confirmAction(
      context,
      title: 'استرداد دفعة',
      message:
          'تمييز دفعة «${Formatters.money(payment.amount)}» كمسترجعة؟',
      confirmLabel: 'استرداد',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(paymentsControllerProvider.notifier).refund(payment.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استرداد الدفعة')),
    );
  }

  Future<void> _delete(Payment payment) async {
    final ok = await confirmAction(
      context,
      title: 'حذف دفعة',
      message: 'حذف هذه الدفعة نهائياً؟',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(paymentsControllerProvider.notifier).delete(payment.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الدفعة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsControllerProvider);
    final members = ref.watch(membersControllerProvider).value ?? const [];
    final memberName = {for (final m in members) m.id: m.fullName};

    return WebPage(
      title: 'المدفوعات',
      subtitle: 'كل عمليات الدفع والاسترداد',
      onRefresh: () {
        ref.invalidate(paymentsControllerProvider);
        ref.invalidate(membersControllerProvider);
      },
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add),
          label: const Text('إضافة دفعة'),
        ),
      ],
      child: paymentsAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل المدفوعات',
          onRetry: () => ref.invalidate(paymentsControllerProvider),
        ),
        data: (payments) {
          final query = _search.text.trim().toLowerCase();
          final filtered = payments.where((p) {
            final name = (memberName[p.memberId] ?? '').toLowerCase();
            final reference = (p.reference ?? '').toLowerCase();
            final matchesSearch = query.isEmpty ||
                name.contains(query) ||
                reference.contains(query);
            final matchesStatus = _status == null || p.status == _status;
            return matchesSearch && matchesStatus;
          }).toList();
          final totalPaid = filtered
              .where((p) => p.status == PaymentStatus.paid)
              .fold<double>(0, (sum, p) => sum + p.amount);

          return WebTableShell(
            title: 'قائمة المدفوعات (${filtered.length})',
            subtitle: 'إجمالي المدفوع فيهذه القائمة: ${Formatters.money(totalPaid)}',
            searchController: _search,
            searchLabel: 'بحث بالعضو أو رقم العملية...',
            filters: _filters(context),
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'لا توجد مدفوعات', subtitle: 'غيّر البحث أو الفلاتر')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('العضو')),
                        DataColumn(label: Text('المبلغ')),
                        DataColumn(label: Text('الوسيلة')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('رقم العملية')),
                        DataColumn(label: Text('ملاحظة')),
                        DataColumn(label: Text('التاريخ')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final p in filtered)
                          DataRow(cells: [
                            DataCell(Text(memberName[p.memberId] ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(Formatters.money(p.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(_methodLabel(p.method))),
                            DataCell(_paymentStatusText(p.status)),
                            DataCell(Text(p.reference ?? '—')),
                            DataCell(Text(
                              p.note ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(Text(
                                Formatters.dateTime(p.createdAt))),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openForm(p),
                                ),
                                if (p.status != PaymentStatus.refunded)
                                  IconButton(
                                    tooltip: 'استرداد',
                                    icon: const Icon(Icons.undo_outlined, size: 20),
                                    onPressed: () => _refund(p),
                                  ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _delete(p),
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
    final chips = <PaymentStatus?>[null, ...PaymentStatus.values];
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

String _statusLabel(PaymentStatus status) => switch (status) {
      PaymentStatus.paid => 'مدفوع',
      PaymentStatus.pending => 'معلق',
      PaymentStatus.refunded => 'مسترجع',
      PaymentStatus.failed => 'فاشل',
    };

String _methodLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.card => 'بطاقة',
      PaymentMethod.wallet => 'محفظة',
      PaymentMethod.bankTransfer => 'تحويل بنكي',
    };

Widget _paymentStatusText(PaymentStatus status) {
  final color = switch (status) {
    PaymentStatus.paid => const Color(0xFF2E7D32),
    PaymentStatus.pending => const Color(0xFFFF8F00),
    PaymentStatus.refunded => Colors.blueGrey,
    PaymentStatus.failed => const Color(0xFFC62828),
  };
  return Text(
    _statusLabel(status),
    style: TextStyle(color: color, fontWeight: FontWeight.w600),
  );
}

class _PaymentFormDialog extends ConsumerStatefulWidget {
  const _PaymentFormDialog({this.initial});

  final Payment? initial;

  @override
  ConsumerState<_PaymentFormDialog> createState() =>
      _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<_PaymentFormDialog> {
  final _form = GlobalKey<FormState>();
  String? _memberId;
  String? _subscriptionId;
  late final _amount = TextEditingController(
      text: (widget.initial?.amount ?? 0) == 0
          ? ''
          : (widget.initial?.amount ?? 0).toString());
  late PaymentMethod _method;
  late PaymentStatus _status;
  late final _reference =
      TextEditingController(text: widget.initial?.reference ?? '');
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _memberId = widget.initial?.memberId;
    _subscriptionId = widget.initial?.subscriptionId;
    _method = widget.initial?.method ?? PaymentMethod.cash;
    _status = widget.initial?.status ?? PaymentStatus.paid;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر العضو أولاً')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payment = Payment(
        id: widget.initial?.id ?? '',
        memberId: _memberId!,
        subscriptionId: _subscriptionId,
        amount: double.parse(_amount.text.trim()),
        method: _method,
        status: _status,
        reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: widget.initial?.createdAt,
      );
      final notifier = ref.read(paymentsControllerProvider.notifier);
      if (widget.initial == null) {
        await notifier.add(payment);
      } else {
        await notifier.save(payment);
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
    final subscriptions = ref.watch(subscriptionsControllerProvider).value ?? const [];
    final plans = ref.watch(plansControllerProvider).value ?? const [];
    final memberName = {for (final m in members) m.id: m.fullName};
    final planName = {for (final p in plans) p.id: p.name};

    final memberSubs = _memberId == null
        ? const <String, dynamic>{}
        : {
            for (final s in subscriptions)
              if (s.memberId == _memberId)
                s.id: '${memberName[s.memberId] ?? ''} — ${planName[s.planId] ?? '?'}',
          };

    return WebFormDialog(
      title: widget.initial == null ? 'إضافة دفعة' : 'تعديل الدفعة',
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
                onChanged: (v) => setState(() {
                  _memberId = v;
                  _subscriptionId = null;
                }),
              ),
              FormDropdown<String>(
                label: 'الاشتراك المرتبط',
                value: _subscriptionId,
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('بدون')),
                  for (final entry in memberSubs.entries)
                    DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _subscriptionId = v),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ (ج.م) *'),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  return (n == null || n <= 0) ? 'رقم صالح' : null;
                },
              ),
              FormDropdown<String>(
                label: 'الوسيلة',
                value: _method.key,
                items: [
                  for (final m in PaymentMethod.values)
                    DropdownMenuItem(value: m.key, child: Text(_methodLabel(m))),
                ],
                onChanged: (v) => setState(() {
                  _method = PaymentMethod.fromKey(v);
                }),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              FormDropdown<String>(
                label: 'الحالة',
                value: _status.key,
                items: [
                  for (final s in PaymentStatus.values)
                    DropdownMenuItem(value: s.key, child: Text(_statusLabel(s))),
                ],
                onChanged: (v) => setState(() {
                  _status = PaymentStatus.fromKey(v);
                }),
              ),
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'رقم العملية (معرف التتبع)',
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'ملاحظة'),
            ),
          ],
        ),
      ),
    );
  }
}