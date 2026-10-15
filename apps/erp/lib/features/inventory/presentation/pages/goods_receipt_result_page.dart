import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../data/goods_receipt_repository.dart';
import '../../data/models/receipt_document_model.dart';
import '../../logic/receipt_result_cubit.dart';
import '../widgets/inventory_state_views.dart';
import '../widgets/receipt_line_summary.dart';

class GoodsReceiptResultPage extends StatelessWidget {
  const GoodsReceiptResultPage({
    super.key,
    required this.receiptId,
    this.repository,
    this.pollInterval = const Duration(seconds: 2),
  });

  final String receiptId;
  final GoodsReceiptRepository? repository;
  final Duration pollInterval;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptResultCubit(
        repository: repository ?? getIt<GoodsReceiptRepository>(),
        pollInterval: pollInterval,
      )..load(receiptId),
      child: _GoodsReceiptResultView(receiptId: receiptId),
    );
  }
}

class _GoodsReceiptResultView extends StatelessWidget {
  const _GoodsReceiptResultView({required this.receiptId});

  final String receiptId;

  Widget _emptyScaffold(
    BuildContext context, {
    required Widget body,
    String? footerLabel,
    VoidCallback? onFooter,
    bool showBack = true,
  }) {
    return Scaffold(
      backgroundColor: context.vColors.surfaceAlt,
      appBar: VAppBar(title: 'Kết quả nhận hàng', showBackButton: showBack),
      body: body,
      bottomNavigationBar: footerLabel == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: VButton(
                  label: footerLabel,
                  fullWidth: true,
                  size: VButtonSize.large,
                  onPressed: onFooter,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptResultCubit, ReceiptResultState>(
      builder: (context, state) => switch (state) {
        ReceiptResultLoading() => Scaffold(
          backgroundColor: context.vColors.surfaceAlt,
          body: const Center(child: VLoading()),
        ),
        ReceiptResultPermissionDenied() => _emptyScaffold(
          context,
          body: const InventoryPermissionDenied(),
          footerLabel: 'Về Kho',
          onFooter: () => context.go('/inventory'),
        ),
        ReceiptResultNotFound() => _notFound(context),
        ReceiptResultLoaded(:final document) => _loaded(context, document),
      },
    );
  }

  Widget _notFound(BuildContext context) {
    return _emptyScaffold(
      context,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space6),
          child: VEmptyState(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VEmptyHeader(
                  children: [
                    VEmptyMedia(iconData: Icons.search_off),
                    VEmptyTitle('Không tìm thấy lần nhận hàng'),
                    VEmptyDescription(
                      'Lần nhận hàng không tồn tại hoặc đã bị xoá.',
                    ),
                  ],
                ),
                const VGap(VSpacing.space4),
                VEmptyContent(
                  child: VButton(
                    label: 'Về Kho',
                    onPressed: () => context.go('/inventory'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loaded(BuildContext context, ReceiptDocumentModel doc) {
    final colors = context.vColors;

    // Kết quả chưa xác định: không Back, không gửi lại; chỉ đối soát cùng lần nhận.
    if (doc.status == ReceiptStatus.executionUnknown) {
      return PopScope(
        canPop: false,
        child: _emptyScaffold(
          context,
          showBack: false,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                VEmptyState(
                  child: VEmptyHeader(
                    children: [
                      VEmptyMedia(icon: VIcons.clock),
                      VEmptyTitle('Đang xác minh kết quả'),
                      VEmptyDescription(
                        'Không thực hiện lại thao tác nhận hàng.',
                      ),
                    ],
                  ),
                ),
                VGap(VSpacing.space4),
                VBanner(
                  status: VBannerStatus.warning,
                  title: 'Giữ nguyên lần nhận hiện tại',
                  description: 'Hệ thống tiếp tục đối soát kết quả của lần nhận này.',
                ),
              ],
            ),
          ),
          footerLabel: 'Xác minh kết quả',
          onFooter: () async {
            await context.push('/warehouse/receipts/reconciliation/${doc.id}');
            if (context.mounted) {
              context.read<ReceiptResultCubit>().load(receiptId);
            }
          },
        ),
      );
    }

    if (doc.status == ReceiptStatus.processing) {
      return _emptyScaffold(
        context,
        showBack: false,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(VSpacing.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VEmptyState(
                  child: VEmptyHeader(
                    children: [
                      VEmptyMedia(icon: VIcons.inventory),
                      VEmptyTitle('Đang ghi nhận hàng'),
                      VEmptyDescription(
                        'Hệ thống đang xử lý. Bạn không cần thực hiện lại.',
                      ),
                    ],
                  ),
                ),
                VGap(VSpacing.space4),
                VLoading(),
              ],
            ),
          ),
        ),
      );
    }

    if (doc.status == ReceiptStatus.executionRejected) {
      return _emptyScaffold(
        context,
        showBack: false,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(VSpacing.space6),
            child: VEmptyState(
              child: VEmptyHeader(
                children: [
                  VEmptyMedia(icon: VIcons.close),
                  VEmptyTitle('Chưa ghi nhận hàng'),
                  VEmptyDescription(
                    'Yêu cầu bị chặn trước khi tồn kho thay đổi.',
                  ),
                ],
              ),
            ),
          ),
        ),
        footerLabel: 'Xong',
        onFooter: () => context.go('/inventory'),
      );
    }

    final (icon, title, description) = switch (doc.status) {
      ReceiptStatus.completed => (
        VIcons.success,
        'Đã ghi nhận hàng',
        'Đã tăng tồn vật lý theo ${doc.items.length} dòng hàng được xử lý.',
      ),
      ReceiptStatus.rejected => (
        VIcons.close,
        'Đã từ chối yêu cầu',
        'Lý do: ${doc.rejectReason ?? "Không rõ"}. Tồn kho không thay đổi.',
      ),
      _ => (
        VIcons.inventory,
        'Yêu cầu đang chờ phê duyệt',
        'Tồn kho chưa thay đổi.',
      ),
    };
    final isApproved = doc.status == ReceiptStatus.completed;

    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      appBar: const VAppBar(
        title: 'Kết quả nhận hàng',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VEmptyState(
              child: VEmptyHeader(
                children: [
                  VEmptyMedia(icon: icon),
                  VEmptyTitle(title),
                  VEmptyDescription(description),
                ],
              ),
            ),
            if (isApproved) ...[
              const VGap(VSpacing.space4),
              VSection(
                title: 'Kết quả theo dòng hàng',
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
              const VGap(VSpacing.space4),
              VBanner(
                status: VBannerStatus.info,
                title: 'Đang chờ xác nhận giá',
                description: 'Phần Đạt chờ xác nhận giá; Cách ly/Hỏng giữ nguyên trạng thái.',
                footer: VButton(
                  label: 'Xác lập giá trị',
                  variant: VButtonVariant.secondary,
                  size: VButtonSize.small,
                  onPressed: () {
                    context.push('/warehouse/valuation/receipt/${doc.id}');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: VButton(
            label: 'Xong',
            fullWidth: true,
            size: VButtonSize.large,
            onPressed: () => context.go('/inventory'),
          ),
        ),
      ),
    );
  }
}
