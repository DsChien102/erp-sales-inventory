import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/catalog/presentation.dart';

class ProductDeleteConfirmDialog extends StatelessWidget {
  const ProductDeleteConfirmDialog({
    super.key,
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  static Future<void> show(
    BuildContext context, {
    required ProductSoftDeleteCubit cubit,
    required String productId,
    required String productName,
  }) async {
    cubit.checkEligibility(productId);
    await showVBottomSheet(
      context: context,
      title: 'Xoá sản phẩm này?',
      child: BlocProvider.value(
        value: cubit,
        child: ProductDeleteConfirmDialog(
          productId: productId,
          productName: productName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductSoftDeleteCubit, ProductSoftDeleteState>(
      listener: (context, state) {
        if (state.status == ProductSoftDeleteStatus.success) {
          VToast.show(
            context,
            title: 'Xóa sản phẩm',
            message: 'Sản phẩm đã được xóa thành công.',
            type: VToastType.success,
          );
          Navigator.of(context).pop(); // Đóng bottom sheet
          if (context.canPop()) {
            context.pop(true); // Đóng trang chi tiết và trả về true để trigger reload
          } else {
            context.go('/products/items');
          }
        } else if (state.status == ProductSoftDeleteStatus.error) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage ?? 'Có lỗi xảy ra.',
            type: VToastType.danger,
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case ProductSoftDeleteStatus.checkingEligibility:
            return _buildLoading();
          case ProductSoftDeleteStatus.eligibilityChecked:
            if (state.eligibility != null) {
              return _buildConfirm(context, state.eligibility!);
            }
            return const SizedBox.shrink();
          case ProductSoftDeleteStatus.deleting:
            return _buildLoading(label: 'Đang xóa...');
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildLoading({String label = 'Đang kiểm tra điều kiện...'}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: VSpacing.space4),
            VText(label),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context, ProductDeletionEligibilityDto eligibility) {
    final dynamicColors = context.vColors;

    if (!eligibility.canDelete) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                'Sản phẩm "$productName" không thể xóa vì:',
                variant: VTextVariant.bodyDefault,
                color: dynamicColors.textSecondary,
              ),
              const SizedBox(height: VSpacing.space3),
              ...eligibility.issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VIcon(icon: VIcons.error, size: 16, color: dynamicColors.danger),
                      const VGap.horizontalSm(),
                      Expanded(
                        child: VText(
                          issue.message,
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.space6),
              VButton(
                label: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                variant: VButtonVariant.secondary,
              ),
            ],
          ),
        ),
      );
    }

    final hasWarnings = eligibility.issues.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Sản phẩm sẽ được đánh dấu đã xoá và không xuất hiện trong danh sách. Đơn hàng cũ vẫn giữ nguyên dữ liệu tại thời điểm giao dịch.',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.textSecondary,
            ),
            if (hasWarnings) ...[
              const SizedBox(height: VSpacing.space4),
              Container(
                padding: const EdgeInsets.all(VSpacing.space3),
                decoration: BoxDecoration(
                  color: dynamicColors.warningBg,
                  border: Border.all(color: dynamicColors.warning.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(VRadius.r8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VIcon(icon: VIcons.warning, color: dynamicColors.warning, size: 20),
                        const VGap.horizontalSm(),
                        VText(
                          'Lưu ý',
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.warning,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: VSpacing.space2),
                    ...eligibility.issues.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText('• ', style: TextStyle(color: dynamicColors.warning)),
                            Expanded(
                              child: VText(
                                issue.message,
                                variant: VTextVariant.bodySmall,
                                color: dynamicColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Huỷ',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: VButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    label: 'Xoá sản phẩm',
                    onPressed: () {
                      context.read<ProductSoftDeleteCubit>().deleteProduct(
                        productId: productId,
                        confirmAcknowledgeWarnings: hasWarnings,
                      );
                    },
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
