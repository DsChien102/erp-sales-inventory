import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../data/current_receipt_actor.dart';
import '../../data/goods_receipt_repository.dart';
import '../../data/models/receipt_actor.dart';
import '../../logic/receipt_approval_cubit.dart';
import '../../logic/receipt_approval_state.dart';
import '../widgets/inventory_state_views.dart';
import '../widgets/receipt_key_value_row.dart';
import '../widgets/receipt_line_summary.dart';
import '../widgets/receipt_reject_reason_sheet.dart';

class GoodsReceiptApprovalPage extends StatelessWidget {
  const GoodsReceiptApprovalPage({
    super.key,
    required this.receiptId,
    this.repository,
    this.actorLoader,
  });

  final String receiptId;
  final GoodsReceiptRepository? repository;
  final ReceiptActorLoader? actorLoader;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReceiptApprovalCubit(
        repository: repository ?? getIt<GoodsReceiptRepository>(),
        actorLoader: actorLoader ?? currentReceiptActor,
      )..load(receiptId),
      child: _GoodsReceiptApprovalView(receiptId: receiptId),
    );
  }
}

class _GoodsReceiptApprovalView extends StatelessWidget {
  const _GoodsReceiptApprovalView({required this.receiptId});

  final String receiptId;

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${_formatDate(dt)} · ${two(dt.hour)}:${two(dt.minute)}';
  }

  void _showDocuments(BuildContext context, List<String> names) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VBottomSheet(
        title: 'Chứng từ giao nhận',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            0,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (names.isEmpty)
                const VText('Chưa có tệp đính kèm.')
              else
                for (final name in names)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: VSpacing.space2,
                    ),
                    child: Row(
                      children: [
                        const VIcon(
                          icon: VIcons.file,
                          iconSize: VIconSize.md,
                          iconColor: VIconColor.primary,
                        ),
                        const VGap(VSpacing.space2, axis: Axis.horizontal),
                        Expanded(child: VText(name)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReject(BuildContext context) async {
    final reason = await ReceiptRejectReasonSheet.show(context);
    if (reason != null && context.mounted) {
      context.read<ReceiptApprovalCubit>().reject(reason: reason);
    }
  }

  void _handleApprove(BuildContext context) {
    context.read<ReceiptApprovalCubit>().approve();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<ReceiptApprovalCubit, ReceiptApprovalState>(
      listener: (context, state) {
        if (state is ReceiptApprovalSuccess) {
          context.go('/warehouse/receipts/result/${state.document.id}');
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.surfaceAlt,
          appBar: VAppBar(
            title: 'Phê duyệt yêu cầu nhận hàng',
            subtitle: switch (state) {
              ReceiptApprovalLoaded(:final document) =>
                'Việc dành cho người phê duyệt · ${document.submittedByName} gửi',
              _ => 'Việc dành cho người phê duyệt',
            },
            showBackButton: true,
          ),
          body: switch (state) {
            ReceiptApprovalInitial() || ReceiptApprovalLoading() =>
              const Center(child: VLoading()),
            ReceiptApprovalError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VText(
                        message,
                        style: VTypography.bodyDefault.copyWith(
                          color: colors.danger,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const VGap(VSpacing.space4),
                      VButton(
                        label: 'Thử lại',
                        onPressed: () =>
                            context.read<ReceiptApprovalCubit>().load(receiptId),
                      ),
                    ],
                  ),
                ),
              ),
            ReceiptApprovalPermissionDenied() =>
              const InventoryPermissionDenied(),
            ReceiptApprovalNotFound() => const Center(
                child: Padding(
                  padding: EdgeInsets.all(VSpacing.space6),
                  child: VEmptyState(
                    child: VEmptyHeader(
                      children: [
                        VEmptyMedia(icon: VIcons.inventory),
                        VEmptyTitle('Không có yêu cầu để duyệt'),
                        VEmptyDescription(
                          'Yêu cầu chỉ xuất hiện sau khi người lập gửi hồ sơ hợp lệ.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ReceiptApprovalLoaded() => _buildContent(context, state),
            ReceiptApprovalSuccess(:final document) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: VText('Đã xử lý: ${document.id}'),
                ),
              ),
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ReceiptApprovalLoaded loadedState,
  ) {
    final colors = context.vColors;
    final doc = loadedState.document;
    final isProcessing = loadedState.isProcessing;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: VSpacing.space4,
            right: VSpacing.space4,
            top: VSpacing.space4,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loadedState.isSelfApproval) ...[
                const VBanner(
                  status: VBannerStatus.warning,
                  title: 'Bạn không thể tự duyệt',
                  description:
                      'Bạn đã gửi yêu cầu này. Cần một người khác có quyền phê duyệt.',
                ),
                const VGap(VSpacing.space3),
              ] else if (loadedState.isDecided) ...[
                VBanner(
                  status: VBannerStatus.info,
                  title: 'Yêu cầu đã được xử lý',
                  description: doc.rejectReason != null
                      ? 'Đã từ chối: ${doc.rejectReason}'
                      : null,
                ),
                const VGap(VSpacing.space3),
              ] else ...[
                const VBanner(
                  status: VBannerStatus.info,
                  title: 'Lý do cần duyệt',
                  description: 'Nhập hàng nhanh bắt buộc phê duyệt.',
                ),
                const VGap(VSpacing.space3),
              ],
              VSection(
                title: 'Thông tin lần nhận',
                child: VCard(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ReceiptKeyValueRow(
                          label: 'Nhà cung cấp',
                          value: doc.header.supplierName.isNotEmpty
                              ? doc.header.supplierName
                              : '--',
                        ),
                        ReceiptKeyValueRow(
                          label: 'Kho nhận',
                          value: doc.header.warehouseName,
                        ),
                        ReceiptKeyValueRow(
                          label: 'Ngày nhận',
                          value: _formatDate(doc.header.receiptDate),
                        ),
                        const VGap(VSpacing.space3),
                        VButton(
                          label: 'Xem chứng từ giao nhận',
                          variant: VButtonVariant.secondary,
                          onPressed: () => _showDocuments(
                            context,
                            doc.header.documentFileNames,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const VGap(VSpacing.space4),
              VSection(
                title: 'Thông tin yêu cầu',
                child: VCard(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Column(
                      children: [
                        ReceiptKeyValueRow(
                          label: 'Người gửi',
                          value: doc.submittedByName,
                        ),
                        ReceiptKeyValueRow(
                          label: 'Gửi lúc',
                          value: _formatDateTime(doc.submittedAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const VGap(VSpacing.space4),
              VSection(
                title: 'Hàng thực nhận',
                trailing: VText(
                  '${doc.items.length} mặt hàng',
                  style: VTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                child: VCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.space4,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < doc.items.length; i++) ...[
                          if (i > 0) const VDivider(),
                          ReceiptLineSummary(item: doc.items[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (loadedState.canDecide)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(VSpacing.space4),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: colors.borderDefault),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loadedState.actionError != null) ...[
                      VBanner(
                        status: VBannerStatus.error,
                        title: 'Lỗi xử lý',
                        description: loadedState.actionError!,
                      ),
                      const VGap(VSpacing.space2),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: VButton(
                            label: 'Từ chối',
                            tone: VComponentTone.danger,
                            variant: VButtonVariant.secondary,
                            enabled: !isProcessing,
                            onPressed: () => _handleReject(context),
                          ),
                        ),
                        const VGap(VSpacing.space3, axis: Axis.horizontal),
                        Expanded(
                          child: VButton(
                            label: 'Duyệt',
                            tone: VComponentTone.success,
                            isLoading: isProcessing,
                            enabled: !isProcessing,
                            onPressed: () => _handleApprove(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
