import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../data/models.dart';
import '../data/product_repository.dart';
import '../logic/product_list_cubit.dart';
import 'pages/product_catalog_tab_page.dart';

/// Shell khu Sản phẩm: giữ một [ProductListCubit] cho cả danh sách và chi tiết (PCC),
/// chia 2 cột trên web rộng (danh sách trái, PCC phải).
class ProductAreaShell extends StatelessWidget {
  const ProductAreaShell({
    super.key,
    required this.child,
    this.selectedId,
    this.productRepository,
    this.cubit,
  });

  final Widget child;
  final String? selectedId;
  final ProductRepository? productRepository;

  /// Chỉ cho test: dùng cubit có sẵn, shell không tạo và không tải.
  final ProductListCubit? cubit;

  static final Set<ProductBusinessStatus> _catalogListStatuses = {
    ProductBusinessStatus.active,
    ProductBusinessStatus.inactive,
  };

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: Builder(builder: (context) => _buildLayout(cubit!)),
      );
    }
    return BlocProvider(
      create: (_) => ProductListCubit(
        productRepository: productRepository ?? getIt<ProductRepository>(),
      )..fetchProducts(
          criteria: ProductSearchCriteria(businessStatuses: _catalogListStatuses),
        ),
      child: Builder(
        builder: (context) => _buildLayout(context.read<ProductListCubit>()),
      ),
    );
  }

  Widget _buildLayout(ProductListCubit listCubit) {
    return VListDetailLayout(
      list: ProductCatalogTabPage(cubit: listCubit, selectedId: selectedId),
      detail: child,
    );
  }
}

