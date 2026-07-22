import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../widgets/dashed_border_container.dart';
import '../widgets/product_form_bottom_bar.dart';

class ProductManualBasePriceRouteArgs {
  final ProductListItemModel product;
  final ProductBasePriceCardDto basePriceCard;
  const ProductManualBasePriceRouteArgs({
    required this.product,
    required this.basePriceCard,
  });
}

class ProductManualBasePricePage extends StatelessWidget {
  const ProductManualBasePricePage({
    super.key,
    required this.product,
    required this.basePriceCard,
  });

  final ProductListItemModel product;
  final ProductBasePriceCardDto basePriceCard;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductManualBasePriceCubit(
        catalogModule: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
      ),
      child: _ProductManualBasePriceView(
        product: product,
        basePriceCard: basePriceCard,
      ),
    );
  }
}

class _ProductManualBasePriceView extends StatefulWidget {
  const _ProductManualBasePriceView({
    required this.product,
    required this.basePriceCard,
  });

  final ProductListItemModel product;
  final ProductBasePriceCardDto basePriceCard;

  @override
  State<_ProductManualBasePriceView> createState() => _ProductManualBasePriceViewState();
}

class _ProductManualBasePriceViewState extends State<_ProductManualBasePriceView> {
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late final int? _initialAmount;

  @override
  void initState() {
    super.initState();
    final amount = widget.basePriceCard.amount;
    _initialAmount = amount?.round();
    _priceController = TextEditingController(
      text: amount == null ? '' : VMoneyValidator.format(amount.round()),
    );
    _noteController = TextEditingController();
    _priceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasPriceChanges {
    final parsed = VMoneyValidator.parse(_priceController.text);
    return parsed != _initialAmount;
  }

  void _onSave(BuildContext context) {
    final priceStr = _priceController.text.trim();
    if (priceStr.isEmpty) {
      VToast.show(
        context,
        title: 'Lỗi',
        message: 'Vui lòng nhập giá vốn mới',
        type: VToastType.danger,
      );
      return;
    }

    final price = VMoneyValidator.parse(priceStr);
    if (price == null || price < 0) {
      VToast.show(
        context,
        title: 'Lỗi',
        message: 'Giá vốn không hợp lệ',
        type: VToastType.danger,
      );
      return;
    }

    context.read<ProductManualBasePriceCubit>().submitManualBasePrice(
      productId: widget.product.id,
      basePrice: price.toDouble(),
      currency: widget.basePriceCard.currency,
    );
  }

  String? _resolveBaseUnitName() {
    final fromCard = widget.basePriceCard.baseUnitName?.trim();
    if (fromCard != null && fromCard.isNotEmpty) {
      return fromCard;
    }
    final fromProduct = widget.product.baseUnit?.trim();
    if (fromProduct != null && fromProduct.isNotEmpty) {
      return fromProduct;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedBaseUnit = _resolveBaseUnitName();
    final hasBaseUnit = resolvedBaseUnit != null;
    final baseUnitName = resolvedBaseUnit ?? 'đơn vị cơ sở';

    return BlocConsumer<ProductManualBasePriceCubit, ProductManualBasePriceState>(
      listener: (context, state) {
        if (state.status == ProductManualBasePriceStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã lưu giá vốn cơ sở',
            type: VToastType.success,
          );
          context.pop();
        } else if (state.status == ProductManualBasePriceStatus.failure) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage ?? 'Có lỗi xảy ra',
            type: VToastType.danger,
          );
        }
      },
      builder: (context, state) {
        return VPageScaffold(
          key: const Key('wgt_e06_u01_fr01_01'),
          title: 'Giá vốn cơ sở',
          titleStyle: VTypography.headingH3.copyWith(
            color: dynamicColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          subtitle: widget.product.name,
          leading: IconButton(
            icon: VIcon(icon: VIcons.arrowBack, color: dynamicColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: hasBaseUnit
                        ? VCard(
                            padding: const EdgeInsets.all(VSpacing.space4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Current base price read-only display
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: dynamicColors.textSecondary.withValues(alpha: 0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(VRadius.r8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      VText(
                                        'Giá vốn hiện tại',
                                        variant: VTextVariant.bodyDefault,
                                        color: dynamicColors.textSecondary,
                                      ),
                                      VText(
                                        widget.basePriceCard.isMissing
                                            ? '—'
                                            : formatCatalogCurrency(widget.basePriceCard.amount),
                                        variant: VTextVariant.bodyDefault,
                                        color: dynamicColors.textPrimary,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: VSpacing.space4),

                                VText(
                                  'Giá vốn mới (${widget.basePriceCard.currency == 'VND' ? 'đ' : widget.basePriceCard.currency} / 1 $baseUnitName)',
                                  variant: VTextVariant.bodySmall,
                                  color: dynamicColors.textSecondary,
                                ),
                                const SizedBox(height: VSpacing.space2),
                                VMoneyField(
                                  key: const Key('input_base_price_amount'),
                                  controller: _priceController,
                                  hintText: 'Ví dụ: 45,000',
                                  textAlign: TextAlign.left,
                                  suffixText:
                                      '${widget.basePriceCard.currency == 'VND' ? 'đ' : widget.basePriceCard.currency} / $baseUnitName',
                                ),
                                const SizedBox(height: VSpacing.space2),
                                VText(
                                  'Giá vốn cơ sở luôn gắn với đơn vị cơ sở của sản phẩm ($baseUnitName).',
                                  variant: VTextVariant.bodySmall,
                                  color: dynamicColors.textSecondary,
                                ),

                                const SizedBox(height: VSpacing.space4),
                                VText(
                                  'Ghi chú',
                                  variant: VTextVariant.bodySmall,
                                  color: dynamicColors.textSecondary,
                                ),
                                const SizedBox(height: VSpacing.space2),
                                VTextField(
                                  controller: _noteController,
                                  hintText: 'Nhập ghi chú...',
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          )
                        : DashedBorderContainer(
                            padding: const EdgeInsets.all(VSpacing.space4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: VTypography.bodyDefault.copyWith(
                                      color: dynamicColors.textPrimary,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Cần thiết lập '),
                                      TextSpan(
                                        text: 'đơn vị cơ sở',
                                        style: VTypography.bodyDefault.copyWith(
                                          color: dynamicColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' cho sản phẩm trước khi nhập giá vốn cơ sở.',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: VSpacing.space2),
                                VText(
                                  'Giá vốn cơ sở luôn gắn với đơn vị cơ sở của sản phẩm.',
                                  variant: VTextVariant.bodySmall,
                                  color: dynamicColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              ProductFormBottomBar(
                onCancel: () => context.pop(),
                saveKey: const Key('btn_manual_base_price_save'),
                isLoading: state.status == ProductManualBasePriceStatus.loading,
                saveEnabled: hasBaseUnit && _hasPriceChanges,
                onSave: () => _onSave(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
