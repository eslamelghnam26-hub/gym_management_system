import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/utils/validators.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';

class MemberFormScreen extends ConsumerStatefulWidget {
  const MemberFormScreen({super.key, this.member});

  final Member? member;

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyController;
  late final TextEditingController _notesController;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _trainerId;
  String? _planId;
  DateTime _startDate = DateTime.now();
  MemberStatus _status = MemberStatus.pending;
  bool _submitting = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _nameController = TextEditingController(text: m?.fullName ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _emailController = TextEditingController(text: m?.email ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _emergencyController =
        TextEditingController(text: m?.emergencyContact ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');
    _dateOfBirth = m?.dateOfBirth;
    _gender = m?.gender;
    _trainerId = m?.trainerId;
    _planId = m?.planId;
    _startDate = m?.startDate ?? DateTime.now();
    _status = m?.status ?? MemberStatus.pending;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _endDate {
    final plan = _planId == null
        ? null
        : ref.read(plansControllerProvider.notifier).byId(_planId!);
    final days = plan?.durationDays;
    if (days == null) return _startDate;
    return _startDate.add(Duration(days: days));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: ref.read(appStringsProvider).startDate,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: ref.read(appStringsProvider).dateOfBirth,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final strings = ref.read(appStringsProvider);
    try {
      final member = Member(
        id: widget.member?.id ?? '',
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        emergencyContact: _emergencyController.text.trim().isEmpty
            ? null
            : _emergencyController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        trainerId: _trainerId,
        planId: _planId,
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
      );
      if (_isEditing) {
        await ref.read(membersControllerProvider.notifier).save(member);
      } else {
        await ref.read(membersControllerProvider.notifier).add(member);
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
    final trainersResult = ref.watch(trainersControllerProvider);
    final plansResult = ref.watch(plansControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? strings.edit : strings.add),
      ),
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
                      controller: _addressController,
                      label: strings.address,
                      hint: strings.address,
                      prefixIcon: Icons.place_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    AppTextField(
                      controller: _emergencyController,
                      label: strings.emergencyContact,
                      hint: strings.emergencyContact,
                      prefixIcon: Icons.emergency_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: _dropdownDecoration(strings.gender,
                                Icons.wc_outlined),
                            items: [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text(strings.male),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text(strings.female),
                              ),
                            ],
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TapPickerField(
                            label: strings.dateOfBirth,
                            value: _dateOfBirth == null
                                ? null
                                : Formatters.date(_dateOfBirth!),
                            onTap: _pickDob,
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _trainerId,
                      decoration:
                          _dropdownDecoration(strings.assignedTrainer),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(strings.selectTrainer,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ),
                        for (final trainer in trainersResult.value ??
                            const <Trainer>[])
                          DropdownMenuItem(
                            value: trainer.id,
                            child: Text(trainer.name),
                          ),
                      ],
                      onChanged: (v) => setState(() => _trainerId = v),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _planId,
                      decoration: _dropdownDecoration(strings.plan),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(strings.selectPlan,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ),
                        for (final plan in plansResult.value ??
                            const <MembershipPlan>[])
                          DropdownMenuItem(
                            value: plan.id,
                            child: Text('${plan.name} — ${Formatters.money(plan.price)}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _planId = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _TapPickerField(
                            label: strings.startDate,
                            value: Formatters.date(_startDate),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TapPickerField(
                            label: strings.endDate,
                            value: Formatters.date(_endDate),
                            onTap: _pickDate,
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<MemberStatus>(
                      initialValue: _status,
                      decoration: _dropdownDecoration(strings.status),
                      items: [
                        for (final status in MemberStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(strings, status)),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _status = v ?? _status),
                    ),
                    AppTextField(
                      controller: _notesController,
                      label: strings.notes,
                      hint: strings.notes,
                      prefixIcon: Icons.notes,
                      maxLines: 3,
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

  InputDecoration _dropdownDecoration(String label, [IconData? icon]) =>
      InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 22) : null,
      );

  String _statusLabel(AppStrings strings, MemberStatus status) {
    return switch (status) {
      MemberStatus.active => strings.statusActive,
      MemberStatus.expired => strings.statusExpired,
      MemberStatus.pending => strings.statusPending,
      MemberStatus.cancelled => strings.statusCancelled,
    };
  }
}

class _TapPickerField extends StatelessWidget {
  const _TapPickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
          child: Text(
            value ?? '—',
            style: TextStyle(
              color: value == null ? Colors.grey : null,
            ),
          ),
        ),
      ),
    );
  }
}