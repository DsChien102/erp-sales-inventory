import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/send_invoice_copy.dart';
import 'invoice_delivery_recipient_form.dart';

/// Result of [showResendInvoiceSheet] when the user confirms.
class ResendInvoiceSheetResult {
  const ResendInvoiceSheetResult({required this.recipientEmail});

  final String recipientEmail;
}

/// Shows the SG-07 resend invoice sheet.
Future<ResendInvoiceSheetResult?> showResendInvoiceSheet(
  BuildContext context, {
  required String latestEmail,
  required String latestDateTime,
  String? initialEmail,
  VoidCallback? onViewHistory,
}) {
  return showVBottomSheet<ResendInvoiceSheetResult>(
    context: context,
    child: ResendInvoiceSheet(
      latestEmail: latestEmail,
      latestDateTime: latestDateTime,
      initialEmail: initialEmail ?? latestEmail,
      onViewHistory: onViewHistory,
    ),
  );
}

/// Resend E-Invoice sheet.
///
/// Implements SG07-O02. Distinct public surface from [SendInvoiceSheet].
class ResendInvoiceSheet extends StatefulWidget {
  const ResendInvoiceSheet({
    super.key,
    required this.latestEmail,
    required this.latestDateTime,
    this.initialEmail,
    this.isLoading = false,
    this.onSubmit,
    this.onCancel,
    this.onViewHistory,
  });

  final String latestEmail;
  final String latestDateTime;
  final String? initialEmail;
  final bool isLoading;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onCancel;
  final VoidCallback? onViewHistory;

  static const previewLatestEmail = 'accounting@company.com';
  static const previewLatestDateTime = '05/08/2026, 16:20';

  @override
  State<ResendInvoiceSheet> createState() => _ResendInvoiceSheetState();
}

class _ResendInvoiceSheetState extends State<ResendInvoiceSheet> {
  late final TextEditingController _emailController;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail ?? widget.latestEmail,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    if (widget.isLoading) return;
    setState(() {
      if (value.trim().isEmpty) {
        _showValidationError = false;
      } else {
        _showValidationError = !SendInvoiceCopy.isValidEmail(value);
      }
    });
  }

  void _submit() {
    if (widget.isLoading) return;
    final email = _emailController.text.trim();
    if (!SendInvoiceCopy.isValidEmail(email)) {
      setState(() => _showValidationError = true);
      return;
    }
    if (widget.onSubmit != null) {
      widget.onSubmit!(email);
    } else {
      Navigator.of(context).pop(ResendInvoiceSheetResult(recipientEmail: email));
    }
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              VText(
                SendInvoiceCopy.resendTitle,
                variant: VTextVariant.headingH3,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.sm(),
              VText(
                SendInvoiceCopy.latestDeliverySummary(
                  email: widget.latestEmail,
                  dateTime: widget.latestDateTime,
                ),
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.md(),
              InvoiceDeliveryRecipientForm(
                emailController: _emailController,
                primaryLabel: SendInvoiceCopy.resendAction,
                isLoading: widget.isLoading,
                showValidationError: _showValidationError,
                onEmailChanged: _onEmailChanged,
                onPrimary: _submit,
                onCancel: _cancel,
                footerAboveActions: Align(
                  alignment: Alignment.center,
                  child: VButton(
                    key: const Key('action_view_delivery_history'),
                    label: SendInvoiceCopy.viewHistoryLink,
                    variant: VButtonVariant.link,
                    onPressed: widget.isLoading ? null : widget.onViewHistory,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
