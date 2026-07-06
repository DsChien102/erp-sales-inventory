import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../widgets/product_conversion_unit_item.dart';
import '../widgets/product_measurement_units_bottom_bar.dart';

class ProductMeasurementUnitsRouteArgs {
  final ProductListItemModel product;
  const ProductMeasurementUnitsRouteArgs({required this.product});
}

class ProductMeasurementUnitsPage extends StatelessWidget {
  const ProductMeasurementUnitsPage({
    super.key,
    required this.product,
  });

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductMeasurementUnitsCubit(
        catalogModule: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
      )..init(product.id, product.baseUnit),
      child: _ProductMeasurementUnitsView(product: product),
    );
  }
}

class _ProductMeasurementUnitsView extends StatefulWidget {
  const _ProductMeasurementUnitsView({required this.product});

  final ProductListItemModel product;

  @override
  State<_ProductMeasurementUnitsView> createState() => _ProductMeasurementUnitsViewState();
}

class _ProductMeasurementUnitsViewState extends State<_ProductMeasurementUnitsView> {
  bool _isEditingBaseUnit = false;
  final _baseUnitController = TextEditingController();
  final _conversionUnitNameController = TextEditingController();
  final _conversionUnitRatioController = TextEditingController();
  bool _isAddingConversionUnit = false;

  @override
  void dispose() {
    _baseUnitController.dispose();
    _conversionUnitNameController.dispose();
    _conversionUnitRatioController.dispose();
    super.dispose();
  }

