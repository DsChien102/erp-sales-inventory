import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:c45_shared_application/application.dart';

import '../lookups/sales_catalog_product_lookup.dart';

/// SG-11 — Khởi tạo phiếu đổi/trả (thin composition root).
///
/// Session orchestration nằm ở [SalesReturnExchangeSessionCubit]. Settlement
/// arithmetic thuộc SG-12 — page này không hiển thị tóm tắt dự kiến local.
class SalesReturnExchangeCreatePage extends StatefulWidget {
  const SalesReturnExchangeCreatePage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<SalesReturnExchangeCreatePage> createState() => _SalesReturnExchangeCreatePageState();
}

class _SalesReturnExchangeCreatePageState extends State<SalesReturnExchangeCreatePage> {
  late final SalesReturnExchangeSessionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesReturnExchangeSessionCubit(
      orderId: widget.orderId,
      returnExchangeRepository: GetIt.instance<ReturnExchangeRepository>(),
      orderRepository: GetIt.instance<SalesOrderRepository>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    );
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool _hasWorkingEdits(SalesReturnExchangeSessionState state) {
    return state.returnEdits.isNotEmpty ||
        state.exchangeEdits.isNotEmpty ||
        state.returnExchangeId != null;
  }

  Future<void> _handlePop(
    BuildContext context,
    SalesReturnExchangeSessionState state,
  ) async {
    if (!_hasWorkingEdits(state)) {
      if (context.mounted) context.pop();
      return;
    }
    final discard = await showSalesReturnDiscardDialog(context);
    if (discard != true || !context.mounted) return;
    final ok = await _cubit.discard();
    if (ok && context.mounted) context.pop();
  }

  Future<void> _openExchangeProductPicker() async {
    final search = SalesCatalogProductLookup.bindSearch();
    final resolveUnits = SalesCatalogProductLookup.bindUnits();

    final selected = await showSalesExchangeProductPickerSheet(
      context,
      searchProducts: (query) async {
        final products = await search(query);
        final selections = <SalesProductSelection>[];
        for (final p in products) {
          if (p.isBlocked) continue;
          final withUnits = await resolveUnits(p);
          for (final u in withUnits.selectableUnits) {
            selections.add(
              SalesProductSelection.fromProductUnit(
                product: withUnits,
                unit: u,
              ),
            );
          }
        }
        return selections;
      },
    );
    if (selected != null && mounted) {
      _cubit.addExchangeProduct(selected);
    }
  }

  Future<void> _handleProceed() async {
    final id = await _cubit.saveAndGetReturnExchangeId();
    if (!mounted || id == null) return;
    await SalesReturnSettleRoute(
      orderId: widget.orderId,
      returnExchangeId: id,
    ).push(context);
    if (!mounted) return;
    // Quay về từ quyết toán (vd. PRICE_CHANGED): làm mới giá món đổi. Giá đổi thì
    // cubit bỏ lượt lưu cũ, nên lần "Tiếp tục" sau lưu giá mới thay vì lặp lỗi.
    try {
      await _cubit.refreshExchangePrices();
    } on Object {
      // Lỗi xem giá: giữ giá hiện có; lưu/định giá ở server vẫn đối chiếu lại.
    }
  }

  bool _showProceedBar(SalesReturnExchangeSessionStatus status) {
    return status == SalesReturnExchangeSessionStatus.ready ||
        status == SalesReturnExchangeSessionStatus.retryableFailure ||
        status == SalesReturnExchangeSessionStatus.stale ||
        status == SalesReturnExchangeSessionStatus.saving;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesReturnExchangeSessionCubit, SalesReturnExchangeSessionState>(
        builder: (context, state) {
          final canPop =
              !_hasWorkingEdits(state) ||
              state.status == SalesReturnExchangeSessionStatus.discarded;

          return PopScope(
            canPop: canPop,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              await _handlePop(context, state);
            },
            child: VPageScaffold(
              key: const Key('wgt_sg11_return_create_page'),
              title: 'Đổi/trả hàng',
              showBackButton: true,
              leading: IconButton(
                icon: VIcon(
                  icon: VIcons.chevronLeft,
                  color: colors.textPrimary,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              bottomBar: _showProceedBar(state.status)
                  ? _ProceedBar(
                      enabled:
                          state.canProceed &&
                          state.status != SalesReturnExchangeSessionStatus.saving,
                      isSaving: state.status == SalesReturnExchangeSessionStatus.saving,
                      onPressed: _handleProceed,
                    )
                  : null,
              body: SalesReturnExchangeSessionBody(
                state: state,
                onRetry: _cubit.load,
                onReturnQuantityChanged: _cubit.setReturnQuantity,
                onExchangeQuantityChanged: _cubit.setExchangeQuantity,
                onAddExchangePressed: _openExchangeProductPicker,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProceedBar extends StatelessWidget {
  const _ProceedBar({
    required this.enabled,
    required this.isSaving,
    required this.onPressed,
  });

  final bool enabled;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: VButton(
        key: const Key('btn_sg11_proceed_settle'),
        label: isSaving ? 'Đang lưu...' : 'Tiếp tục',
        variant: VButtonVariant.primary,
        tone: VComponentTone.success,
        size: VButtonSize.large,
        fullWidth: true,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
