import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

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

  void _handleDeactivate(BuildContext context, {bool confirmAcknowledgeWarnings = false}) {
    context.read<ProductControlCenterCubit>().deactivateProduct(
      product.id,
      confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
    );
  }

  void _handleReactivate(BuildContext context) {
    context.read<ProductControlCenterCubit>().reactivateProduct(product.id);
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
              setState(() => _isBottomSheetOpen = false);
            }
          });
          context.read<ProductControlCenterCubit>().resetActionState();
        }
      },
      child: KeyedSubtree(
        key: const Key('wgt_e01_u02_fr01_01'),
        child: VPageScaffold(
          key: const Key('wgt_e02_u03_fr01_01'),
          title: product.name,
          titleStyle: VTypography.headingH3.copyWith(
            color: dynamicColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          leading: IconButton(
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
              fallbackIsSoftDeleted: product.isSoftDeleted,
            ),
          ],
          body: BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
            builder: (context, state) {
              return ProductControlCenterBody(
                product: product,
                state: state,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
