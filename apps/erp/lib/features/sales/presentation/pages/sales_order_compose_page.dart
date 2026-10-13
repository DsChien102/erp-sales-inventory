import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

import '../lookups/sales_catalog_product_lookup.dart';
import '../lookups/sales_partner_customer_lookup.dart';
import '../lookups/sales_pricing_lookup.dart';
import '../orchestration/sales_checkout_orchestrator.dart';
import '../orchestration/sales_draft_backend.dart';
import '../orchestration/sales_manual_price_orchestrator.dart';

/// SG-02 — Tạo / soạn đơn bán hàng.
class SalesOrderComposePage extends StatefulWidget {
  const SalesOrderComposePage({super.key, this.draftId});

  final String? draftId;

  @override
  State<SalesOrderComposePage> createState() => _SalesOrderComposePageState();
}

class _SalesOrderComposePageState extends State<SalesOrderComposePage> {
  late final SalesComposeCubit _cubit;
  bool _allowPop = false;
  bool _leaveSheetOpen = false;

  /// Chặn bấm nhanh mở 2 [SalesProductUnitSheet] (resolve units + show cùng lúc).
  bool _unitPickerOpen = false;

  static const _stockExceededToast = 'Số lượng vượt quá tồn khả dụng';

  @override
  void initState() {
    super.initState();
    final draftId = widget.draftId?.trim();
    final resolvedId = SalesComposeDraftRef.isNew(draftId ?? '')
        ? SalesComposeDraftRef.newDraft
        : draftId!;
    _cubit = SalesComposeCubit(
      draftId: resolvedId,
      previewPricing: SalesPricingLookup.bindPreview(),
      persistDraft: SalesDraftBackend.bindPersist(),
      restoreDraft: SalesDraftBackend.bindRestore(),
      prepareCheckout: SalesCheckoutOrchestrator.bind(),
      applyManualPriceFlow: SalesManualPriceOrchestrator.bind(),
    )..hydrate();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showStockExceededToast() {
    VToast.show(
      context,
      title: _stockExceededToast,
      message: '',
      type: VToastType.warning,
    );
  }

  void _showDraftSavedToast() {
    VToast.show(
      context,
      title: 'Đã lưu đơn nháp.',
      message: '',
      type: VToastType.success,
    );
  }

  Future<void> _openDrafts() async {
    final pick = await const SalesDraftsRoute().push<SalesDraftPickResult?>(context);
    if (!mounted || pick == null) return;
    final resolvedId = switch (pick) {
      SalesDraftPickNew() => SalesComposeDraftRef.newDraft,
      SalesDraftPickExisting(:final draftId) => draftId,
    };
    await _cubit.loadDraft(resolvedId);
  }

  Future<void> _openCustomerPicker() async {
    final current = _cubit.state.customer;
    final result = await showSalesCustomerSelectSheet(
      context,
      searchCustomers: SalesPartnerCustomerLookup.bindSearch(),
      selectedPartnerId: current.partnerId,
      selectedWalkIn: current.isWalkIn,
      onCreateCustomer: _openCreateCustomer,
    );
    if (result == null || !mounted) return;
    // Search list items lack invoice profile; resolve detail so checkout
    // snapshot carries Theme-08 buyer identity (Task 3b).
    if (!result.isWalkIn && result.partnerId != null && result.partnerId!.trim().isNotEmpty) {
      try {
        final resolved = await SalesPartnerCustomerLookup.bindResolve()(
          result.partnerId!,
        );
        if (!mounted) return;
        _cubit.applyCustomerSelection(resolved);
        return;
      } catch (_) {
        // Fall through with list selection if detail resolve fails.
      }
    }
    _cubit.applyCustomerSelection(result);
  }

  Future<void> _openCreateCustomer() async {
    final result = await SalesCustomerQuickCreateSheet.show(
      context,
      checkDuplicate: SalesPartnerCustomerLookup.bindDuplicateCheck(),
      createCustomer: SalesPartnerCustomerLookup.bindCreate(),
    );
    if (result == null || !mounted) return;
    _cubit.applyCustomerSelection(result);
  }

  Future<void> _onSelectSuggestedProduct(SalesSellableProductVm product) async {
    if (product.isBlocked) {
      VToast.show(
        context,
        title: 'Không thể chọn',
        message: product.blockReason ?? 'Sản phẩm không còn bán được.',
        type: VToastType.warning,
      );
      return;
    }
    if (_unitPickerOpen) return;
    _unitPickerOpen = true;

    try {
      late final SalesSellableProductVm resolvedProduct;
      try {
        resolvedProduct = await SalesCatalogProductLookup.bindUnits()(product);
      } on SalesExternalOperationException catch (error) {
        if (!mounted) return;
        VToast.show(
          context,
          title: 'Không thể tải đơn vị bán',
          message: error.message,
          type: VToastType.danger,
        );
        return;
      }

      if (!mounted) return;
      final units = resolvedProduct.selectableUnits;
      if (units.isEmpty) {
        VToast.show(
          context,
          title: 'Không có đơn vị bán',
          message: 'Chọn sản phẩm khác.',
          type: VToastType.warning,
        );
        return;
      }

      SalesProductUnitVm? unit;
      if (resolvedProduct.needsUnitPicker) {
        unit = await SalesProductUnitSheet.show(
          context,
          product: resolvedProduct,
        );
        if (unit == null || !mounted) return;
      } else {
        unit = units.first;
      }

      final selection = SalesProductSelection.fromProductUnit(
        product: resolvedProduct,
        unit: unit,
      );
      final err = _cubit.tryIncrementLine(selection);
      if (err != null && mounted) {
        _showStockExceededToast();
      }
    } finally {
      _unitPickerOpen = false;
    }
  }

  Future<void> _onChangeLineUnit(SalesComposeLineVm line) async {
    if (_cubit.state.busy != SalesComposeBusy.none) return;
    if (_unitPickerOpen) return;
    _unitPickerOpen = true;

    try {
      final stub = SalesSellableProductVm(
        productId: line.identity.productId,
        sku: '',
        displayName: line.identity.productName,
        units: [
          SalesProductUnitVm(
            productUnitId: line.identity.productUnitId,
            unitCode: '',
            unitName: line.identity.unitLabel,
            unitPrice: line.identity.catalogUnitPrice,
            isDefault: true,
          ),
        ],
      );

      late final SalesSellableProductVm resolvedProduct;
      try {
        resolvedProduct = await SalesCatalogProductLookup.bindUnits()(stub);
      } on SalesExternalOperationException catch (error) {
        if (!mounted) return;
        VToast.show(
          context,
          title: 'Không thể tải đơn vị bán',
          message: error.message,
          type: VToastType.danger,
        );
        return;
      }

      if (!mounted) return;
      if (resolvedProduct.selectableUnits.isEmpty) {
        VToast.show(
          context,
          title: 'Không có đơn vị bán',
          message: 'Không thể đổi đơn vị cho sản phẩm này.',
          type: VToastType.warning,
        );
        return;
      }

      final unit = await SalesProductUnitSheet.show(
        context,
        product: resolvedProduct,
        initialUnitId: line.identity.productUnitId,
      );
      if (unit == null || !mounted) return;

      final selection = SalesProductSelection.fromProductUnit(
        product: resolvedProduct,
        unit: unit,
      );
      final err = _cubit.changeLineUnit(line.identity.lineId, selection);
      if (err != null && mounted) {
        _showStockExceededToast();
      }
    } finally {
      _unitPickerOpen = false;
    }
  }

  Future<bool> _saveDraft({required bool closeAfterSave}) async {
    final result = await _cubit.saveDraft();
    if (!mounted) return false;
    switch (result) {
      case SalesDraftSaveResult.failed:
        return false;
      case SalesDraftSaveResult.draftGone:
        VToast.show(
          context,
          title: 'Đơn nháp không còn',
          message: closeAfterSave
              ? 'Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác.'
              : 'Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác. Đã chuyển sang đơn mới.',
          type: VToastType.warning,
        );
      case SalesDraftSaveResult.saved:
        _showDraftSavedToast();
    }
    if (closeAfterSave) {
      // Leave the compose flow like "discard and close". Replacing compose with
      // the drafts list made it the first page of the draft shell navigator,
      // which hides its back button and strands the user there.
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _leaveToHome();
      });
      return result == SalesDraftSaveResult.saved;
    }
    await _cubit.startNewDraft();
    if (!mounted) return false;
    await context.read<SalesDraftListCubit>().load();
    return result == SalesDraftSaveResult.saved;
  }

  void _leaveToHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(SalesNav.ordersList);
    }
  }

  Future<void> _requestLeave() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_cubit.state.shouldConfirmLeave) {
      _leaveToHome();
      return;
    }
    if (_leaveSheetOpen) return;
    _leaveSheetOpen = true;
    final action = await showSalesComposeLeaveSheet(context);
    if (!mounted) return;
    _leaveSheetOpen = false;
    if (action == null || action == SalesComposeLeaveAction.continueEditing) {
      return;
    }
    switch (action) {
      case SalesComposeLeaveAction.continueEditing:
        return;
      case SalesComposeLeaveAction.saveAndClose:
        await _saveDraft(closeAfterSave: true);
      case SalesComposeLeaveAction.discardAndClose:
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _leaveToHome();
        });
    }
  }

  Future<void> _checkout() async {
    final result = await _cubit.startCheckout();
    if (!mounted || result == null) return;
    switch (result) {
      case SalesCheckoutPrepareReady(:final args):
        await SalesCheckoutRoute($extra: args).push(context);
        if (!mounted) return;
        await _cubit.refreshPricingPreview();
      case SalesCheckoutPrepareBlocked(:final message):
        VToast.show(
          context,
          title: 'Chưa thể thanh toán',
          message: message,
          type: VToastType.warning,
        );
      case SalesCheckoutPrepareFailed(:final message):
        VToast.show(
          context,
          title: 'Chưa thể thanh toán',
          message: message,
          type: VToastType.warning,
        );
    }
  }

  Future<void> _openPriceAdjust(SalesComposeLineVm line) async {
    if (_cubit.state.busy != SalesComposeBusy.none) return;
    final result = await SalesComposePriceAdjustSheet.show(
      context,
      line: line,
      canSavePrivatePrice: !_cubit.state.customer.isWalkIn,
    );
    if (result == null || !mounted) return;

    final outcome = await _cubit.adjustPrice(
      line: line,
      draft: result.manualPrice,
      confirmBelowFloor: () async {
        if (!mounted) return false;
        return SalesComposePriceAdjustSheet.confirmBelowFloor(context);
      },
      confirmOverwrite: () async {
        if (!mounted) return false;
        return SalesComposePriceAdjustSheet.confirmOverwrite(context);
      },
    );
    if (!mounted || outcome == null) return;

    switch (outcome) {
      case SalesManualPriceApplied(:final savedPrivatePrice):
        VToast.show(
          context,
          title: savedPrivatePrice ? 'Đã lưu và áp dụng giá riêng' : 'Đã áp dụng điều chỉnh giá',
          message: '',
          type: VToastType.success,
        );
      case SalesManualPriceFailed(:final message):
        VToast.show(
          context,
          title: 'Không thể áp dụng giá',
          message: message,
          type: VToastType.danger,
        );
      case SalesManualPriceCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<SalesComposeCubit, SalesComposeState>(
            listenWhen: (previous, current) =>
                previous.saveMessage != current.saveMessage && current.saveMessage != null,
            listener: (context, state) {
              VToast.show(
                context,
                title: 'Chưa lưu được',
                message: state.saveMessage ?? 'Thêm ít nhất một sản phẩm trước khi lưu nháp.',
                type: VToastType.warning,
              );
            },
          ),
        ],
        child: BlocBuilder<SalesComposeCubit, SalesComposeState>(
          builder: (context, state) {
            if (state is SalesComposeLoading) {
              return const VPageScaffold(
                key: Key('wgt_sg02_compose_loading'),
                title: 'Tạo đơn hàng',
                showBackButton: true,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final canPop = _allowPop || !state.shouldConfirmLeave;
            // No padding: the app bar's 56pt leading slot is the tap target.
            final leaveLeading = VIconBox(
              key: const Key('btn_compose_back'),
              icon: VIcons.chevronLeft,
              semanticLabel: 'Quay lại',
              size: 40,
              backgroundColor: Colors.transparent,
              onTap: _requestLeave,
            );

            return PopScope<Object?>(
              canPop: canPop,
              onPopInvokedWithResult: (didPop, _) {
                FocusManager.instance.primaryFocus?.unfocus();
                if (!didPop) _requestLeave();
              },
              child: VPageScaffold(
                key: const Key('wgt_sg02_compose_page'),
                title: 'Tạo đơn hàng',
                showBackButton: false,
                leading: leaveLeading,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: VSpacing.space2),
                    child: BlocBuilder<SalesDraftListCubit, SalesDraftListState>(
                      buildWhen: (previous, current) =>
                          previous.totalCount != current.totalCount ||
                          previous.runtimeType != current.runtimeType ||
                          (previous is SalesDraftListLoading &&
                              current is SalesDraftListLoading &&
                              previous.isFirstLoad != current.isFirstLoad),
                      builder: (context, draftListState) {
                        final isLoadingCount =
                            draftListState is SalesDraftListInitial ||
                            (draftListState is SalesDraftListLoading && draftListState.isFirstLoad);
                        if (isLoadingCount) {
                          return VSkeleton(
                            key: const Key('btn_compose_open_drafts_loading'),
                            width: 100,
                            height: context.vDensity.controlHeightSmall,
                            semanticLabel: 'Đang tải số đơn nháp',
                          );
                        }
                        return VButton(
                          key: const Key('btn_compose_open_drafts'),
                          label: 'Đơn nháp (${draftListState.totalCount})',
                          variant: VButtonVariant.tertiary,
                          size: VButtonSize.small,
                          onPressed: _openDrafts,
                        );
                      },
                    ),
                  ),
                ],
                bottomBar: VPagePadding(
                  vertical: VSpacing.space3,
                  child: SalesComposeSummaryBar(
                    subtotalMinor: state.subtotalMinor,
                    canCheckout: state.canCheckout,
                    canSaveDraft: state.canSaveDraft,
                    onCheckout: _checkout,
                    onSaveDraft: () => _saveDraft(closeAfterSave: false),
                    pricingStatus: state.pricingStatus,
                    isSavingDraft: state.saveStatus == SalesComposeSaveStatus.saving,
                    isCheckingOut: state.busy == SalesComposeBusy.checkingOut,
                  ),
                ),
                body: SalesComposeFormBody(
                  state: state,
                  onSelectCustomer: _openCustomerPicker,
                  onCreateCustomer: _openCreateCustomer,
                  onSelectSuggestedProduct: _onSelectSuggestedProduct,
                  onQuantityChanged: _cubit.updateQuantity,
                  onDiscount: _openPriceAdjust,
                  onDeleteLine: (lineId) => _cubit.removeLine(lineId),
                  onLineTap: _onChangeLineUnit,
                  onStockExceeded: _showStockExceededToast,
                  onNoteChanged: _cubit.setOrderNote,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
