import 'package:flutter/material.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/features/payments/presentation/payment_fields.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/services/payment/payment_gateway.dart';

/// Shows the gateway result inside a dismissible dialog. Failed receipts get
/// a danger variant so the error path is clearly visible in demos.
Future<void> showReceiptDialog(
  BuildContext context, {
  required PaymentReceipt receipt,
  required AppStrings strings,
  String? footerNote,
}) {
  final succeeded = receipt.status == PaymentStatus.paid ||
      receipt.status == PaymentStatus.pending;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        icon: Icon(
          succeeded ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 56,
          color: succeeded ? AppColors.success : AppColors.danger,
        ),
        title: Text(succeeded ? strings.paymentSuccess : strings.paymentFailed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.receipt,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Text(
              Formatters.money(receipt.amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(paymentMethodIcon(receipt.method),
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(strings.paymentMethodLabel(receipt.method)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${strings.reference}: ${receipt.reference}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (receipt.cardLast4 != null) ...[
              const SizedBox(height: 4),
              Text('•••• ${receipt.cardLast4}',
                  style: theme.textTheme.bodySmall),
            ],
            if (footerNote != null) ...[
              const SizedBox(height: 4),
              Text(footerNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.confirm),
          ),
        ],
      );
    },
  );
}