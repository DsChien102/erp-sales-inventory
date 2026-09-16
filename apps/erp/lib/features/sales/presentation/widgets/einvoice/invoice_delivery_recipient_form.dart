import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/order_invoice_delivery_copy.dart';

/// Shared recipient field + primary/cancel actions for app-owned SG-07 sheets.
class InvoiceDeliveryRecipientForm extends StatelessWidget {
  const InvoiceDeliveryRecipientForm({
    super.key,
    required this.emailController,
    required this.primaryLabel,
    required this.isSubmitting,
    required this.operationLocked,
    required this.showValidationError,
    required this.onChanged,
    required this.onPrimary,
    required this.onCancel,
    this.sourceLabel,
    this.footerAboveActions,
  });

  final TextEditingController emailController;
  final String primaryLabel;
  final bool isSubmitting;
  final bool operationLocked;
  final bool showValidationError;
  final ValueChanged<String> onChanged;
  final VoidCallback? onPrimary;
  final VoidCallback? onCancel;
  final Widget? sourceLabel;
  final Widget? footerAboveActions;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final fieldLocked = isSubmitting || operationLocked;
    final canSubmit =
        !isSubmitting &&
        !operationLocked &&
        !showValidationError &&
        OrderInvoiceDeliveryCopy.isValidEmail(emailController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VTextField(
          key: const Key('field_recipient_email'),
          controller: emailController,
          label: OrderInvoiceDeliveryCopy.recipientLabel,
          isRequired: true,
          hintText: OrderInvoiceDeliveryCopy.recipientPlaceholder,
          helperText: showValidationError ? null : OrderInvoiceDeliveryCopy.recipientHelper,
          errorText: showValidationError ? OrderInvoiceDeliveryCopy.recipientInvalid : null,
          enabled: !fieldLocked,
          keyboardType: TextInputType.emailAddress,
          onChanged: fieldLocked ? null : onChanged,
        ),
        if (sourceLabel != null) ...[
          const VGap.xs(),
          DefaultTextStyle.merge(
            style: TextStyle(color: colors.textSecondary),
            child: sourceLabel!,
          ),
        ],
        if (footerAboveActions != null) ...[
          const VGap.md(),
          footerAboveActions!,
        ],
        const VGap.lg(),
        VButton(
          key: const Key('action_send_invoice'),
          label: primaryLabel,
          variant: VButtonVariant.primary,
          fullWidth: true,
          isLoading: isSubmitting,
          onPressed: canSubmit ? onPrimary : null,
        ),
        const VGap.sm(),
        VButton(
          key: const Key('action_cancel_send'),
          label: OrderInvoiceDeliveryCopy.cancelAction,
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: isSubmitting ? null : onCancel,
        ),
      ],
    );
  }
}
