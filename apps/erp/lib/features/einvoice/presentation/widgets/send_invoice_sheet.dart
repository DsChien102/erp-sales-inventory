import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import '../../data/models.dart';

import '../../logic/order_invoice_delivery_cubit.dart';
import '../../logic/order_invoice_delivery_state.dart';
import '../support/order_invoice_delivery_copy.dart';
import 'invoice_delivery_recipient_form.dart';

/// Shows app-owned SG-07 first-send sheet. Returns `true` when send accepted.
Future<bool?> showOrderInvoiceSendSheet(
  BuildContext context, {
  required OrderInvoiceDeliveryCubit cubit,
  required SendInvoiceSheetContextDto sheetContext,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    title: OrderInvoiceDeliveryCopy.sendTitle,
    semanticLabel: OrderInvoiceDeliveryCopy.sendTitle,
    child: BlocProvider.value(
      value: cubit,
      child: OrderInvoiceSendSheet(sheetContext: sheetContext),
    ),
  );
}

/// App-owned first-send sheet (SG07-O01-A/B/C/D).
class OrderInvoiceSendSheet extends StatefulWidget {
  const OrderInvoiceSendSheet({
    super.key,
    required this.sheetContext,
  });

  final SendInvoiceSheetContextDto sheetContext;

  @override
  State<OrderInvoiceSendSheet> createState() => _OrderInvoiceSendSheetState();
}

class _OrderInvoiceSendSheetState extends State<OrderInvoiceSendSheet> {
  late final TextEditingController _emailController;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.sheetContext.suggestedEmail ?? '',
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

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final source = OrderInvoiceDeliveryCopy.suggestionSource(
      widget.sheetContext.suggestedEmailSource,
    );

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
                  primaryLabel: OrderInvoiceDeliveryCopy.sendAction,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
