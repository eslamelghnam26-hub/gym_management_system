import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/providers/expenses_provider.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: ref.read(appStringsProvider).expenseDate,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final expense = Expense(
        id: '',
        category: _category,
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      await ref.read(expensesControllerProvider.notifier).add(expense);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(strings.savedSuccess),
        backgroundColor: AppColors.success,
      ));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.newExpense)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _amountController,
                      label: strings.amount,
                      hint: strings.amount,
                      prefixIcon: Icons.payments_outlined,
                      validator: (value) =>
                          (double.tryParse(value?.trim() ?? '') ?? 0) <= 0
                              ? 'required'
                              : null,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final c in ExpenseCategory.values)
                          DropdownMenuItem(
                            value: c,
                            child: Text(strings.expenseCategoryLabel(c)),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        if (v != null) _category = v;
                      }),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.event_outlined),
                          labelText: strings.expenseDate,
                        ),
                        child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _noteController,
                      label: strings.notes,
                      hint: strings.notes,
                      prefixIcon: Icons.notes,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: strings.save,
                      loading: _saving,
                      onPressed: _save,
                      icon: Icons.check,
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