import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:c45_design_system/design_system.dart';

class ProductGuidedCreatePage extends StatelessWidget {
  const ProductGuidedCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductGuidedCreateCubit(
        productRepository: GetIt.instance<ProductRepository>(),
        productPriceRepository: GetIt.instance<ProductPriceRepository>(),
        customFieldRepository: GetIt.instance<CustomFieldRepository>(),
        measurementUnitRepository: GetIt.instance<MeasurementUnitRepository>(),
      ),
      child: const _ProductGuidedCreateView(),
    );
  }
}

class _ProductGuidedCreateView extends StatelessWidget {
  const _ProductGuidedCreateView();

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocListener<ProductGuidedCreateCubit, ProductGuidedCreateState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ProductGuidedCreateStatus.success && state.createdProduct != null) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Sản phẩm đã được khởi tạo!',
            type: VToastType.success,
          );
          context.pop(state.createdProduct!);
        } else if (state.status == ProductGuidedCreateStatus.error &&
            state.errorMessage != null &&
            !state.hasDuplicateError) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        }
      },
      child: VPageScaffold(
        key: const Key('wgt_e02_u01_fr01_01'),
        resizeToAvoidBottomInset: false,
        title: 'Tạo nhanh sản phẩm',
        leading: IconButton(
          icon: VIcon(icon: VIcons.arrowBack, color: dynamicColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        body: ProductGuidedCreateBody(
          onCancel: () => context.pop(),
          onOpenDuplicateProduct: (productId, productName) {
            final product = CatalogUiMapper.minimalFromDuplicate(
              productId: productId,
              productName: productName,
            );
            context.push(
              '/products/items/$productId/view',
              extra: product,
            );
          },
        ),
      ),
    );
  }
}
