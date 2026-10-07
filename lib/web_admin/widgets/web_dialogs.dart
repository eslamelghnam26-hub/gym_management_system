import 'package:flutter/material.dart';

/// Shared scrollable web form dialog: title header, scrollable body and a
/// footer with Cancel/Save. Pages wire their form fields + async submit
/// through [onSave] and disable it with [saving].
class WebFormDialog extends StatelessWidget {
  const WebFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.saving = false,
    this.width = 600,
    this.saveLabel = 'حفظ',
    this.hint,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final bool saving;
  final double width;
  final String saveLabel;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(hint!, style: theme.textTheme.bodySmall),
              ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(saving ? 'جارٍ الحفظ...' : saveLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic table card shell used by all admin list pages: header with title +
/// actions, optional search field and filter chips, then the table body.
class WebTableShell extends StatelessWidget {
  const WebTableShell({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.searchLabel,
    this.searchController,
    this.filters,
    this.child,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final String? searchLabel;
  final TextEditingController? searchController;
  final Widget? filters;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          if (searchController != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: searchLabel ?? 'بحث...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
          if (filters != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: filters,
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(14),
            child: child ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Compact labeled dropdown used inside admin forms.
class FormDropdown<T> extends StatelessWidget {
  const FormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}

/// Row of two equal-width fields (responsive to a single column).
class FormRow extends StatelessWidget {
  const FormRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final children = this.children;
      if (constraints.maxWidth < 420 || children.length <= 1) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              children[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: children[i]),
          ],
        ],
      );
    });
  }
}

/// Read-only date field opening a date picker on tap; supports clearing.
class FormDateField extends StatelessWidget {
  const FormDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.allowClear = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null && allowClear)
              IconButton(
                tooltip: 'مسح',
                icon: const Icon(Icons.cancel_outlined, size: 18),
                onPressed: () => onChanged(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            IconButton(
              tooltip: 'اختيار تاريخ',
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? DateTime.now(),
                  firstDate: firstDate ?? DateTime(2000),
                  lastDate: lastDate ?? DateTime(2100),
                  locale: Localizations.maybeLocaleOf(context),
                );
                if (picked != null) onChanged(picked);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
      isEmpty: value == null,
      child: value == null
          ? const Text('غير محدد')
          : Text(
              value!.toIso8601String().split('T').first,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodyMedium,
            ),
    );
  }
}