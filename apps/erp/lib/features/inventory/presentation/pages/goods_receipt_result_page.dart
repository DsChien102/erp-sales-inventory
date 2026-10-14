import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../data/goods_receipt_repository.dart';
import '../../data/models/receipt_document_model.dart';
import '../widgets/receipt_line_summary.dart';

class GoodsReceiptResultPage extends StatefulWidget {
  const GoodsReceiptResultPage({
    super.key,
    required this.receiptId,
    this.repository,
  });

  final String receiptId;
  final GoodsReceiptRepository? repository;

  @override
  State<GoodsReceiptResultPage> createState() => _GoodsReceiptResultPageState();
}

class _GoodsReceiptResultPageState extends State<GoodsReceiptResultPage> {
  late final GoodsReceiptRepository _repo =
      widget.repository ?? getIt<GoodsReceiptRepository>();
  ReceiptDocumentModel? _document;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final doc = await _repo.getReceiptById(widget.receiptId);
      if (mounted) {
        setState(() {
          _document = doc;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surfaceAlt,
        body: const Center(child: VLoading()),
      );
    }

    final doc = _document;
    if (doc == null) {
      return Scaffold(
        backgroundColor: colors.surfaceAlt,
        appBar: const VAppBar(
          title: 'Kết quả nhận hàng',
          showBackButton: true,
        ),
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
                      VEmptyDescription('Mã phiếu không tồn tại hoặc đã bị xóa.'),
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
      ReceiptStatus.pendingApproval => (
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
                description:
                    'Phần Đạt chờ xác nhận giá; Cách ly/Hỏng giữ nguyên trạng thái.',
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
