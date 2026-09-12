import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:erp/core/formatting/money_formatter.dart';

/// SG-12 — Quyết toán chênh lệch đổi/trả (thin composition root).
///
/// Settlement plan từ backend; UI thu/hoàn chỉ điều phối phần hiển thị tại presentation.
class SalesReturnExchangeSettlementPage extends StatefulWidget {
  const SalesReturnExchangeSettlementPage({
    super.key,
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  State<SalesReturnExchangeSettlementPage> createState() =>
      _SalesReturnExchangeSettlementPageState();
}

class _SalesReturnExchangeSettlementPageState extends State<SalesReturnExchangeSettlementPage> {
  late final SalesReturnExchangeSettlementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesReturnExchangeSettlementCubit(
      orderId: widget.orderId,
      returnExchangeId: widget.returnExchangeId,
      salesModule: GetIt.instance<ISalesModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..loadAndEvaluate();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _handleConfirmSettlement() async {
    final settlement = _cubit.state.effectiveSettlement;
    if (settlement == null) return;

    final confirm = await showSalesReturnConfirmSettlementSheet(
      context,
      vm: settlement,
    );
    if (confirm != true || !mounted) return;

    final outcome = await _cubit.confirm();
    if (!mounted || outcome == null) return;

    if (outcome.kind == SalesReturnExchangeResultKind.confirmed ||
        outcome.kind == SalesReturnExchangeResultKind.processing) {
      SalesReturnResultRoute(
        orderId: widget.orderId,
        returnExchangeId: widget.returnExchangeId,
      ).pushReplacement(context);
    }
  }

  String _bottomBarLabel(SalesReturnExchangeSettlementState state) {
    final settlement = state.effectiveSettlement;
    if (settlement == null) return 'Quyết toán';
    if (settlement.customerCollectMinor > 0) return 'Phải thu thêm';
    if (settlement.storeRefundMinor > 0) {
      if (state.effectiveRefundMinor == 0 && state.actualOffsetMinor > 0) {
        return 'Đã cấn trừ';
      }
      return 'Cần hoàn tiền';
    }
    return 'Không chênh lệch';
  }

  String _bottomBarValue(SalesReturnExchangeSettlementState state) {
    final settlement = state.effectiveSettlement;
    if (settlement == null) return '—';
    if (settlement.customerCollectMinor > 0) {
      return MoneyFormatter.formatMinor(settlement.customerCollectMinor);
    }
    if (settlement.storeRefundMinor > 0) {
      if (state.effectiveRefundMinor == 0 && state.actualOffsetMinor > 0) {
        return MoneyFormatter.formatMinor(state.actualOffsetMinor);
      }
      return MoneyFormatter.formatMinor(state.effectiveRefundMinor);
    }
    return MoneyFormatter.formatMinor(0);
  }

  bool _showConfirmBar(SalesReturnExchangeSettlementStatus status) {
    return status == SalesReturnExchangeSettlementStatus.ready ||
        status == SalesReturnExchangeSettlementStatus.stale ||
        status == SalesReturnExchangeSettlementStatus.retryableFailure ||
        status == SalesReturnExchangeSettlementStatus.confirming;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesReturnExchangeSettlementCubit, SalesReturnExchangeSettlementState>(
        builder: (context, state) {
          final isConfirming = state.status == SalesReturnExchangeSettlementStatus.confirming;
          final settlement = state.effectiveSettlement;
          final showBar = settlement != null && _showConfirmBar(state.status);

          return VPageScaffold(
            key: const Key('wgt_sg12_return_settlement_page'),
            title: 'Quyết toán đổi/trả',
            showBackButton: true,
            leading: IconButton(
              icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
              onPressed: isConfirming ? null : () => Navigator.maybePop(context),
            ),
            bottomBar: showBar
                ? Container(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        top: BorderSide(color: colors.borderDefault),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            VText(
                              _bottomBarLabel(state),
                              variant: VTextVariant.bodyDefault,
                              color: colors.textSecondary,
                            ),
                            VText(
                              _bottomBarValue(state),
                              variant: VTextVariant.bodyDefault,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const VGap.sm(),
                        VButton(
                          key: const Key('btn_sg12_confirm_settlement'),
                          label: isConfirming ? 'Đang xử lý...' : 'Xác nhận đổi/trả',
                          variant: VButtonVariant.primary,
                          tone: VComponentTone.success,
                          size: VButtonSize.large,
                          fullWidth: true,
                          onPressed: (!state.canConfirm || isConfirming)
                              ? null
                              : _handleConfirmSettlement,
                        ),
                      ],
                    ),
                  )
                : null,
            body: SalesReturnExchangeSettlementBody(
              state: state,
              onRetry: () => _cubit.loadAndEvaluate(),
              onSettledNowChanged: _cubit.updateSettledNow,
              onDueDateChanged: _cubit.updatePaymentDueDate,
              onMethodChanged: _cubit.updatePaymentMethod,
              onOffsetDebtChanged: _cubit.updateOffsetDebt,
            ),
          );
        },
      ),
    );
  }
}
