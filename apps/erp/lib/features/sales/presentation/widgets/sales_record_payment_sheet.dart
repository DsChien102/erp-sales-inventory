import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/logic/sales_record_payment_cubit.dart';
import 'package:erp/features/sales/logic/sales_record_payment_state.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _SalesRecordPaymentActiveStoreAdapter implements ISalesActiveStoreContext {
  const _SalesRecordPaymentActiveStoreAdapter(this._session);
  final SessionController _session;

  @override
  String? get activeStoreId => _session.activeStoreId;

  @override
  Future<String> requireActiveStoreId() => _session.requireActiveStoreId();
}

class _VndGroupingFormatter extends TextInputFormatter {
  const _VndGroupingFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(selection: TextSelection.collapsed(offset: 0));
    }
    final formatted = MoneyFormatter.formatMinorPlain(MoneyFormatter.parseMinor(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Future<int?> showSalesRecordPaymentSheet(
  BuildContext context, {
  required String salesOrderId,
  required String orderNumber,
  required int outstandingMinor,
  String? dueDateFormatted,
  SalesRecordPaymentCubit? cubit,
}) {
  final effectiveCubit =
      cubit ??
      SalesRecordPaymentCubit(
        repository: GetIt.instance<SalesPaymentRepository>(),
        executionContext: GetIt.instance<IExecutionContext>(),
        activeStoreContext: _SalesRecordPaymentActiveStoreAdapter(
          GetIt.instance<SessionController>(),
        ),
        salesOrderId: salesOrderId,
        outstandingMinor: outstandingMinor,
      );

  final sheetFuture = showVAdaptiveSheet<int>(
    context: context,
    title: 'Thu tiền',
    semanticLabel: 'Thu tiền',
    child: BlocProvider<SalesRecordPaymentCubit>.value(
      value: effectiveCubit,
      child: _SalesRecordPaymentSheetContent(
        orderNumber: orderNumber,
        outstandingMinor: outstandingMinor,
        dueDateFormatted: dueDateFormatted,
      ),
    ),
  );

  if (cubit == null) {
    sheetFuture.whenComplete(() => effectiveCubit.close());
  }

  return sheetFuture;
}

class _SalesRecordPaymentSheetContent extends StatefulWidget {
  const _SalesRecordPaymentSheetContent({
    required this.orderNumber,
    required this.outstandingMinor,
    this.dueDateFormatted,
  });

  final String orderNumber;
  final int outstandingMinor;
  final String? dueDateFormatted;

  @override
  State<_SalesRecordPaymentSheetContent> createState() =>
      _SalesRecordPaymentSheetContentState();
}

class _SalesRecordPaymentSheetContentState
    extends State<_SalesRecordPaymentSheetContent> {
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: MoneyFormatter.formatMinorPlain(widget.outstandingMinor),
    );
    _referenceController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<SalesRecordPaymentCubit>();

    return BlocConsumer<SalesRecordPaymentCubit, SalesRecordPaymentState>(
      listener: (context, state) {
        if (state.status == SalesRecordPaymentStatus.succeeded) {
          Navigator.of(context).pop(state.amountMinor);
        }
      },
      builder: (context, state) {
        final isSubmitting =
            state.status == SalesRecordPaymentStatus.submitting;
        final isFailureWithRetry =
            state.status == SalesRecordPaymentStatus.failure && state.canRetry;

        return PopScope(
          canPop: !isSubmitting,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VText(
                  'Đơn ${widget.orderNumber}',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VText(
                      'Còn phải thu',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    VText(
                      MoneyFormatter.formatMinor(widget.outstandingMinor),
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (widget.dueDateFormatted != null) ...[
                  const VGap.xs(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VText(
                        'Hẹn thanh toán',
                        variant: VTextVariant.bodyDefault,
                        color: colors.textSecondary,
                      ),
                      VText(
                        widget.dueDateFormatted!,
                        variant: VTextVariant.bodyDefault,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ],
                const VGap.md(),
                VField(
                  invalid: state.fieldError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VFieldLabel('Số tiền', isRequired: true),
                      VTextField(
                        key: const Key('inp_sg11_amount'),
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        suffixText: 'đ',
                        inputFormatters: const [_VndGroupingFormatter()],
                        enabled: !isSubmitting,
                        onChanged: (text) {
                          final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                          cubit.setAmountMinor(
                            digits.isEmpty
                                ? null
                                : MoneyFormatter.parseMinor(digits),
                          );
                        },
                        onSubmitted: (_) {
                          if (!isSubmitting) cubit.submit();
                        },
                      ),
                      if (state.fieldError != null) ...[
                        const VGap.xs(),
                        VFieldError(state.fieldError!),
                      ],
                    ],
                  ),
                ),
                const VGap.md(),
                VText(
                  'Phương thức',
                  variant: VTextVariant.bodySmall,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VSegmentedControl(
                  key: const Key('seg_sg11_method'),
                  segments: const ['Tiền mặt', 'Chuyển khoản'],
                  selectedIndex:
                      state.method == SalesPaymentMethod.cash ? 0 : 1,
                  onChanged: (index) {
                    if (isSubmitting) return;
                    cubit.setMethod(
                      index == 0
                          ? SalesPaymentMethod.cash
                          : SalesPaymentMethod.manualBankTransfer,
                    );
                  },
                ),
                if (state.method ==
                    SalesPaymentMethod.manualBankTransfer) ...[
                  const VGap.md(),
                  VTextField(
                    key: const Key('inp_sg11_reference'),
                    controller: _referenceController,
                    hintText: 'Mã giao dịch (Không bắt buộc)',
                    enabled: !isSubmitting,
                    onChanged: (val) => cubit.setExternalReference(val),
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const VGap.sm(),
                  VText(
                    state.errorMessage!,
                    key: const Key('txt_sg11_error'),
                    variant: VTextVariant.bodySmall,
                    color: colors.danger,
                  ),
                ],
                const VGap.lg(),
                Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Quay lại',
                        variant: VButtonVariant.secondary,
                        onPressed:
                            isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const VGap.horizontalSm(),
                    Expanded(
                      child: VButton(
                        key: const Key('btn_sg11_confirm'),
                        label:
                            isFailureWithRetry
                                ? 'Thử lại'
                                : 'Xác nhận thu tiền',
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : () => cubit.submit(),
                      ),
                    ),
                  ],
                ),
                const VGap.sm(),
              ],
            ),
          ),
        );
      },
    );
  }
}
