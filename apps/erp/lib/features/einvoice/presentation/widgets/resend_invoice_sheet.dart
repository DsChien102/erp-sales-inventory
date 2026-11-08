import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../data/models.dart';

import '../../logic/order_invoice_delivery_cubit.dart';
import '../../logic/order_invoice_delivery_state.dart';
import '../support/order_invoice_delivery_copy.dart';
import 'invoice_delivery_recipient_form.dart';

/// Shows app-owned SG-07 resend sheet. Returns `true` when send accepted.
Future<bool?> showOrderInvoiceResendSheet(
  BuildContext context, {
  required OrderInvoiceDeliveryCubit cubit,
  required SendInvoiceSheetContextDto sheetContext,
  required Future<void> Function(BuildContext sheetContext) onViewHistory,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    title: OrderInvoiceDeliveryCopy.resendTitle,
    semanticLabel: OrderInvoiceDeliveryCopy.resendTitle,
    child: BlocProvider.value(
      value: cubit,
      child: OrderInvoiceResendSheet(
        sheetContext: sheetContext,
        onViewHistory: onViewHistory,
      ),
    ),
  );
}

/// Latest delivery whose status is succeeded (history is ordered by
/// `delivery_no` ascending); null when none succeeded.
InvoiceDeliveryItemDto? latestSuccessfulDelivery(
  List<InvoiceDeliveryItemDto> history,
) {
  for (var i = history.length - 1; i >= 0; i--) {
    if (history[i].status == DeliveryStatus.succeeded) {
      return history[i];
    }
  }
  return null;
}

/// App-owned resend sheet (SG07-O02).
class OrderInvoiceResendSheet extends StatefulWidget {
  const OrderInvoiceResendSheet({
    super.key,
    required this.sheetContext,
    required this.onViewHistory,
  });

  final SendInvoiceSheetContextDto sheetContext;
  final Future<void> Function(BuildContext sheetContext) onViewHistory;

  @override
  State<OrderInvoiceResendSheet> createState() => _OrderInvoiceResendSheetState();
}

class _OrderInvoiceResendSheetState extends State<OrderInvoiceResendSheet> {
  late final TextEditingController _emailController;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    final latest = widget.sheetContext.history.isNotEmpty
        ? widget.sheetContext.history.last.recipientEmail
        : null;
    _emailController = TextEditingController(
      text: widget.sheetContext.suggestedEmail ?? latest ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _showValidationError = false;
      } else {
        _showValidationError = !OrderInvoiceDeliveryCopy.isValidEmail(value);
      }
    });
  }

  Future<void> _submit() async {
    final accepted = await context.read<OrderInvoiceDeliveryCubit>().submit(_emailController.text);
    if (accepted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  String? _latestSummary() {
    final latest = latestSuccessfulDelivery(widget.sheetContext.history);
    if (latest == null) {
      return null;
    }
    final local = (latest.completedAt ?? latest.startedAt).toLocal();
    final dateTime =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}, '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return OrderInvoiceDeliveryCopy.latestDeliverySummary(
      email: latest.recipientEmail,
      dateTime: dateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<OrderInvoiceDeliveryCubit, OrderInvoiceDeliveryState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == OrderInvoiceDeliveryStatus.failure &&
          current.errorMessage != null,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        final historyEnabled = !state.isSubmitting;
        final summary = _latestSummary();
        final source = OrderInvoiceDeliveryCopy.suggestionSource(
          widget.sheetContext.suggestedEmailSource,
        );
        return Material(
          color: colors.surface.withValues(alpha: 0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space3,
              VSpacing.space4,
              VSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                InvoiceDeliveryRecipientForm(
                  emailController: _emailController,
                  primaryLabel: OrderInvoiceDeliveryCopy.resendAction,
                  isSubmitting: state.isSubmitting,
                  operationLocked: state.operationLocked,
                  showValidationError: _showValidationError,
                  onChanged: _onEmailChanged,
                  onPrimary: _submit,
                  onCancel: _cancel,
                  sourceLabel: source == null
                      ? null
                      : VText(
                          source,
                          key: const Key('label_suggestion_source'),
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                  footerAboveActions: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (summary != null) ...[
                        VText(
                          summary,
                          variant: VTextVariant.bodyDefault,
                          color: colors.textSecondary,
                        ),
                        const VGap.sm(),
                      ],
                      Align(
                        alignment: Alignment.center,
                        child: VButton(
                          key: const Key('action_view_delivery_history'),
                          label: OrderInvoiceDeliveryCopy.viewHistory,
                          variant: VButtonVariant.link,
                          onPressed: historyEnabled ? () => widget.onViewHistory(context) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
