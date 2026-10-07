import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/providers/expenses_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  final _search = TextEditingController();
  ExpenseCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm(Expense? expense) async {
    await showDialog(
      context: context,
      builder: (_) => _ExpenseFormDialog(initial: expense),
    );
  }

  Future<void> _delete(Expense expense) async {
    final ok = await confirmAction(
      context,
      title: 'حذف مصروف',
      message: 'حذف مصروف ${Formatters.money(expense.amount)}؟',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(expensesControllerProvider.notifier).delete(expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesControllerProvider);

    return WebPage(
      title: 'المصروفات',
      subtitle: 'الرواتب والإيجار والمصروفات التشغيلية',
      onRefresh: () => ref.invalidate(expensesControllerProvider),
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add),
          label: const Text('إضافة مصروف'),
        ),
      ],
      child: expensesAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل المصروفات',
          onRetry: () => ref.invalidate(expensesControllerProvider),
        ),
        data: (expenses) {
          final query = _search.text.trim().toLowerCase();
          final filtered = expenses.where((e) {
            final matchesSearch = query.isEmpty ||
                (e.note?.toLowerCase().contains(query) ?? false);
            final matchesCategory = _category == null || e.category == _category;
            return matchesSearch && matchesCategory;
          }).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);

          return WebTableShell(
            title: 'قائمة المصروفات (${filtered.length})',
            subtitle: 'الإجمالي: ${Formatters.money(total)}',
            searchController: _search,
            searchLabel: 'بحث في الملاحظات...',
            filters: _filters(context),
            child: filtered.isEmpty
                ? const EmptyState(title: 'لا توجد مصروفات', subtitle: 'غيّر البحث أو الفلاتر')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('الفئة')),
                        DataColumn(label: Text('المبلغ')),
                        DataColumn(label: Text('التاريخ')),
                        DataColumn(label: Text('ملاحظة')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final e in filtered)
                          DataRow(cells: [
                            DataCell(_categoryChip(context, e.category)),
                            DataCell(Text(Formatters.money(e.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(Formatters.date(e.date))),
                            DataCell(Text(
                              e.note ?? '—',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openForm(e),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _delete(e),
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
    final chips = <ExpenseCategory?>[null, ...ExpenseCategory.values];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final category in chips)
          ChoiceChip(
            label: Text(category == null ? 'الكل' : _categoryLabel(category)),
            selected: _category == category,
            onSelected: (_) => setState(() => _category = category),
          ),
      ],
    );
  }

  Widget _categoryChip(BuildContext context, ExpenseCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _categoryLabel(category),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

String _categoryLabel(ExpenseCategory category) => switch (category) {
      ExpenseCategory.salary => 'رواتب',
      ExpenseCategory.rent => 'إيجار',
      ExpenseCategory.equipment => 'معدات',
      ExpenseCategory.utilities => 'خدمات',
      ExpenseCategory.other => 'أخرى',
    };

class _ExpenseFormDialog extends ConsumerStatefulWidget {
  const _ExpenseFormDialog({this.initial});

  final Expense? initial;

  @override
  ConsumerState<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<_ExpenseFormDialog> {
  final _form = GlobalKey<FormState>();
  late ExpenseCategory _category;
  late final _amount = TextEditingController(
      text: (widget.initial?.amount ?? 0) == 0
          ? ''
          : (widget.initial?.amount ?? 0).toString());
  late DateTime _date;
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initial?.category ?? ExpenseCategory.other;
    _date = widget.initial?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final expense = Expense(
        id: widget.initial?.id ?? '',
        category: _category,
        amount: double.parse(_amount.text.trim()),
        date: _date,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: widget.initial?.createdAt,
      );
      final notifier = ref.read(expensesControllerProvider.notifier);
      if (widget.initial == null) {
        await notifier.add(expense);
      } else {
        await notifier.save(expense);
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
      title: widget.initial == null ? 'إضافة مصروف' : 'تعديل المصروف',
      saving: _saving,
      onSave: _submit,
      width: 560,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormRow(children: [
              FormDropdown<String>(
                label: 'الفئة',
                value: _category.key,
                items: [
                  for (final c in ExpenseCategory.values)
                    DropdownMenuItem(value: c.key, child: Text(_categoryLabel(c))),
                ],
                onChanged: (v) =>
                    setState(() => _category = ExpenseCategory.fromKey(v)),
              ),
              FormDateField(
                label: 'التاريخ',
                value: _date,
                onChanged: (v) => setState(() => _date = v ?? _date),
                lastDate: DateTime(2100),
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ (ج.م) *'),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                return (n == null || n <= 0) ? 'رقم صالح' : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظة'),
            ),
          ],
        ),
      ),
    );
  }
}