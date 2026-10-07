import 'package:flutter/material.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/models/member.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final MemberStatus status;

  Color get _color => switch (status) {
        MemberStatus.active => AppColors.success,
        MemberStatus.expired => AppColors.danger,
        MemberStatus.pending => AppColors.accent,
        MemberStatus.cancelled => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        arabic ? status.labelAr : status.labelEn,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}