import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'product_readiness_checklist_page.dart';
import 'product_measurement_units_page.dart';
import 'product_manual_base_price_page.dart';
import 'product_custom_field_group_edit_page.dart';
import 'product_guided_create_page.dart';
import 'product_price_bands_page.dart';
import '../widgets/product_control_center_operational_section.dart';
import '../widgets/product_control_center_profile_card.dart';
import '../widgets/product_control_center_danger_section.dart';
import '../widgets/product_lifecycle_bottom_sheets.dart';
import '../widgets/product_delete_confirm_dialog.dart';
import '../widgets/product_restore_confirm_dialog.dart';
import '../widgets/product_control_center_readiness_banner.dart';
import 'product_stock_adjustment_page.dart';

class ProductControlCenterRouteArgs {
  final ProductListItemModel product;
  const ProductControlCenterRouteArgs({required this.product});
}

class ProductControlCenterPage extends StatelessWidget {
  const ProductControlCenterPage({
    super.key,
    required this.product,
  });

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductControlCenterCubit(
        catalogModule: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
      )..loadControlCenter(product.id),
      child: _ProductControlCenterView(product: product),
    );
  }
}

class _ProductControlCenterView extends StatefulWidget {
  const _ProductControlCenterView({required this.product});

  final ProductListItemModel product;

  @override
  State<_ProductControlCenterView> createState() => _ProductControlCenterViewState();
}

class _ProductControlCenterViewState extends State<_ProductControlCenterView> {
  ProductListItemModel get product => widget.product;
  bool _isBottomSheetOpen = false;

  void _showEditPlaceholder(BuildContext context) {
    VToast.show(
      context,
      title: 'Chỉnh sửa',
      message: 'Chức năng sửa thông tin sẽ khả dụng trong slice tiếp theo.',
      type: VToastType.info,
    );
  }

  Future<void> _openChecklist(BuildContext context) async {
    final cubit = context.read<ProductControlCenterCubit>();
    await cubit.loadReadinessForChecklist(product.id);
    if (!context.mounted) return;

    final readinessView = cubit.state.readinessView;
    if (readinessView == null) return;

    final controlCenter = cubit.state.controlCenter;
    final updatedProduct = controlCenter != null
        ? product.copyWith(baseUnit: controlCenter.units.baseUnitName)
        : product;

    final firstGroupId = controlCenter?.customFieldGroupCards.firstOrNull?.groupId;

    await context.push(
      '/products/items/pcc/checklist',
      extra: ProductReadinessChecklistRouteArgs(
        readinessView: readinessView,
        product: updatedProduct,
        defaultCustomFieldGroupId: firstGroupId,
      ),
    );
    if (!context.mounted) return;
    context.read<ProductControlCenterCubit>().loadControlCenter(product.id);
  }

  void _handleDeactivate(BuildContext context, {bool confirmAcknowledgeWarnings = false}) {
    context.read<ProductControlCenterCubit>().deactivateProduct(
      product.id,
      confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
    );
  }