  void _onSaveBaseUnit(BuildContext context, ProductMeasurementUnitsState state) {
    final text = _baseUnitController.text.trim().toLowerCase();
    if (text.isEmpty) {
      VToast.show(
        context,
        title: 'Lỗi',
        message: 'Vui lòng nhập tên đơn vị cơ sở',
        type: VToastType.danger,
      );
      return;
    }

    final cubit = context.read<ProductMeasurementUnitsCubit>();
    // Check if it exists in tenantUnits
    final existingUnit = state.tenantUnits.where((u) => u.name.toLowerCase() == text).firstOrNull;
    if (existingUnit != null) {
      cubit.setBaseUnitExisting(existingUnit.id, existingUnit.name);
    } else {
      cubit.setBaseUnitNew(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocConsumer<ProductMeasurementUnitsCubit, ProductMeasurementUnitsState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus ||
          previous.unitMutationStatus != current.unitMutationStatus,
      listener: (context, state) {
        if (state.saveStatus == ProductMeasurementUnitsStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã lưu đơn vị cơ sở',
            type: VToastType.success,
          );
          setState(() {
            _isEditingBaseUnit = false;
          });
        } else if (state.saveStatus == ProductMeasurementUnitsStatus.failure) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage ?? 'Có lỗi xảy ra',
            type: VToastType.danger,
          );
        }

        if (state.unitMutationStatus == ProductMeasurementUnitsStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã cập nhật đơn vị quy đổi',
            type: VToastType.success,
          );
          setState(() {
            _isAddingConversionUnit = false;
            _conversionUnitNameController.clear();
            _conversionUnitRatioController.clear();
          });
        } else if (state.unitMutationStatus == ProductMeasurementUnitsStatus.failure) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage ?? 'Có lỗi xảy ra',
            type: VToastType.danger,
          );
        }
      },
      builder: (context, state) {
        final hasBaseUnit = state.baseUnitName != null && state.baseUnitName!.isNotEmpty;

        return Scaffold(
          backgroundColor: dynamicColors.background,
          appBar: VAppBar(
            title: 'Đơn vị đo lường',
            titleStyle: VTypography.headingH3.copyWith(
              color: dynamicColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            subtitle: widget.product.name,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: dynamicColors.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Base Unit Card
                  VCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐƠN VỊ CƠ SỞ',
                          style: VTypography.bodySmall.copyWith(
                            color: dynamicColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!hasBaseUnit && !_isEditingBaseUnit) ...[
                          Text(
                            'Chưa thiết lập (không bắt buộc).',
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isEditingBaseUnit = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: dynamicColors.primary.withValues(alpha: 0.5),
                                  style: BorderStyle
                                      .solid, // dotted in mockup but dashed/dotted usually needs custom painter or package, so we just use border
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: dynamicColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Thiết lập đơn vị cơ sở',
                                    style: VTypography.bodyDefault.copyWith(
                                      color: dynamicColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (_isEditingBaseUnit) ...[
                          Text(
                            'Tên đơn vị cơ sở',
                            style: VTypography.bodySmall.copyWith(
                              color: dynamicColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          VTextField(
                            controller: _baseUnitController,
                            hintText: 'hộp, chai, gói, lọ, kg...',
                            onChanged: (val) {
                              setState(() {}); // trigger rebuild to update lowercase hint
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sẽ lưu ở dạng chữ thường: ${_baseUnitController.text.toLowerCase()}',
                            style: VTypography.bodySmall.copyWith(
                              color: dynamicColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditingBaseUnit = false;
                                  });
                                },
                                child: Text(
                                  'Huỷ',
                                  style: VTypography.bodyDefault.copyWith(
                                    color: dynamicColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              VButton(
                                label: 'Lưu',
                                isLoading:
                                    state.saveStatus == ProductMeasurementUnitsStatus.loading,
                                onPressed: () => _onSaveBaseUnit(context, state),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            state.baseUnitName!,
                            style: VTypography.headingH4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: dynamicColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tuỳ chọn. Khi đã có giao dịch, không nên đổi.',
                            style: VTypography.bodySmall.copyWith(
                              color: dynamicColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Conversion Units Card
                  VCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐƠN VỊ QUY ĐỔI (${state.conversionUnits.length})',
                          style: VTypography.bodySmall.copyWith(
                            color: dynamicColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!hasBaseUnit) ...[
                          Text(
                            'Cần đặt đơn vị cơ sở trước khi thêm đơn vị quy đổi.',
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textPrimary,
                            ),
                          ),
                        ] else ...[
                          if (state.conversionUnits.isEmpty && !_isAddingConversionUnit)
                            Text(
                              'Chưa có đơn vị quy đổi.',
                              style: VTypography.bodyDefault.copyWith(
                                color: dynamicColors.textPrimary,
                              ),
                            )
                          else if (state.conversionUnits.isNotEmpty)
                            ...state.conversionUnits.map((u) {
                              return ProductConversionUnitItem(
                                key: Key('conversion_unit_item_${u.id}'),
                                unit: u,
                                baseUnitName: state.baseUnitName!,
                              );
                            }),

                          const SizedBox(height: 16),

                          if (!_isAddingConversionUnit)
                            InkWell(
                              key: const Key('btn_add_conversion_unit'),
                              onTap: () {
                                setState(() {
                                  _isAddingConversionUnit = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: dynamicColors.primary.withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: dynamicColors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thêm đơn vị quy đổi',
                                      style: VTypography.bodyDefault.copyWith(
                                        color: dynamicColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tên đơn vị',
                                        style: VTypography.bodySmall.copyWith(
                                          color: dynamicColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      VTextField(
                                        key: const Key('input_conversion_unit_name'),
                                        controller: _conversionUnitNameController,
                                        hintText: 'hộp, thùng...',
                                        onChanged: (val) {
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tỉ lệ (x ${state.baseUnitName})',
                                        style: VTypography.bodySmall.copyWith(
                                          color: dynamicColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      VTextField(
                                        key: const Key('input_conversion_unit_rate'),
                                        controller: _conversionUnitRatioController,
                                        hintText: '10',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sẽ lưu ở dạng chữ thường: ${_conversionUnitNameController.text.toLowerCase()}',
                              style: VTypography.bodySmall.copyWith(
                                color: dynamicColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isAddingConversionUnit = false;
                                    });
                                  },
                                  child: Text(
                                    'Huỷ',
                                    style: VTypography.bodyDefault.copyWith(
                                      color: dynamicColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                VButton(
                                  key: const Key('btn_submit_conversion_unit'),
                                  label: 'Thêm',
                                  isLoading:
                                      state.unitMutationStatus ==
                                      ProductMeasurementUnitsStatus.loading,
                                  onPressed: () {
                                    final name = _conversionUnitNameController.text
                                        .trim()
                                        .toLowerCase();
                                    final ratioStr = _conversionUnitRatioController.text.trim();
                                    final ratio = double.tryParse(ratioStr);

                                    if (name.isEmpty) {
                                      VToast.show(
                                        context,
                                        title: 'Lỗi',
                                        message: 'Vui lòng nhập tên đơn vị',
                                        type: VToastType.danger,
                                      );
                                      return;
                                    }
                                    if (ratio == null || ratio <= 0) {
                                      VToast.show(
                                        context,
                                        title: 'Lỗi',
                                        message: 'Tỷ lệ quy đổi phải > 0',
                                        type: VToastType.danger,
                                      );
                                      return;
                                    }

                                    context.read<ProductMeasurementUnitsCubit>().addConversionUnit(
                                      name,
                                      ratio,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const ProductMeasurementUnitsBottomBar(),
        );
      },
    );
  }
}
