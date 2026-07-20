import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';
import '../bloc/product_profile_maintenance_cubit.dart';
import '../widgets/product_form_bottom_bar.dart';

class ProductProfileMaintenancePage extends StatelessWidget {
  const ProductProfileMaintenancePage({
    super.key,
    required this.product,
  });

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductProfileMaintenanceCubit(
        catalogModule: getIt<ICatalogModule>(),
        executionContext: getIt<IExecutionContext>(),
        productId: product.id,
        initialName: product.name,
        initialTradeName: product.tradeName,
        initialSku: product.sku,
        initialBarcode: product.barcode,
      ),
      child: const _ProductProfileMaintenanceView(),
    );
  }
}

class _ProductProfileMaintenanceView extends StatefulWidget {
  const _ProductProfileMaintenanceView();

  @override
  State<_ProductProfileMaintenanceView> createState() => _ProductProfileMaintenanceViewState();
}

class _ProductProfileMaintenanceViewState extends State<_ProductProfileMaintenanceView> {
  late final TextEditingController _nameController;
  late final TextEditingController _tradeNameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ProductProfileMaintenanceCubit>();
    _nameController = TextEditingController(text: cubit.state.name);
    _tradeNameController = TextEditingController(text: cubit.state.tradeName);
    _skuController = TextEditingController(text: cubit.state.sku);
    _barcodeController = TextEditingController(text: cubit.state.barcode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tradeNameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocListener<ProductProfileMaintenanceCubit, ProductProfileMaintenanceState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ProductProfileMaintenanceStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã cập nhật hồ sơ sản phẩm',
            type: VToastType.success,
          );
          context.pop();
        } else if (state.status == ProductProfileMaintenanceStatus.failure &&
            state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        }
      },
      child: VPageScaffold(
        key: const Key('wgt_e07_u01_fr01_01'),
        title: 'Hồ sơ sản phẩm',
        leading: IconButton(
          icon: VIcon(icon: VIcons.arrowBack, color: dynamicColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: BlocBuilder<ProductProfileMaintenanceCubit, ProductProfileMaintenanceState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VTextField(
                    key: const Key('input_profile_name'),
                    controller: _nameController,
                    label: 'Tên nội bộ',
                    hintText: 'Tên nội bộ',
                    isRequired: true,
                    errorText: state.nameError,
                    onChanged: (value) =>
                        context.read<ProductProfileMaintenanceCubit>().nameChanged(value),
                  ),
                  const SizedBox(height: VSpacing.space4),
                  VTextField(
                    controller: _tradeNameController,
                    label: 'Tên thương mại',
                    hintText: 'Tên hiển thị cho khách',
                    onChanged: (value) =>
                        context.read<ProductProfileMaintenanceCubit>().tradeNameChanged(value),
                  ),
                  const SizedBox(height: VSpacing.space4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: VTextField(
                          key: const Key('input_profile_sku'),
                          controller: _skuController,
                          label: 'SKU',
                          hintText: 'Mã SKU',
                          errorText: state.skuError,
                          onChanged: (value) =>
                              context.read<ProductProfileMaintenanceCubit>().skuChanged(value),
                        ),
                      ),
                      const SizedBox(width: VSpacing.space4),
                      Expanded(
                        child: VTextField(
                          key: const Key('input_profile_barcode'),
                          controller: _barcodeController,
                          label: 'Barcode',
                          hintText: 'Mã vạch',
                          errorText: state.barcodeError,
                          onChanged: (value) =>
                              context.read<ProductProfileMaintenanceCubit>().barcodeChanged(value),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        bottomBar: BlocBuilder<ProductProfileMaintenanceCubit, ProductProfileMaintenanceState>(
          builder: (context, state) {
            return ProductFormBottomBar(
              onCancel: () => context.pop(),
              saveKey: const Key('btn_profile_maintenance_save'),
              isLoading: state.status == ProductProfileMaintenanceStatus.submitting,
              saveEnabled: context.read<ProductProfileMaintenanceCubit>().hasChanges,
              onSave: () => context.read<ProductProfileMaintenanceCubit>().submit(),
            );
          },
        ),
      ),
    );
  }
}
