import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/widgets/app_button.dart';
import 'package:gym_management_system/core/widgets/app_text_field.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/providers/announcements_provider.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key});

  @override
  ConsumerState<AnnouncementFormScreen> createState() =>
      _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState
    extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  AnnouncementAudience _audience = AnnouncementAudience.all;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final announcement = Announcement(
        id: '',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        audience: _audience,
      );
      await ref
          .read(announcementsControllerProvider.notifier)
          .add(announcement);
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
      appBar: AppBar(title: Text(strings.newAnnouncement)),
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
                      controller: _titleController,
                      label: strings.announcementTitle,
                      hint: strings.announcementTitle,
                      prefixIcon: Icons.campaign_outlined,
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true) ? 'required' : null,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _bodyController,
                      label: strings.announcementBody,
                      hint: strings.announcementBody,
                      prefixIcon: Icons.notes,
                      maxLines: 5,
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true) ? 'required' : null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AnnouncementAudience>(
                      initialValue: _audience,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      items: [
                        for (final a in AnnouncementAudience.values)
                          DropdownMenuItem(
                            value: a,
                            child: Text(strings.audienceLabel(a)),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        if (v != null) _audience = v;
                      }),
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