  void _handleReactivate(BuildContext context) {
    context.read<ProductControlCenterCubit>().reactivateProduct(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocListener<ProductControlCenterCubit, ProductControlCenterState>(
      listenWhen: (previous, current) => previous.actionStatus != current.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == ProductLifecycleActionStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã cập nhật trạng thái kinh doanh của sản phẩm.',
            type: VToastType.success,
          );
          context.read<ProductControlCenterCubit>().resetActionState();
        } else if (state.actionStatus == ProductLifecycleActionStatus.failure) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.actionErrorMessage ?? 'Đã xảy ra lỗi khi thực hiện hành động.',
            type: VToastType.danger,
          );
          context.read<ProductControlCenterCubit>().resetActionState();
        } else if (state.actionStatus == ProductLifecycleActionStatus.warning) {
          if (_isBottomSheetOpen) return;
          _isBottomSheetOpen = true;
          showProductDeactivateBottomSheet(
            context: context,
            warnings: state.actionWarnings,
            onConfirm: () => _handleDeactivate(context, confirmAcknowledgeWarnings: true),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isBottomSheetOpen = false;
              });
            }
          });
          context.read<ProductControlCenterCubit>().resetActionState();
        }
      },
      child: KeyedSubtree(
        key: const Key('wgt_e01_u02_fr01_01'),
        child: Scaffold(
          key: const Key('wgt_e02_u03_fr01_01'),
          backgroundColor: dynamicColors.background,
          appBar: VAppBar(
            title: product.name,
            titleStyle: VTypography.headingH3.copyWith(
              color: dynamicColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: dynamicColors.textPrimary),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/products/items');
                }
              },
            ),
            actions: [
              BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
                builder: (context, state) {
                  final isReady =
                      state.controlCenter?.readinessSummary.status == ReadinessStatus.readyToSell;
                  final isSoftDeleted =
                      state.controlCenter?.profile.isSoftDeleted ?? product.isSoftDeleted;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: VBadge(
                        label: isSoftDeleted
                            ? 'Đã xóa'
                            : isReady
                            ? 'Sẵn sàng bán'
                            : 'Thiếu dữ liệu',
                        status: isSoftDeleted
                            ? VBadgeStatus.locked
                            : isReady
                            ? VBadgeStatus.success
                            : VBadgeStatus.danger,
                        isSmall: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
            builder: (context, state) {
              final controlCenter = state.controlCenter;
              final isLoading =
                  state.status == ProductControlCenterStatus.loading ||
                  state.status == ProductControlCenterStatus.initial;

              if (state.status == ProductControlCenterStatus.failure) {
                return Center(
                  child: Text(
                    state.errorMessage ?? 'Không thể tải chi tiết sản phẩm',
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                );
              }

              final blockersCount = controlCenter?.readinessSummary.blockers.length ?? 0;
              final isSoftDeleted = controlCenter?.profile.isSoftDeleted ?? product.isSoftDeleted;

              return SingleChildScrollView(
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
                      const SizedBox(height: 96),

                    if (controlCenter != null && blockersCount > 0) ...[
                      ProductControlCenterReadinessBanner(
                        blockersCount: blockersCount,
                        onTap: () => _openChecklist(context),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (controlCenter != null) ...[
                      ProductControlCenterSectionCard(
                        title: 'Hồ sơ sản phẩm',
                        icon: Icons.assignment_outlined,
                        subtitle:
                            '${controlCenter.profile.sku ?? 'Chưa có mã SKU'} · ${controlCenter.profile.barcode ?? 'Chưa có mã vạch'}',
                        onEdit: isSoftDeleted
                            ? null
                            : () async {
                                final updatedProduct = product.copyWith(
                                  name: controlCenter.profile.name,
                                  tradeName: controlCenter.profile.tradeName,
                                  sku: controlCenter.profile.sku,
                                  barcode: controlCenter.profile.barcode,
                                  images: controlCenter.profile.images,
                                  imageUrl: controlCenter.profile.primaryImageUrl,
                                );
                                await context.push(
                                  '/products/items/pcc/profile-maintenance',
                                  extra: updatedProduct,
                                );
                                if (!context.mounted) return;
                                context.read<ProductControlCenterCubit>().loadControlCenter(
                                  product.id,
                                );
                              },
                      ),
                      ProductControlCenterSectionCard(
                        title: 'Ảnh sản phẩm',
                        icon: Icons.camera_alt_outlined,
                        subtitle: '${controlCenter.profile.images.length} ảnh',
                        onEdit: isSoftDeleted
                            ? null
                            : () async {
                                final updatedProduct = product.copyWith(
                                  name: controlCenter.profile.name,
                                  tradeName: controlCenter.profile.tradeName,
                                  sku: controlCenter.profile.sku,
                                  barcode: controlCenter.profile.barcode,
                                  images: controlCenter.profile.images,
                                  imageUrl: controlCenter.profile.primaryImageUrl,
                                );
                                await context.push(
                                  '/products/items/pcc/images-maintenance',
                                  extra: updatedProduct,
                                );
                                if (!context.mounted) return;
                                context.read<ProductControlCenterCubit>().loadControlCenter(
                                  product.id,
                                );
                              },
                      ),
                      ProductControlCenterOperationalSection(
                        units: controlCenter.units,
                        stock: controlCenter.stock,
                        basePrice: controlCenter.basePrice,
                        priceBand: controlCenter.priceBand,
                        onEditUnits: isSoftDeleted
                            ? null
                            : () async {
                                final updatedProduct = product.copyWith(
                                  baseUnit: controlCenter.units.baseUnitName,
                                );
                                await context.push(
                                  '/products/items/pcc/measurement-units',
                                  extra: ProductMeasurementUnitsRouteArgs(product: updatedProduct),
                                );
                                if (!context.mounted) return;
                                context.read<ProductControlCenterCubit>().loadControlCenter(
                                  product.id,
                                );
                              },
                        onEditStock: isSoftDeleted
                            ? null
                            : () async {
                                if (controlCenter.stock.canAdjust) {
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
                                    context.read<ProductControlCenterCubit>().loadControlCenter(
                                      product.id,
                                    );
                                  }
                                }
                              },
                        onEditBasePrice: isSoftDeleted
                            ? null
                            : controlCenter.basePrice.canEdit
                            ? () async {
                                await context.push(
                                  '/products/items/pcc/manual-base-price',
                                  extra: ProductManualBasePriceRouteArgs(
                                    product: product,
                                    basePriceCard: controlCenter.basePrice,
                                  ),
                                );
                                if (!context.mounted) return;
                                context.read<ProductControlCenterCubit>().loadControlCenter(
                                  product.id,
                                );
                              }
                            : controlCenter.basePrice.mode == BasePriceMode.costingModule
                            ? () => _showEditPlaceholder(context)
                            : null,
                        onEditPriceBand: isSoftDeleted
                            ? null
                            : () async {
                                await context.push(
                                  '/products/items/pcc/price-bands',
                                  extra: ProductPriceBandsRouteArgs(
                                    productId: product.id,
                                    productName: product.name,
                                  ),
                                );
                                if (!context.mounted) return;
                                context.read<ProductControlCenterCubit>().loadControlCenter(
                                  product.id,
                                );
                              },
                      ),
                      ...controlCenter.customFieldGroupCards.map((group) {
                        IconData iconData = Icons.assignment_outlined;
                        final nameLower = group.name.toLowerCase();
                        if (nameLower.contains('thuốc')) {
                          iconData = Icons.medication_outlined;
                        } else if (nameLower.contains('quy cách') ||
                            nameLower.contains('bảo quản')) {
                          iconData = Icons.inventory_2_outlined;
                        } else if (nameLower.contains('tuân thủ')) {
                          iconData = Icons.lock_outline;
                        }

                        final filledCount = group.fields
                            .where((f) => f.displayValue != null && f.displayValue!.isNotEmpty)
                            .length;
                        final allInactive = group.fields.every((f) => !f.isActive);
                        return ProductControlCenterSectionCard(
                          title: group.name,
                          icon: iconData,
                          subtitle: '$filledCount/${group.fields.length} trường đã điền',
                          actionText: allInactive ? 'Xem' : 'Sửa',
                          onEdit: () async {
                            await context.push(
                              '/products/items/pcc/custom-fields/edit',
                              extra: ProductCustomFieldGroupEditRouteArgs(
                                productId: product.id,
                                productName: product.name,
                                groupId: group.groupId,
                              ),
                            );
                            if (!context.mounted) return;
                            context.read<ProductControlCenterCubit>().loadControlCenter(
                              product.id,
                            );
                          },
                        );
                      }),
                      ProductControlCenterSectionCard(
                        title: 'Ghi chú',
                        icon: Icons.description_outlined,
                        subtitle: controlCenter.profile.note?.isNotEmpty == true
                            ? 'Đã điền ghi chú'
                            : 'Chưa có ghi chú',
                        onEdit: () => _showEditPlaceholder(context),
                      ),
                      ProductControlCenterSectionCard(
                        title: 'Lịch sử thay đổi',
                        icon: Icons.history,
                        subtitle: controlCenter.changeHistoryPreview.isNotEmpty
                            ? '${controlCenter.changeHistoryPreview.first.summary} · ${controlCenter.changeHistoryPreview.first.occurredAt.toString().substring(0, 10)}'
                            : 'Tạo sản phẩm · 2026-07-06',
                        actionText: 'Xem',
                        onEdit: () {
                          context.push(
                            '/products/items/pcc/change-history',
                            extra: product,
                          );
                        },
                      ),
                      ProductControlCenterDangerSection(
                        businessStatus: controlCenter.profile.businessStatus,
                        isSoftDeleted: isSoftDeleted,
                        onDeactivate: () async {
                          if (_isBottomSheetOpen) return;
                          setState(() {
                            _isBottomSheetOpen = true;
                          });
                          await showProductDeactivateBottomSheet(
                            context: context,
                            onConfirm: () => _handleDeactivate(context),
                          );
                          if (mounted) {
                            setState(() {
                              _isBottomSheetOpen = false;
                            });
                          }
                        },
                        onReactivate: () async {
                          if (_isBottomSheetOpen) return;
                          setState(() {
                            _isBottomSheetOpen = true;
                          });
                          await showProductReactivateBottomSheet(
                            context: context,
                            onConfirm: () => _handleReactivate(context),
                          );
                          if (mounted) {
                            setState(() {
                              _isBottomSheetOpen = false;
                            });
                          }
                        },
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
                            onRestored: () {
                              context.read<ProductControlCenterCubit>().loadControlCenter(
                                product.id,
                              );
                            },
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
