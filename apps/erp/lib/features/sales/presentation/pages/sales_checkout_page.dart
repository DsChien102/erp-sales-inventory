import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:erp/core/formatting/money_formatter.dart';

/// SG-05 — Group D checkout finalize and uncertain-result recovery.
class SalesCheckoutPage extends StatefulWidget {
  const SalesCheckoutPage({
    super.key,
    required this.args,
  });

  final SalesCheckoutDraftArgs args;

  @override
  State<SalesCheckoutPage> createState() => _SalesCheckoutPageState();
}

class _SalesCheckoutPageState extends State<SalesCheckoutPage> {
  late final SalesCheckoutCubit _cubit;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _transactionCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = SalesCheckoutCubit(
      args: widget.args,
      repository: GetIt.instance<SalesCheckoutRepository>(),
      session: GetIt.instance<SessionController>(),
      activeStoreContext: _SalesCheckoutActiveStoreAdapter(
        GetIt.instance<SessionController>(),
      ),
    )..load();
    _syncControllers(_cubit.state.vm);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    _transactionCodeController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _syncControllers(SalesCheckoutVm vm) {
    _setControllerValue(_cashController, _toDigitsText(vm.cashPaidMinor));
    _setControllerValue(_bankController, _toDigitsText(vm.bankPaidMinor));
    _setControllerValue(_transactionCodeController, vm.transactionCode ?? '');
  }

