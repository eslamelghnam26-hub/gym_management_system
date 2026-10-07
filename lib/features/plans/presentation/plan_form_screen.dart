import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/validators.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/providers/plans_provider.dart';

class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key, this.plan});

  final MembershipPlan? plan;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late final TextEditingController _featureController;
  late final List<String> _features;
  bool _unlimitedSessions = false;
  late bool _isActive;
  bool _submitting = false;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _durationController = TextEditingController(
        text: plan == null ? '30' : '${plan.durationDays}');
    _priceController = TextEditingController(
        text: plan == null
            ? ''
            : (plan.price == plan.price.roundToDouble()
                ? '${plan.price.toInt()}'
                : '${plan.price}'));
    _featureController = TextEditingController();
    _features = List.of(plan?.features ?? []);
    _unlimitedSessions = plan?.isUnlimitedSessions ?? true;
    _isActive = plan?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  void _addFeature() {
    final value = _featureController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _features.add(value);
      _featureController.clear();
    });
  }

  void _removeFeature(int index) {
    setState(() => _features.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final strings = ref.read(appStringsProvider);
    try {
      final plan = MembershipPlan(
        id: widget.plan?.id ?? '',
        name: _nameController.text.trim(),
        durationDays: int.tryParse(_durationController.text.trim()) ?? 30,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        sessions: _unlimitedSessions ? 0 : 12,
        features: _features,
        isActive: _isActive,
      );
      if (_isEditing) {
        await ref.read(plansControllerProvider.notifier).save(plan);
      } else {
        await ref.read(plansControllerProvider.notifier).add(plan);
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
                      label: strings.planName,
                      hint: strings.planName,
                      prefixIcon: Icons.card_membership_outlined,
                      validator: Validators.required,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _durationController,
                            label: strings.duration,
                            hint: '30',
                            prefixIcon: Icons.schedule_outlined,
                            validator: (value) => Validators.required(
                                value), // numeric validated on submit
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _priceController,
                            label: strings.price,
                            hint: '1000',
                            prefixIcon: Icons.payments_outlined,
                            validator: (value) => Validators.required(value),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.sessionsUnlimited),
                      subtitle: Text(strings.sessions),
                      value: _unlimitedSessions,
                      onChanged: (value) =>
                          setState(() => _unlimitedSessions = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.activeToggle),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.features,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < _features.length; i++)
                          InputChip(
                            label: Text(_features[i]),
                            onDeleted: () => _removeFeature(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _featureController,
                            label: strings.addFeature,
                            hint: strings.addFeature,
                            prefixIcon: Icons.add_box_outlined,
                            onSubmitted: (_) => _addFeature(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: strings.addFeature,
                          onPressed: _addFeature,
                          icon: const Icon(Icons.add),
                        ),
                      ],
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