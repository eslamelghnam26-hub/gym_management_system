import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/gym_settings.dart';
import 'package:gym_management_system/providers/gym_settings_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

/// Knowledge base the AI assistant answers from: services, house rules and
/// FAQs. Edits are saved into the shared `gym_settings` document so the
/// mobile app can consume the same content later.
class AiKnowledgePage extends ConsumerStatefulWidget {
  const AiKnowledgePage({super.key});

  @override
  ConsumerState<AiKnowledgePage> createState() => _AiKnowledgePageState();
}

class _AiKnowledgePageState extends ConsumerState<AiKnowledgePage> {
  bool _initialized = false;
  bool _saving = false;
  final List<TextEditingController> _services = [];
  final List<TextEditingController> _rules = [];
  final List<(TextEditingController, TextEditingController)> _faqs = [];

  @override
  void dispose() {
    for (final c in [..._services, ..._rules, ..._faqs.expand((f) => [f.$1, f.$2])]) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(GymSettings settings) {
    if (_initialized) return;
    _services
      ..clear()
      ..addAll([for (final s in settings.services) TextEditingController(text: s)]);
    _rules
      ..clear()
      ..addAll([for (final r in settings.rules) TextEditingController(text: r)]);
    _faqs
      ..clear()
      ..addAll([
        for (final f in settings.faqs)
          (
            TextEditingController(text: f.question),
            TextEditingController(text: f.answer),
          ),
      ]);
    _initialized = true;
  }

  Future<void> _save() async {
    final settings = ref.read(gymSettingsProvider).value;
    if (settings == null) return;
    setState(() => _saving = true);
    try {
      final updated = settings.copyWith(
        services: [for (final c in _services) c.text.trim()].where((s) => s.isNotEmpty).toList(),
        rules: [for (final c in _rules) c.text.trim()].where((s) => s.isNotEmpty).toList(),
        faqs: [
          for (final f in _faqs)
            if (f.$1.text.trim().isNotEmpty && f.$2.text.trim().isNotEmpty)
              KnowledgeFaq(question: f.$1.text.trim(), answer: f.$2.text.trim()),
        ],
      );
      await ref.read(gymSettingsProvider.notifier).save(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ قاعدة المعرفة')),
      );
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
    final settingsAsync = ref.watch(gymSettingsProvider);

    return WebPage(
      title: 'ذكاء الجيم (AI)',
      subtitle: 'يستجيب المساعد الذكي من هذه القاعدة المعرفية',
      onRefresh: () => ref.invalidate(gymSettingsProvider),
      actions: [
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('حفظ'),
        ),
      ],
      child: settingsAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل الإعدادات',
          onRetry: () => ref.invalidate(gymSettingsProvider),
        ),
        data: (settings) {
          _init(settings);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionCard(
                context,
                icon: Icons.fitness_center_outlined,
                title: 'خدمات الجيم',
                hint: 'مثال: تدريب شخصي، تغذية، كروس فيت',
                addLabel: 'إضافة خدمة',
                onAdd: () => setState(() => _services.add(TextEditingController())),
                children: [
                  for (var i = 0; i < _services.length; i++)
                    _row(
                      controller: _services[i],
                      onDelete: () => setState(() {
                        _services.removeAt(i).dispose();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionCard(
                context,
                icon: Icons.rule_outlined,
                title: 'قواعد النادي',
                hint: 'مثال: يُمنع التصوير داخل الصالات',
                addLabel: 'إضافة قاعدة',
                onAdd: () => setState(() => _rules.add(TextEditingController())),
                children: [
                  for (var i = 0; i < _rules.length; i++)
                    _row(
                      controller: _rules[i],
                      onDelete: () => setState(() {
                        _rules.removeAt(i).dispose();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionCard(
                context,
                icon: Icons.help_outline,
                title: 'الأسئلة الشائعة',
                hint: 'أسئلة وأجوبة يجيب عليها المساعد تلقائيًا',
                addLabel: 'إضافة سؤال',
                onAdd: () => setState(
                  () => _faqs.add((TextEditingController(), TextEditingController())),
                ),
                children: [
                  for (var i = 0; i < _faqs.length; i++)
                    _faqRow(i),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String hint,
    required String addLabel,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(hint, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(addLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'لا توجد عناصر — أضف أول عنصر',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }

  Widget _row({required TextEditingController controller, required VoidCallback onDelete}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(isDense: true),
          ),
        ),
        IconButton(
          tooltip: 'حذف',
          onPressed: onDelete,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
        ),
      ],
    );
  }

  Widget _faqRow(int index) {
    final (q, a) = _faqs[index];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: q,
                decoration: const InputDecoration(
                  labelText: 'السؤال',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: 'حذف',
              onPressed: () => setState(() {
                q.dispose();
                a.dispose();
                _faqs.removeAt(index);
              }),
              icon: const Icon(Icons.remove_circle_outline, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: a,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'الإجابة',
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}