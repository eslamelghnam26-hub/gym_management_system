import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/validators.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';

class TrainerFormScreen extends ConsumerStatefulWidget {
  const TrainerFormScreen({super.key, this.trainer});

  final Trainer? trainer;

  @override
  ConsumerState<TrainerFormScreen> createState() => _TrainerFormScreenState();
}

class _TrainerFormScreenState extends ConsumerState<TrainerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _specializationController;
  late final TextEditingController _salaryController;
  late final TextEditingController _scheduleController;
  bool _submitting = false;

  bool get _isEditing => widget.trainer != null;

  @override
  void initState() {
    super.initState();
    final t = widget.trainer;
    _nameController = TextEditingController(text: t?.name ?? '');
    _phoneController = TextEditingController(text: t?.phone ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _specializationController =
        TextEditingController(text: t?.specialization ?? '');
    _salaryController = TextEditingController(
        text: t == null
            ? ''
            : (t.salary == t.salary.roundToDouble()
                ? '${t.salary.toInt()}'
                : '${t.salary}'));
    _scheduleController = TextEditingController(text: t?.schedule ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _salaryController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final strings = ref.read(appStringsProvider);
    try {
      final trainer = Trainer(
        id: widget.trainer?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        specialization: _specializationController.text.trim().isEmpty
            ? null
            : _specializationController.text.trim(),
        salary: double.tryParse(_salaryController.text.trim()) ?? 0,
        schedule: _scheduleController.text.trim().isEmpty
            ? null
            : _scheduleController.text.trim(),
      );
      if (_isEditing) {
        await ref.read(trainersControllerProvider.notifier).save(trainer);
      } else {
        await ref.read(trainersControllerProvider.notifier).add(trainer);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.savedSuccess),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      final code = e is AppException ? e.code : 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.errorMessage(code)),
            backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? strings.edit : strings.add)),
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
                      controller: _nameController,
                      label: strings.fullName,
                      hint: strings.fullName,
                      prefixIcon: Icons.person_outline,
                      validator: Validators.required,
                      textInputAction: TextInputAction.next,
                    ),
                    AppTextField(
                      controller: _phoneController,
                      label: strings.phone,
                      hint: '01xxxxxxxxx',
                      prefixIcon: Icons.phone_outlined,
                      validator: Validators.required,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    AppTextField(
                      controller: _emailController,
                      label: strings.email,
                      hint: 'mail@example.com',
                      prefixIcon: Icons.mail_outline,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    AppTextField(
                      controller: _specializationController,
                      label: strings.specialization,
                      hint: strings.specialization,
                      prefixIcon: Icons.workspace_premium_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    AppTextField(
                      controller: _salaryController,
                      label: strings.salary,
                      hint: '6000',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                    AppTextField(
                      controller: _scheduleController,
                      label: strings.schedule,
                      hint: 'كل يوم 10ص - 6م',
                      prefixIcon: Icons.schedule_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: strings.save,
                      loading: _submitting,
                      onPressed: _submit,
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