  void _setControllerValue(TextEditingController c, String value) {
    if (c.text == value) return;
    c.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _toDigitsText(int amountMinor) {
    final raw = amountMinor.toString();
    final b = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      b.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) b.write('.');
    }
    return b.toString();
  }

  Future<void> _openMoneyKeypad({
    required bool isCash,
    required int currentAmountMinor,
  }) async {
    final raw = await showVNumericKeypadSheet(
      context: context,
      mode: VNumericKeypadMode.money,
      initialRaw: currentAmountMinor.toString(),
      title: isCash ? 'Nhập số tiền mặt' : 'Nhập số tiền chuyển khoản',
      unitLabel: 'Đơn vị: VND',
      allowDecimal: false,
      tone: VComponentTone.success,
    );
    if (!mounted || raw == null) return;
    final amount = int.tryParse(raw) ?? 0;
    if (isCash) {
      _cubit.updateCashAmount(amount);
    } else {
      _cubit.updateBankAmount(amount);
    }
  }

  void _returnToCompose() {
    if (context.canPop()) {
      context.pop();
    } else {
      const SalesComposeRoute().go(context);
    }
  }

  Future<void> _confirmFinalize() async {
    final action = await showSalesCheckoutFinalizeSheet(context);
    if (!mounted || action != SalesCheckoutFinalizeAction.confirm) return;
    await _cubit.finalizeCheckout();
  }

  void _openResult(SalesCheckoutState state) {
    final result = state.checkoutResult;
    if (result == null || result.salesOrderId.isEmpty) return;
    SalesResultRoute(
      orderId: result.salesOrderId,
      $extra: SalesCheckoutResultArgs(result: result, storeId: state.attempt!.request.storeId),
    ).go(context);
  }

  /// Surfaces precheck/attempt outcomes as toasts. Success navigates; the two
  /// unresolved outcomes (uncertain failure, conflict) carry a tap-to-recover
  /// action that reuses the same attempt id so it cannot create a duplicate.
  void _handleStateFeedback(BuildContext context, SalesCheckoutState state) {
    switch (state.attemptStatus) {
      case SalesCheckoutAttemptStatus.succeeded:
        _openResult(state);
        return;
      case SalesCheckoutAttemptStatus.failure:
        VToast.show(
          context,
          title: 'Chưa hoàn tất được đơn',
          message: state.attemptErrorMessage ?? 'Không thể hoàn tất đơn.',
          type: VToastType.danger,
          onTap: _cubit.checkAttemptAgain,
        );
        return;
      case SalesCheckoutAttemptStatus.conflict:
        VToast.show(
          context,
          title: 'Yêu cầu bị xung đột',
          message: state.attemptErrorMessage ?? 'Vui lòng tải lại đơn.',
          type: VToastType.danger,
          onTap: _returnToCompose,
        );
        return;
      case SalesCheckoutAttemptStatus.blocked:
        VToast.show(
          context,
          title: 'Đơn bị chặn khi hoàn tất',
          message: state.attemptErrorMessage ?? 'Vui lòng quay lại đơn để kiểm tra.',
          type: VToastType.danger,
          onTap: _returnToCompose,
        );
        return;
      case SalesCheckoutAttemptStatus.idle ||
          SalesCheckoutAttemptStatus.submitting ||
          SalesCheckoutAttemptStatus.recovering:
        break;
    }
    switch (state.status) {
      case SalesCheckoutStatus.blocked:
        VToast.show(
          context,
          title: 'Chưa đủ điều kiện thanh toán',
          message: _blockerMessage(state),
          type: VToastType.danger,
        );
      case SalesCheckoutStatus.failure:
        VToast.show(
          context,
          title: 'Không kiểm tra được thanh toán',
          message: state.errorMessage ?? 'Vui lòng thử lại.',
          type: VToastType.danger,
        );
      case SalesCheckoutStatus.initial ||
          SalesCheckoutStatus.prechecking ||
          SalesCheckoutStatus.ready:
        break;
    }
  }

  String _blockerMessage(SalesCheckoutState state) {
    final blockers = state.precheck?.blockers ?? const <SalesBlockerDto>[];
    if (blockers.isEmpty) {
      return state.errorMessage ?? 'Đơn chưa đủ điều kiện thanh toán.';
    }
    return blockers.map(_localizedBlockerMessage).join('\n');
  }

  String _localizedBlockerMessage(SalesBlockerDto blocker) {
    return switch (blocker.code) {
      'PRODUCT_NOT_SELLABLE' => 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.',
      _ => switch (blocker.message) {
        'Paid amount cannot exceed the checkout total.' =>
          'Số tiền thanh toán không được vượt quá tổng cần trả.',
        _ => blocker.message,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<SalesCheckoutCubit, SalesCheckoutState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || previous.attemptStatus != current.attemptStatus,
        listener: _handleStateFeedback,
        builder: (context, state) {
          final vm = state.vm;
          _syncControllers(vm);
          final displayedTotal = vm.displayedTotalAmountMinor;
          final attemptBusy =
              state.attemptStatus == SalesCheckoutAttemptStatus.submitting ||
              state.attemptStatus == SalesCheckoutAttemptStatus.recovering;
          final busy = attemptBusy || state.status == SalesCheckoutStatus.prechecking;
          final canFinalize =
              state.status == SalesCheckoutStatus.ready &&
              state.attemptStatus == SalesCheckoutAttemptStatus.idle &&
              vm.canFinalizePayment;

          return VPageScaffold(
            key: const Key('wgt_sg05_checkout_page'),
            title: 'Thanh toán',
            showBackButton: true,
            bottomBar: VPagePadding(
              vertical: VSpacing.space3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const VText(
                        'Khách phải trả',
                        variant: VTextVariant.bodyDefault,
                      ),
                      const Spacer(),
                      VText(
                        MoneyFormatter.formatMinor(displayedTotal),
                        variant: VTextVariant.bodyDefaultMono,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const VGap.sm(),
                  VButton(
                    key: const Key('btn_sg05_finalize'),
                    label: 'Tiếp tục',
                    tone: VComponentTone.success,
                    fullWidth: true,
                    isLoading: busy,
                    enabled: canFinalize,
                    onPressed: (canFinalize && !busy) ? _confirmFinalize : null,
                  ),
                ],
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.space4,
                VSpacing.space3,
                VSpacing.space4,
                VSpacing.space4,
              ),
              children: [
                SalesCheckoutSummaryCard(vm: vm),
                const VGap.md(),
                SalesCheckoutPaymentMethodSelector(
                  selectedMode: vm.paymentMode,
                  onModeSelected: attemptBusy ? (_) {} : _cubit.selectPaymentMode,
                ),
                const VGap.sm(),
                VCard(
                  padding: const EdgeInsets.all(VSpacing.space3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.paymentMode == SalesPaymentMode.cash ||
                          vm.paymentMode == SalesPaymentMode.mixed) ...[
                        VText(
                          vm.paymentMode == SalesPaymentMode.mixed ? 'Tiền mặt' : 'Số tiền mặt',
                          variant: VTextVariant.bodyDefault,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const VGap.xs(),
                        GestureDetector(
                          key: const Key('input_sg05_cash_amount'),
                          behavior: HitTestBehavior.opaque,
                          onTap: attemptBusy || !vm.canEditCashAmount
                              ? null
                              : () => _openMoneyKeypad(
                                  isCash: true,
                                  currentAmountMinor: vm.cashPaidMinor,
                                ),
                          child: IgnorePointer(
                            child: VTextField(
                              controller: _cashController,
                              suffixText: 'đ',
                            ),
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          vm.paymentMode == SalesPaymentMode.mixed
                              ? 'Nhập phần khách trả bằng tiền mặt.'
                              : (vm.canEditCashAmount
                                    ? 'Có thể nhập số tiền khác.'
                                    : 'Tự động bằng tổng đơn.'),
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        const VGap.sm(),
                      ],
                      if (vm.paymentMode == SalesPaymentMode.bankTransfer ||
                          vm.paymentMode == SalesPaymentMode.mixed) ...[
                        VText(
                          vm.paymentMode == SalesPaymentMode.mixed
                              ? 'Chuyển khoản'
                              : 'Số tiền chuyển khoản',
                          variant: VTextVariant.bodyDefault,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const VGap.xs(),
                        GestureDetector(
                          key: const Key('input_sg05_bank_amount'),
                          behavior: HitTestBehavior.opaque,
                          onTap: attemptBusy || !vm.canEditBankAmount
                              ? null
                              : () => _openMoneyKeypad(
                                  isCash: false,
                                  currentAmountMinor: vm.bankPaidMinor,
                                ),
                          child: IgnorePointer(
                            child: VTextField(
                              controller: _bankController,
                              suffixText: 'đ',
                            ),
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          vm.paymentMode == SalesPaymentMode.mixed
                              ? 'Nhập phần khách trả bằng chuyển khoản.'
                              : (vm.canEditBankAmount
                                    ? 'Có thể nhập số tiền khác.'
                                    : 'Tự động bằng tổng đơn.'),
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        const VGap.sm(),
                      ],
                      if (vm.paymentMode != SalesPaymentMode.mixed)
                        SalesCheckoutPercentRow(
                          currentMode: vm.paymentMode,
                          selectedPercent: displayedTotal == 0
                              ? 100
                              : ((vm.paymentMode == SalesPaymentMode.cash
                                            ? vm.cashPaidMinor
                                            : vm.bankPaidMinor) *
                                        100 /
                                        displayedTotal)
                                    .round(),
                          disableLowPercent: vm.isWalkIn,
                          onSelect: attemptBusy ? (_) {} : _cubit.selectPercent,
                        ),
                      if (vm.paymentMode != SalesPaymentMode.cash) ...[
                        if (vm.paymentMode != SalesPaymentMode.mixed) const VGap.sm(),
                        const VText(
                          'Mã giao dịch',
                          variant: VTextVariant.bodyDefault,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const VGap.xs(),
                        VTextField(
                          key: const Key('input_sg05_transaction_code'),
                          controller: _transactionCodeController,
                          hintText: 'Nhập mã giao dịch',
                          onChanged: attemptBusy ? null : _cubit.updateTransactionCode,
                        ),
                        const VGap.xs(),
                        VText(
                          'Không bắt buộc.',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        const VGap.sm(),
                      ],
                      const VGap.sm(),
                      Row(
                        children: [
                          VText(
                            'Tiền thừa',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                          const Spacer(),
                          VText(
                            MoneyFormatter.formatMinor(vm.changeAmountMinor),
                            variant: VTextVariant.bodyDefaultMono,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const VGap.md(),
                SalesCheckoutReceivableCard(
                  vm: vm,
                  enabled: !attemptBusy,
                  onDueDateSelected: _cubit.updateDueDate,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _SalesCheckoutActiveStoreAdapter implements ISalesActiveStoreContext {
  const _SalesCheckoutActiveStoreAdapter(this._inner);

  final SessionController _inner;

  @override
  String? get activeStoreId => _inner.activeStoreId;

  @override
  Future<String> requireActiveStoreId() => _inner.requireActiveStoreId();
}

