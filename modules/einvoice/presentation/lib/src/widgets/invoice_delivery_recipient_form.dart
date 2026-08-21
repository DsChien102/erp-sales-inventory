import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/send_invoice_copy.dart';

/// Shared recipient field + primary/cancel actions for send/resend sheets.
///
/// Not a public specimen widget — used by [SendInvoiceSheet] /
/// [ResendInvoiceSheet] only.
class InvoiceDeliveryRecipientForm extends StatelessWidget {
  const InvoiceDeliveryRecipientForm({
    super.key,
    required this.emailController,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onCancel,
    this.isLoading = false,
    this.showValidationError = false,
    this.onEmailChanged,
    this.header,
    this.footerAboveActions,
  });

  final TextEditingController emailController;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool showValidationError;
  final ValueChanged<String>? onEmailChanged;
  final Widget? header;
  final Widget? footerAboveActions;

  @override
  Widget build(BuildContext context) {
    final canSubmit = !isLoading &&
        !showValidationError &&
        SendInvoiceCopy.isValidEmail(emailController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[
          header!,
          const VGap.md(),
        ],
        VTextField(
          key: const Key('field_recipient_email'),
          controller: emailController,
          label: SendInvoiceCopy.recipientLabel,
          isRequired: true,
          hintText: SendInvoiceCopy.recipientPlaceholder,
          helperText:
              showValidationError ? null : SendInvoiceCopy.recipientHelper,
          errorText:
              showValidationError ? SendInvoiceCopy.recipientInvalid : null,
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
          onChanged: onEmailChanged,
        ),
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
          isLoading: isLoading,
          onPressed: canSubmit ? onPrimary : null,
        ),
        const VGap.sm(),
        VButton(
          key: const Key('action_cancel_send'),
          label: SendInvoiceCopy.cancelAction,
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: onCancel,
        ),
      ],
    );
  }
}
