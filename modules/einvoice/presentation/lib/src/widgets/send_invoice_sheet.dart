import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/send_invoice_copy.dart';
import 'invoice_delivery_recipient_form.dart';

/// Preview / controlled presentation states for [SendInvoiceSheet].
enum SendInvoiceSheetState {
  /// O01-A — suggested email filled.
  suggested,

  /// O01-B — empty recipient.
  empty,

  /// O01-C — invalid email with error helper.
  invalid,

  /// O01-D — sending / loading.
  loading,
}

/// Result of [showSendInvoiceSheet] when the user confirms.
class SendInvoiceSheetResult {
  const SendInvoiceSheetResult({required this.recipientEmail});

  final String recipientEmail;
}

/// Shows the SG-07 first-send invoice sheet.
///
/// Opening alone does not create a delivery (fake/preview only in this slice).
Future<SendInvoiceSheetResult?> showSendInvoiceSheet(
  BuildContext context, {
  required String invoiceNumber,
  required String invoiceSymbol,
  String initialEmail = '',
  SendInvoiceSheetState state = SendInvoiceSheetState.suggested,
}) {
  return showVBottomSheet<SendInvoiceSheetResult>(
    context: context,
    child: SendInvoiceSheet(
      invoiceNumber: invoiceNumber,
      invoiceSymbol: invoiceSymbol,
      initialEmail: initialEmail,
      state: state,
    ),
  );
}

/// First-send E-Invoice sheet.
///
/// Implements SG07-O01-A / O01-B / O01-C / O01-D.
class SendInvoiceSheet extends StatefulWidget {
  const SendInvoiceSheet({
    super.key,
    required this.invoiceNumber,
    required this.invoiceSymbol,
    this.initialEmail = '',
    this.state = SendInvoiceSheetState.suggested,
    this.onSubmit,
    this.onCancel,
  });

  final String invoiceNumber;
  final String invoiceSymbol;
  final String initialEmail;
  final SendInvoiceSheetState state;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onCancel;

  /// Preview fixture from approved design (not a business constant).
  static const previewInvoiceNumber = '0000129';
  static const previewInvoiceSymbol = 'C26TAA';
  static const previewSuggestedEmail = 'accounting@company.com';

  @override
  State<SendInvoiceSheet> createState() => _SendInvoiceSheetState();
}

class _SendInvoiceSheetState extends State<SendInvoiceSheet> {
  late final TextEditingController _emailController;
  late bool _showValidationError;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: _initialEmailForState());
    _showValidationError = widget.state == SendInvoiceSheetState.invalid;
    _isLoading = widget.state == SendInvoiceSheetState.loading;
  }

  @override
  void didUpdateWidget(covariant SendInvoiceSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _isLoading = widget.state == SendInvoiceSheetState.loading;
      _showValidationError = widget.state == SendInvoiceSheetState.invalid;
      if (oldWidget.initialEmail != widget.initialEmail ||
          oldWidget.state != widget.state) {
        _emailController.text = _initialEmailForState();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _initialEmailForState() {
    return switch (widget.state) {
      SendInvoiceSheetState.suggested =>
        widget.initialEmail.isEmpty
            ? SendInvoiceSheet.previewSuggestedEmail
            : widget.initialEmail,
      SendInvoiceSheetState.empty => '',
      SendInvoiceSheetState.invalid =>
        widget.initialEmail.isEmpty ? 'not-an-email' : widget.initialEmail,
      SendInvoiceSheetState.loading =>
        widget.initialEmail.isEmpty
            ? SendInvoiceSheet.previewSuggestedEmail
            : widget.initialEmail,
    };
  }

  void _onEmailChanged(String value) {
    if (_isLoading) return;
    setState(() {
      if (value.trim().isEmpty) {
        _showValidationError = false;
      } else {
        _showValidationError = !SendInvoiceCopy.isValidEmail(value);
      }
    });
  }

  void _submit() {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    if (!SendInvoiceCopy.isValidEmail(email)) {
      setState(() => _showValidationError = true);
      return;
    }
    if (widget.onSubmit != null) {
      widget.onSubmit!(email);
    } else {
      Navigator.of(context).pop(SendInvoiceSheetResult(recipientEmail: email));
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
                SendInvoiceCopy.sendTitle,
                variant: VTextVariant.headingH3,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.sm(),
              VText(
                SendInvoiceCopy.invoiceIdentity(
                  invoiceNumber: widget.invoiceNumber,
                  invoiceSymbol: widget.invoiceSymbol,
                ),
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.md(),
              InvoiceDeliveryRecipientForm(
                emailController: _emailController,
                primaryLabel: SendInvoiceCopy.sendAction,
                isLoading: _isLoading,
                showValidationError: _showValidationError,
                onEmailChanged: _onEmailChanged,
                onPrimary: _submit,
                onCancel: _cancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
