import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../logic/quick_receipt_session_cubit.dart';
import '../../logic/quick_receipt_session_state.dart';
import '../../logic/receipt_rules.dart';
import '../widgets/receipt_key_value_row.dart';
import '../widgets/receipt_line_summary.dart';
import 'receipt_item_detail_args.dart';

class GoodsReceiptReviewPage extends StatelessWidget {
  const GoodsReceiptReviewPage({super.key});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _banner(QuickReceiptSessionState state, bool isSubmitted) {
    if (isSubmitted) {
      return const VBanner(
        status: VBannerStatus.info,
        title: 'Đã gửi phê duyệt',
        description: 'Đang chờ người duyệt; tồn kho chưa thay đổi.',
      );
    }
    final allValid = state.items.isNotEmpty &&
        state.items.every((i) => validateReceiptItem(i).isValid);
    final noStock = allValid && !state.items.any((i) => i.totalPhysicalStock > 0);
    if (noStock) {
      return const VBanner(
        status: VBannerStatus.warning,
        title: 'Chưa có hàng vào tồn',
        description:
            'Nhập hàng nhanh chỉ gửi được khi Đạt + Cách ly + Hỏng lớn hơn 0.',
      );
    }
    return const VBanner(
      status: VBannerStatus.info,
      title: 'Cần phê duyệt trước khi ghi nhận',
      description:
          'Nhập hàng nhanh luôn cần người duyệt độc lập. Tồn kho chưa thay đổi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<QuickReceiptSessionCubit, QuickReceiptSessionState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Chưa gửi được',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        }
      },
      builder: (context, state) {
        final header = state.header;
        final items = state.items;
        final isSubmitted = state.submittedDocument != null;

        return PopScope(
          canPop: !isSubmitted,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              context.go('/inventory');
            }
          },
          child: Scaffold(
            backgroundColor: colors.surfaceAlt,
            appBar: VAppBar(
              title: 'Rà soát nhận hàng',
              showBackButton: !isSubmitted,
              leading: isSubmitted
                  ? VButton.icon(
                      icon: VIcons.chevronLeft,
                      semanticLabel: 'Về Kho',
                      variant: VButtonVariant.tertiary,
                      onPressed: () => context.go('/inventory'),
                    )
                  : null,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _banner(state, isSubmitted),
                  const VGap(VSpacing.space4),
                  VSection(
                    title: 'Thông tin lần nhận',
                    trailing: isSubmitted
                        ? null
                        : VButton(
                            label: 'Sửa',
                            variant: VButtonVariant.link,
                            onPressed: () => context
                                .go('/warehouse/receipts/quick/header'),
                          ),
                    child: VCard(
                      child: Padding(
                        padding: const EdgeInsets.all(VSpacing.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReceiptKeyValueRow(
                              label: 'Nhà cung cấp',
                              value: header.supplierName.isNotEmpty
                                  ? header.supplierName
                                  : '--',
                            ),
                            ReceiptKeyValueRow(
                              label: 'Kho nhận',
                              value: header.warehouseName,
                            ),
                            ReceiptKeyValueRow(
                              label: 'Ngày nhận',
                              value: _formatDate(header.receiptDate),
                            ),
                            ReceiptKeyValueRow(
                              label: 'Chứng từ giao nhận',
                              value: '${header.documentFileNames.length} tệp',
                            ),
                            for (final name in header.documentFileNames)
                              Align(
                                alignment: Alignment.centerRight,
                                child: VText(
                                  name,
                                  style: VTypography.caption.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const VGap(VSpacing.space4),
                  VSection(
                    title: 'Hàng thực nhận',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VText(
                          '${items.length} mặt hàng',
                          style: VTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        if (!isSubmitted) ...[
                          const VGap(VSpacing.space2, axis: Axis.horizontal),
                          VButton(
                            label: 'Sửa',
                            variant: VButtonVariant.link,
                            onPressed: () => context
                                .go('/warehouse/receipts/quick/items'),
                          ),
                        ],
                      ],
                    ),
                    child: VCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.space4,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) const VDivider(),
                              ReceiptLineSummary(
                                item: items[i],
                                onTap: () => context.push(
                                  '/warehouse/receipts/quick/item-detail',
                                  extra: ReceiptItemDetailArgs(
                                    item: items[i],
                                    readOnly: isSubmitted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: isSubmitted
                    ? VButton(
                        label: 'Về Kho',
                        fullWidth: true,
                        size: VButtonSize.large,
                        onPressed: () => context.go('/inventory'),
                      )
                    : VButton(
                        label: 'Gửi phê duyệt',
                        fullWidth: true,
                        size: VButtonSize.large,
                        isLoading: state.isSubmitting,
                        enabled: !state.isSubmitting && state.canReview,
                        onPressed: () {
                          context
                              .read<QuickReceiptSessionCubit>()
                              .submitForApproval();
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
