import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../widgets/product_control_center_formatters.dart';

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

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.basePriceCard.amount?.toStringAsFixed(0) ?? '',
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
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

    final price = double.tryParse(priceStr);
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
          basePrice: price,
          currency: widget.basePriceCard.currency,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final baseUnitName = widget.product.baseUnit ?? 'đơn vị cơ sở';

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
        return Scaffold(
          backgroundColor: dynamicColors.background,
          appBar: VAppBar(
            title: 'Giá vốn cơ sở',
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
              child: VCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current base price read-only display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: dynamicColors.textSecondary.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giá vốn hiện tại',
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textSecondary,
                            ),
                          ),
                          Text(
                            widget.basePriceCard.isMissing
                                ? '—'
                                : formatCatalogCurrency(widget.basePriceCard.amount),
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Giá vốn mới (${widget.basePriceCard.currency == 'VND' ? 'đ' : widget.basePriceCard.currency} / 1 $baseUnitName)',
                      style: VTypography.bodySmall.copyWith(
                        color: dynamicColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    VTextField(
                      controller: _priceController,
                      hintText: 'Ví dụ: 45000',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giá vốn cơ sở luôn gắn với đơn vị cơ sở của sản phẩm ($baseUnitName).',
                      style: VTypography.bodySmall.copyWith(
                        color: dynamicColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Text(
                      'Ghi chú',
                      style: VTypography.bodySmall.copyWith(
                        color: dynamicColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    VTextField(
                      controller: _noteController,
                      hintText: 'Nhập ghi chú...',
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'Huỷ',
                              style: VTypography.bodyDefault.copyWith(
                                color: dynamicColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: VButton(
                            label: 'Lưu thay đổi',
                            isLoading: state.status == ProductManualBasePriceStatus.loading,
                            onPressed: () => _onSave(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
