import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/catalog/presentation.dart';

import '../widgets/product_conversion_unit_delete_blocked_dialog.dart';
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
        measurementUnitRepository: GetIt.instance<MeasurementUnitRepository>(),
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
  bool _sessionHasPersistedChanges = false;

  @override
  void initState() {
    super.initState();
    _baseUnitController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _baseUnitController.dispose();
    _conversionUnitNameController.dispose();
    _conversionUnitRatioController.dispose();
    super.dispose();
  }

  List<TenantMeasurementUnitDto> _availableConversionUnitSuggestions(
    ProductMeasurementUnitsState state,
  ) {
    return excludeTenantMeasurementUnits(
      state.tenantUnits,
      state.conversionUnits.map((unit) => unit.name),
    );
  }

  List<String> _disabledConversionUnitNames(ProductMeasurementUnitsState state) {
    final baseUnitName = state.baseUnitName?.trim();
    if (baseUnitName == null || baseUnitName.isEmpty) {
      return const [];
    }
    return [baseUnitName];
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
          previous.unitMutationStatus != current.unitMutationStatus ||
          previous.deleteBlockedUnitId != current.deleteBlockedUnitId,
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
            _sessionHasPersistedChanges = true;
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
            _sessionHasPersistedChanges = true;
          });
        } else if (state.unitMutationStatus == ProductMeasurementUnitsStatus.failure) {
          final blockedUnitId = state.deleteBlockedUnitId;
          if (blockedUnitId != null) {
            final cubit = context.read<ProductMeasurementUnitsCubit>();
            ProductConversionUnitDeleteBlockedDialog.show(
              context,
              message:
                  state.errorMessage ??
                  'Không thể xóa đơn vị này vì đã có dữ liệu phụ thuộc. '
                      'Hãy dùng "Tắt đơn vị" để bảo toàn lịch sử.',
              onDeactivate: () {
                cubit.clearDeleteBlocked();
                cubit.deactivateConversionUnit(blockedUnitId);
              },
            );
            cubit.clearDeleteBlocked();
          } else {
            VToast.show(
              context,
              title: 'Lỗi',
              message: state.errorMessage ?? 'Có lỗi xảy ra',
              type: VToastType.danger,
            );
          }
        }
      },
      builder: (context, state) {
        final hasBaseUnit = state.baseUnitName != null && state.baseUnitName!.isNotEmpty;

        return VPageScaffold(
          title: 'Đơn vị đo lường',
          titleStyle: VTypography.headingH3.copyWith(
            color: dynamicColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          subtitle: widget.product.name,
          leading: IconButton(
            icon: VIcon(icon: VIcons.arrowBack, color: dynamicColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Base Unit Card
                  VCard(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          'ĐƠN VỊ CƠ SỞ',
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.textSecondary,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: VSpacing.space3),
                        if (!hasBaseUnit && !_isEditingBaseUnit) ...[
                          VText(
                            'Chưa thiết lập (không bắt buộc).',
                            variant: VTextVariant.bodyDefault,
                            color: dynamicColors.textPrimary,
                          ),
                          const SizedBox(height: VSpacing.space4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isEditingBaseUnit = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(VRadius.r8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: dynamicColors.primary.withValues(alpha: 0.5),
                                  style: BorderStyle
                                      .solid, // dotted in mockup but dashed/dotted usually needs custom painter or package, so we just use border
                                ),
                                borderRadius: BorderRadius.circular(VRadius.r8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  VIcon(icon: VIcons.add, color: dynamicColors.primary, size: 18),
                                  const VGap.horizontalSm(),
                                  VText(
                                    'Thiết lập đơn vị cơ sở',
                                    variant: VTextVariant.bodyDefault,
                                    color: dynamicColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (_isEditingBaseUnit) ...[
                          VText(
                            'Tên đơn vị cơ sở',
                            variant: VTextVariant.bodySmall,
                            color: dynamicColors.textSecondary,
                          ),
                          const SizedBox(height: VSpacing.space2),
                          TenantMeasurementUnitSearchField(
                            controller: _baseUnitController,
                            units: state.tenantUnits,
                            onChanged: (_) => setState(() {}),
                            hintText: 'hộp, chai, gói, lọ, kg...',
                            useVTextField: true,
                            fieldKey: const Key('input_base_unit_name'),
                          ),
                          const SizedBox(height: VSpacing.space2),
                          VText(
                            'Sẽ lưu ở dạng chữ thường: ${_baseUnitController.text.toLowerCase()}',
                            variant: VTextVariant.bodySmall,
                            color: dynamicColors.textSecondary,
                          ),
                          const SizedBox(height: VSpacing.space4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditingBaseUnit = false;
                                  });
                                },
                                child: VText(
                                  'Huỷ',
                                  variant: VTextVariant.bodyDefault,
                                  color: dynamicColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: VSpacing.space2),
                              VButton(
                                label: 'Lưu',
                                isLoading:
                                    state.saveStatus == ProductMeasurementUnitsStatus.loading,
                                onPressed: () => _onSaveBaseUnit(context, state),
                              ),
                            ],
                          ),
                        ] else ...[
                          VText(
                            state.baseUnitName!,
                            variant: VTextVariant.headingH4,
                            color: dynamicColors.textPrimary,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: VSpacing.space1),
                          VText(
                            'Đơn vị cơ sở không đổi được sau khi đã đặt.',
                            variant: VTextVariant.bodySmall,
                            color: dynamicColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.space4),

                  // Conversion Units Card
                  VCard(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          'ĐƠN VỊ QUY ĐỔI (${state.conversionUnits.length})',
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.textSecondary,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: VSpacing.space3),
                        if (!hasBaseUnit) ...[
                          VText(
                            'Cần đặt đơn vị cơ sở trước khi thêm đơn vị quy đổi.',
                            variant: VTextVariant.bodyDefault,
                            color: dynamicColors.textPrimary,
                          ),
                        ] else ...[
                          if (state.conversionUnits.isEmpty && !_isAddingConversionUnit)
                            VText(
                              'Chưa có đơn vị quy đổi.',
                              variant: VTextVariant.bodyDefault,
                              color: dynamicColors.textPrimary,
                            )
                          else if (state.conversionUnits.isNotEmpty)
                            ...state.conversionUnits.map((u) {
                              return ProductConversionUnitItem(
                                key: Key('conversion_unit_item_${u.id}'),
                                unit: u,
                                baseUnitName: state.baseUnitName!,
                              );
                            }),

                          const SizedBox(height: VSpacing.space4),

                          if (!_isAddingConversionUnit)
                            InkWell(
                              key: const Key('btn_add_conversion_unit'),
                              onTap: () {
                                setState(() {
                                  _isAddingConversionUnit = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(VRadius.r8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: dynamicColors.primary.withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(VRadius.r8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    VIcon(icon: VIcons.add, color: dynamicColors.primary, size: 18),
                                    const VGap.horizontalSm(),
                                    VText(
                                      'Thêm đơn vị quy đổi',
                                      variant: VTextVariant.bodyDefault,
                                      color: dynamicColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        'Tên đơn vị',
                                        variant: VTextVariant.bodySmall,
                                        color: dynamicColors.textSecondary,
                                      ),
                                      const SizedBox(height: VSpacing.space2),
                                      TenantMeasurementUnitSearchField(
                                        controller: _conversionUnitNameController,
                                        units: _availableConversionUnitSuggestions(state),
                                        disabledUnitNames: _disabledConversionUnitNames(state),
                                        onChanged: (_) => setState(() {}),
                                        hintText: 'hộp, thùng...',
                                        useVTextField: true,
                                        fieldKey: const Key('input_conversion_unit_name'),
                                        dropdownKey: const Key(
                                          'dropdown_conversion_unit_matches',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: VSpacing.space4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        'Tỉ lệ (x ${state.baseUnitName})',
                                        variant: VTextVariant.bodySmall,
                                        color: dynamicColors.textSecondary,
                                      ),
                                      const SizedBox(height: VSpacing.space2),
                                      VTextField(
                                        key: const Key('input_conversion_unit_rate'),
                                        controller: _conversionUnitRatioController,
                                        hintText: '10',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: VSpacing.space2),
                            VText(
                              'Sẽ lưu ở dạng chữ thường: ${_conversionUnitNameController.text.trim().isEmpty ? '—' : _conversionUnitNameController.text.trim().toLowerCase()}',
                              variant: VTextVariant.bodySmall,
                              color: dynamicColors.textSecondary,
                            ),
                            const SizedBox(height: VSpacing.space4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isAddingConversionUnit = false;
                                    });
                                  },
                                  child: VText(
                                    'Huỷ',
                                    variant: VTextVariant.bodyDefault,
                                    color: dynamicColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: VSpacing.space2),
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
                                    final baseUnitName = state.baseUnitName;
                                    if (baseUnitName != null &&
                                        isSameMeasurementUnitName(name, baseUnitName)) {
                                      VToast.show(
                                        context,
                                        title: 'Lỗi',
                                        message: 'Không thể dùng đơn vị cơ sở làm đơn vị quy đổi',
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
          bottomBar: ProductMeasurementUnitsBottomBar(
            saveEnabled:
                _sessionHasPersistedChanges ||
                (_isEditingBaseUnit &&
                    _baseUnitController.text.trim().toLowerCase() !=
                        (state.baseUnitName ?? '').trim().toLowerCase()),
          ),
        );
      },
    );
  }
}
