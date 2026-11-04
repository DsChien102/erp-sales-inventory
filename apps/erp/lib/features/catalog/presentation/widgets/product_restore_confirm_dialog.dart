import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductRestoreConfirmDialog extends StatelessWidget {
  const ProductRestoreConfirmDialog({
    super.key,
    required this.productId,
    required this.productName,
    required this.readinessSummary,
    this.onRestored,
  });

  final String productId;
  final String productName;
  final ReadinessSummaryDto readinessSummary;
  final VoidCallback? onRestored;

  static Future<void> show(
    BuildContext context, {
    required ProductSoftDeleteCubit cubit,
    required String productId,
    required String productName,
    required ReadinessSummaryDto readinessSummary,
    VoidCallback? onRestored,
  }) async {
    await showVAdaptiveSheet(
      context: context,
      title: 'Khôi phục sản phẩm này?',
      child: BlocProvider.value(
        value: cubit,
        child: ProductRestoreConfirmDialog(
          productId: productId,
          productName: productName,
          readinessSummary: readinessSummary,
          onRestored: onRestored,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductSoftDeleteCubit, ProductSoftDeleteState>(
      listener: (context, state) {
        if (state.status == ProductSoftDeleteStatus.restored) {
          VToast.show(
            context,
            title: 'Khôi phục sản phẩm',
            message: 'Sản phẩm đã được khôi phục.',
            type: VToastType.success,
          );
          Navigator.of(context).pop();
          onRestored?.call();
        } else if (state.status == ProductSoftDeleteStatus.error) {
          VToast.show(
            context,
            title: 'Không thể khôi phục',
            message: state.errorMessage ?? 'Không thể khôi phục sản phẩm.',
            type: VToastType.danger,
          );
        }
      },
      builder: (context, state) {
        if (state.status == ProductSoftDeleteStatus.restoring) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(VSpacing.space5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: VSpacing.space4),
                  VText('Đang khôi phục...'),
                ],
              ),
            ),
          );
        }

        return _RestoreContent(
          productId: productId,
          productName: productName,
          readinessSummary: readinessSummary,
          errorMessage: state.status == ProductSoftDeleteStatus.error ? state.errorMessage : null,
        );
      },
    );
  }
}

class _RestoreContent extends StatelessWidget {
  const _RestoreContent({
    required this.productId,
    required this.productName,
    required this.readinessSummary,
    this.errorMessage,
  });

  final String productId;
  final String productName;
  final ReadinessSummaryDto readinessSummary;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final blockers = readinessSummary.blockers;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Sản phẩm "$productName" sẽ được khôi phục ở trạng thái ngừng kinh doanh. Kiểm tra readiness trước khi kinh doanh lại.',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.textSecondary,
            ),
            if (blockers.isNotEmpty) ...[
              const SizedBox(height: VSpacing.space4),
              Container(
                padding: const EdgeInsets.all(VSpacing.space3),
                decoration: BoxDecoration(
                  color: dynamicColors.warningBg,
                  border: Border.all(
                    color: dynamicColors.warning.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(VRadius.r8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      'Readiness hiện tại',
                      variant: VTextVariant.bodySmall,
                      color: dynamicColors.warning,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    ...blockers.map(
                      (blocker) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: VText(
                          blocker.message,
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: VSpacing.space4),
              VText(
                errorMessage!,
                variant: VTextVariant.bodySmall,
                color: dynamicColors.danger,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                    label: 'Khôi phục',
                    onPressed: () {
                      context.read<ProductSoftDeleteCubit>().restoreProduct(
                        productId: productId,
                      );
                    },
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
