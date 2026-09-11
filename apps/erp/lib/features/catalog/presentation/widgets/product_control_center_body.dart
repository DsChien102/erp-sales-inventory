import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../pages/product_custom_field_group_edit_page.dart';
import '../pages/product_manual_base_price_page.dart';
import '../pages/product_measurement_units_page.dart';
import '../pages/product_price_bands_page.dart';
import '../pages/product_readiness_checklist_page.dart';
import '../pages/product_stock_adjustment_page.dart';
import '../pages/product_note_edit_page.dart';
import 'product_control_center_custom_fields_section.dart';
import 'product_control_center_danger_section.dart';
import 'product_control_center_identity_section.dart';
import 'product_control_center_meta_section.dart';
import 'product_control_center_operational_section.dart';
import 'product_control_center_profile_card.dart';
import 'product_control_center_readiness_banner.dart';
import 'product_delete_confirm_dialog.dart';
import 'product_restore_confirm_dialog.dart';

class ProductControlCenterBody extends StatelessWidget {
  const ProductControlCenterBody({
    super.key,
    required this.product,
    required this.state,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final ProductListItemModel product;
  final ProductControlCenterState state;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final controlCenter = state.controlCenter;
    final isLoading =
        state.status == ProductControlCenterStatus.loading ||
        state.status == ProductControlCenterStatus.initial;

    if (state.status == ProductControlCenterStatus.failure) {
      return Center(
        child: VText(
          state.errorMessage ?? 'Không thể tải chi tiết sản phẩm',
          variant: VTextVariant.bodyDefault,
          color: dynamicColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      );
    }

    final blockersCount = controlCenter?.readinessSummary.blockers.length ?? 0;
    final isSoftDeleted = controlCenter?.profile.isSoftDeleted ?? product.isSoftDeleted;

    return SingleChildScrollView(
      child: VPagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controlCenter != null)
              ProductControlCenterProfileCard(
                profile: controlCenter.profile,
                priceBand: controlCenter.priceBand,
                stock: controlCenter.stock,
              )
            else if (isLoading)
              const SizedBox(height: VSpacing.space12),
            if (controlCenter != null && blockersCount > 0) ...[
              const VGap.sm(),
              ProductControlCenterReadinessBanner(
                blockersCount: blockersCount,
                onTap: () => _openChecklist(context),
              ),
            ],
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(VSpacing.space8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controlCenter != null) ...[
              const VGap.sm(),
              ProductControlCenterIdentitySection(
                profile: controlCenter.profile,
                onEditProfile: isSoftDeleted
                    ? null
                    : () => _openProfileMaintenance(context, controlCenter),
                onEditImages: isSoftDeleted
                    ? null
                    : () => _openImagesMaintenance(context, controlCenter),
              ),
              const VGap.sm(),
              ProductControlCenterOperationalSection(
                units: controlCenter.units,
                stock: controlCenter.stock,
                basePrice: controlCenter.basePrice,
                priceBand: controlCenter.priceBand,
                onEditUnits: isSoftDeleted
                    ? null
                    : () => _openMeasurementUnits(context, controlCenter),
                onEditStock: isSoftDeleted
                    ? null
                    : () => _openStockAdjustment(context, controlCenter),
                onEditBasePrice: isSoftDeleted
                    ? null
                    : controlCenter.basePrice.canEdit
                    ? () => _openManualBasePrice(context, controlCenter)
                    : null,
                onEditPriceBand: isSoftDeleted ? null : () => _openPriceBands(context),
              ),
              const VGap.sm(),
              ProductControlCenterCustomFieldsSection(
                groups: controlCenter.customFieldGroupCards,
                onEditGroup: (group) => _openCustomFieldGroup(context, group),
              ),
              const VGap.sm(),
              ProductControlCenterMetaSection(
                note: controlCenter.profile.note,
                changeHistoryPreview: controlCenter.changeHistoryPreview,
                onEditNote: () => _openNoteEdit(context, controlCenter),
                onViewChangeHistory: () {
                  context.push(
                    '/products/items/pcc/change-history',
                    extra: product,
                  );
                },
              ),
              const VGap.sm(),
              ProductControlCenterDangerSection(
                businessStatus: controlCenter.profile.businessStatus,
                isSoftDeleted: isSoftDeleted,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
                onDelete: () {
                  ProductDeleteConfirmDialog.show(
                    context,
                    cubit: ProductSoftDeleteCubit(
                      mediator: GetIt.instance<ICatalogModule>(),
                      executionContext: GetIt.instance<IExecutionContext>(),
                    ),
                    productId: product.id,
                    productName: product.name,
                  );
                },
                onRestore: () {
                  ProductRestoreConfirmDialog.show(
                    context,
                    cubit: ProductSoftDeleteCubit(
                      mediator: GetIt.instance<ICatalogModule>(),
                      executionContext: GetIt.instance<IExecutionContext>(),
                    ),
                    productId: product.id,
                    productName: product.name,
                    readinessSummary: controlCenter.readinessSummary,
                    onRestored: () => _reload(context),
                  );
                },
              ),
            ],
            const SafeArea(
              top: false,
              child: VGap.xl(),
            ),
          ],
        ),
      ),
    );
  }

  void _reload(BuildContext context) {
    context.read<ProductControlCenterCubit>().loadControlCenter(product.id);
  }

  Future<void> _reloadAfterPush(BuildContext context, Future<void> navigation) async {
    await navigation;
    if (!context.mounted) return;
    _reload(context);
  }

  ProductListItemModel _productFromProfile(ProductControlCenterDto controlCenter) {
    return product.copyWith(
      name: controlCenter.profile.name,
      tradeName: controlCenter.profile.tradeName,
      sku: controlCenter.profile.sku,
      barcode: controlCenter.profile.barcode,
      images: controlCenter.profile.images,
      imageUrl: controlCenter.profile.primaryImageUrl,
    );
  }

  Future<void> _openChecklist(BuildContext context) async {
    final cubit = context.read<ProductControlCenterCubit>();
    // Reload PCC so hasRequiredMissing reflects latest saves before prioritizing group.
    await cubit.loadControlCenter(product.id);
    if (!context.mounted) return;
    await cubit.loadReadinessForChecklist(product.id);
    if (!context.mounted) return;

    final readinessView = cubit.state.readinessView;
    if (readinessView == null) return;

    final controlCenter = cubit.state.controlCenter;
    final updatedProduct = controlCenter != null
        ? product.copyWith(baseUnit: controlCenter.units.baseUnitName)
        : product;
    await _reloadAfterPush(
      context,
      context.push(
        '/products/items/pcc/checklist',
        extra: ProductReadinessChecklistRouteArgs(
          readinessView: readinessView,
          product: updatedProduct,
          customFieldGroupCards: controlCenter?.customFieldGroupCards ?? const [],
        ),
      ),
    );
  }

  Future<void> _openProfileMaintenance(
    BuildContext context,
    ProductControlCenterDto controlCenter,
  ) {
    return _reloadAfterPush(
      context,
      context.push(
        '/products/items/pcc/profile-maintenance',
        extra: _productFromProfile(controlCenter),
      ),
    );
  }

  Future<void> _openImagesMaintenance(
    BuildContext context,
    ProductControlCenterDto controlCenter,
  ) {
    return _reloadAfterPush(
      context,
      context.push(
        '/products/items/pcc/images-maintenance',
        extra: _productFromProfile(controlCenter),
      ),
    );
  }

  Future<void> _openMeasurementUnits(
    BuildContext context,
    ProductControlCenterDto controlCenter,
  ) {
    return _reloadAfterPush(
      context,
      context.push(
        '/products/items/pcc/measurement-units',
        extra: ProductMeasurementUnitsRouteArgs(
          product: product.copyWith(baseUnit: controlCenter.units.baseUnitName),
        ),
      ),
    );
  }

  Future<void> _openStockAdjustment(
    BuildContext context,
    ProductControlCenterDto controlCenter,
  ) async {
    if (!controlCenter.stock.canAdjust) return;

    final didChange = await context.push<bool>(
      '/products/items/pcc/stock',
      extra: ProductStockAdjustmentRouteArgs(
        product: product,
        currentQuantity: controlCenter.stock.quantity,
        unitName: controlCenter.stock.unitName,
        stockVersion: controlCenter.stock.currentVersion,
      ),
    );
    if (didChange == true && context.mounted) {
      _reload(context);
    }
  }

  Future<void> _openNoteEdit(
    BuildContext context,
    ProductControlCenterDto controlCenter,
  ) async {
    final didChange = await context.push<bool>(
      '/products/items/pcc/note',
      extra: ProductNoteEditRouteArgs(
        product: product,
        currentNote: controlCenter.profile.note,
      ),
    );
    if (didChange == true && context.mounted) {
      _reload(context);
    }
  }

  Future<void> _openManualBasePrice(
    BuildContext context,
    ProductControlCenterDto controlCenter,
  ) {
    return _reloadAfterPush(
      context,
      context.push(
        '/products/items/pcc/manual-base-price',
        extra: ProductManualBasePriceRouteArgs(
          product: product.copyWith(baseUnit: controlCenter.units.baseUnitName),
          basePriceCard: controlCenter.basePrice,
        ),
      ),
    );
  }

  Future<void> _openPriceBands(BuildContext context) {
    return _reloadAfterPush(
      context,
      context.push(
        '/products/items/pcc/price-bands',
        extra: ProductPriceBandsRouteArgs(
          productId: product.id,
          productName: product.name,
        ),
      ),
    );
  }

  Future<void> _openCustomFieldGroup(
    BuildContext context,
    CustomFieldGroupCardDto group,
  ) {
    return _reloadAfterPush(
      context,
      context.push(
        '/products/items/pcc/custom-fields/edit',
        extra: ProductCustomFieldGroupEditRouteArgs(
          productId: product.id,
          productName: product.name,
          groupId: group.groupId,
        ),
      ),
    );
  }
}
