import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import '../widgets/product_control_center_body.dart';
import '../widgets/product_control_center_status_badge.dart';
import '../widgets/product_lifecycle_bottom_sheets.dart';

class ProductControlCenterRouteArgs {
  final ProductListItemModel product;
  const ProductControlCenterRouteArgs({required this.product});
}

class ProductControlCenterPage extends StatelessWidget {
  const ProductControlCenterPage({
    super.key,
    required this.productId,
    this.initialProduct,
    this.onMutated,
  });

  final String productId;
  final ProductListItemModel? initialProduct;
  final VoidCallback? onMutated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductControlCenterCubit(
        productRepository: GetIt.instance<ProductRepository>(),
      )..loadControlCenter(productId),
      child: _ProductControlCenterView(
        productId: productId,
        initialProduct: initialProduct,
        onMutated: onMutated,
      ),
    );
  }
}

class _ProductControlCenterView extends StatefulWidget {
  const _ProductControlCenterView({
    required this.productId,
    this.initialProduct,
    this.onMutated,
  });

  final String productId;
  final ProductListItemModel? initialProduct;
  final VoidCallback? onMutated;

  @override
  State<_ProductControlCenterView> createState() => _ProductControlCenterViewState();
}

class _ProductControlCenterViewState extends State<_ProductControlCenterView> {
  late ProductListItemModel _product;
  bool _isBottomSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct ??
        CatalogUiMapper.minimalFromDuplicate(
          productId: widget.productId,
          productName: '',
        );
  }

  @override
  void didUpdateWidget(covariant _ProductControlCenterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProduct != null && oldWidget.initialProduct != widget.initialProduct) {
      _product = widget.initialProduct!;
    }
  }

  void _handleDeactivate(BuildContext context, {bool confirmAcknowledgeWarnings = false}) {
    context.read<ProductControlCenterCubit>().deactivateProduct(
      _product.id,
      confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
    );
  }

  void _handleReactivate(BuildContext context) {
    context.read<ProductControlCenterCubit>().reactivateProduct(_product.id);
  }

  Future<void> _withBottomSheetGuard(Future<void> Function() action) async {
    if (_isBottomSheetOpen) return;
    setState(() => _isBottomSheetOpen = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isBottomSheetOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isSplit = VListDetailLayout.isSplitOf(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<ProductControlCenterCubit, ProductControlCenterState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == ProductControlCenterStatus.success && state.controlCenter != null) {
              _product = CatalogUiMapper.listItemFromControlCenter(
                state.controlCenter!,
                base: _product,
              );
            }
          },
        ),
        BlocListener<ProductControlCenterCubit, ProductControlCenterState>(
          listenWhen: (previous, current) =>
              previous.actionStatus != current.actionStatus,
          listener: (context, state) {
            if (state.actionStatus == ProductLifecycleActionStatus.success) {
              widget.onMutated?.call();
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
                  setState(() => _isBottomSheetOpen = false);
                }
              });
              context.read<ProductControlCenterCubit>().resetActionState();
            }
          },
        ),
      ],
      child: BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
        builder: (context, state) {
          final effectiveProduct = state.controlCenter != null
              ? CatalogUiMapper.listItemFromControlCenter(
                  state.controlCenter!,
                  base: _product,
                )
              : _product;

          final titleText = effectiveProduct.name.isNotEmpty
              ? effectiveProduct.name
              : (state.controlCenter?.profile.name ?? '');

          return KeyedSubtree(
            key: const Key('wgt_e01_u02_fr01_01'),
            child: VPageScaffold(
              key: const Key('wgt_e02_u03_fr01_01'),
              title: titleText,
              titleStyle: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              showBackButton: false,
              leading: isSplit
                  ? null
                  : IconButton(
                      icon: VIcon(icon: VIcons.arrowBack, color: dynamicColors.textPrimary),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/products/items');
                        }
                      },
                    ),
              actions: [
                ProductControlCenterStatusBadge(
                  fallbackIsSoftDeleted: effectiveProduct.isSoftDeleted,
                ),
              ],
              body: ProductControlCenterBody(
                product: effectiveProduct,
                state: state,
                onMutated: widget.onMutated,
                onDeactivate: () => _withBottomSheetGuard(
                  () => showProductDeactivateBottomSheet(
                    context: context,
                    onConfirm: () => _handleDeactivate(context),
                  ),
                ),
                onReactivate: () => _withBottomSheetGuard(
                  () => showProductReactivateBottomSheet(
                    context: context,
                    onConfirm: () => _handleReactivate(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
