import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/receipt_header_draft.dart';
import '../../logic/quick_receipt_session_cubit.dart';
import '../../logic/quick_receipt_session_state.dart';
import '../widgets/inventory_state_views.dart';
import '../widgets/receipt_supplier_select_sheet.dart';

class QuickReceiptHeaderPage extends StatefulWidget {
  const QuickReceiptHeaderPage({super.key});

  @override
  State<QuickReceiptHeaderPage> createState() => _QuickReceiptHeaderPageState();
}

class _QuickReceiptHeaderPageState extends State<QuickReceiptHeaderPage> {
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _triedContinue = false;

  @override
  void dispose() {
    _warehouseController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _selectSupplier(QuickReceiptSessionState state) async {
    final currentId = state.header.supplierId;
    final selected = await ReceiptSupplierSelectSheet.show(
      context,
      suppliers: state.suppliers,
      selectedSupplierId: currentId.isEmpty ? null : currentId,
    );
    if (selected != null && mounted) {
      final cubit = context.read<QuickReceiptSessionCubit>();
      cubit.updateHeader(
        cubit.state.header.copyWith(
          supplierId: selected.id,
          supplierName: selected.name,
        ),
      );
    }
  }

  Future<void> _pickDocuments(ReceiptHeaderDraft header) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result == null || !mounted) return;
    context.read<QuickReceiptSessionCubit>().updateHeader(
      header.copyWith(
        documentFileNames: [
          ...header.documentFileNames,
          ...result.files.map((f) => f.name),
        ],
      ),
    );
  }

  void _removeDocument(ReceiptHeaderDraft header, int index) {
    final updated = List<String>.from(header.documentFileNames)..removeAt(index);
    context.read<QuickReceiptSessionCubit>().updateHeader(
      header.copyWith(documentFileNames: updated),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<QuickReceiptSessionCubit, QuickReceiptSessionState>(
      builder: (context, state) {
        final header = state.header;
        final supplierMissing = _triedContinue && header.supplierId.isEmpty;
        final locked = state.warehouseLocked;
        final catalogReady = state.catalogStatus == CatalogStatus.ready && !locked;
        if (_warehouseController.text != header.warehouseName) {
          _warehouseController.text = header.warehouseName;
        }
        final dateText = _formatDate(header.receiptDate);
        if (_dateController.text != dateText) _dateController.text = dateText;

        return Scaffold(
          backgroundColor: colors.surfaceAlt,
          appBar: const VAppBar(
            title: 'Nhập hàng nhanh',
            showBackButton: true,
          ),
          body: state.permissionDenied
              ? const InventoryPermissionDenied()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.catalogConflict) ...[
                        InventoryNoticeBanner(
                          InventoryNotice.conflict,
                          action: VButton(
                            label: 'Tải lại',
                            variant: VButtonVariant.secondary,
                            size: VButtonSize.small,
                            onPressed: context.read<QuickReceiptSessionCubit>().loadCatalog,
                          ),
                        ),
                        const VGap.cozy(),
                      ],
                      if (locked) ...[
                        const InventoryNoticeBanner(InventoryNotice.locked),
                        const VGap.cozy(),
                      ],
                      if (_triedContinue && !header.isValid) ...[
                        const InventoryNoticeBanner(InventoryNotice.validation),
                        const VGap.cozy(),
                      ],
                      VSection(
                        title: 'Thông tin lần nhận',
                        subtitle: 'Xác định nhà cung cấp, phạm vi nhận và chứng từ giao nhận.',
                        gapAfterHeader: VSpacing.space4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            VField(
                              invalid: supplierMissing,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VFieldLabel('Nhà cung cấp', isRequired: true),
                                  const VGap(VSpacing.space1),
                                  InkWell(
                                    onTap: catalogReady ? () => _selectSupplier(state) : null,
                                    borderRadius: BorderRadius.circular(VRadius.button),
                                    child: Opacity(
                                      opacity: catalogReady ? 1 : 0.4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: VSpacing.space3,
                                          vertical: VSpacing.space3,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: supplierMissing
                                                ? colors.danger
                                                : (header.supplierId.isEmpty
                                                      ? colors.borderDefault
                                                      : colors.primary),
                                          ),
                                          borderRadius: BorderRadius.circular(VRadius.button),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: VText(
                                                header.supplierName.isNotEmpty
                                                    ? header.supplierName
                                                    : 'Chạm để chọn nhà cung cấp...',
                                                style: VTypography.bodyDefault.copyWith(
                                                  color: header.supplierName.isNotEmpty
                                                      ? colors.textPrimary
                                                      : colors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            const VIcon(
                                              icon: VIcons.chevronDown,
                                              iconSize: VIconSize.sm,
                                              iconColor: VIconColor.muted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (supplierMissing) ...[
                                    const VGap(VSpacing.space1),
                                    const VFieldError('Chọn nhà cung cấp trong danh sách.'),
                                  ],
                                ],
                              ),
                            ),
                            const VGap.cozy(),
                            VField(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VFieldLabel('Kho nhận'),
                                  const VGap(VSpacing.space1),
                                  VTextField(
                                    controller: _warehouseController,
                                    enabled: false,
                                  ),
                                ],
                              ),
                            ),
                            const VGap.cozy(),
                            VField(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VFieldLabel('Ngày nhận'),
                                  const VGap(VSpacing.space1),
                                  VTextField(
                                    controller: _dateController,
                                    enabled: false,
                                  ),
                                ],
                              ),
                            ),
                            const VGap.cozy(),
                            VField(
                              invalid: _triedContinue && header.documentFileNames.isEmpty,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VFieldLabel(
                                    'Chứng từ giao nhận',
                                    isRequired: true,
                                  ),
                                  const VGap(VSpacing.space2),
                                  VFileDropZone(
                                    title: 'Chọn hoặc kéo tệp',
                                    subtitle:
                                        'Phiếu giao hàng, biên bản bàn giao, vận đơn hoặc bản scan/ảnh rõ nội dung',
                                    state: header.documentFileNames.isEmpty
                                        ? (_triedContinue
                                              ? VFileDropZoneState.invalid
                                              : VFileDropZoneState.empty)
                                        : VFileDropZoneState.valid,
                                    onTap: locked ? null : () => _pickDocuments(header),
                                  ),
                                  if (_triedContinue && header.documentFileNames.isEmpty) ...[
                                    const VGap(VSpacing.space1),
                                    const VFieldError(
                                      'Cần đính kèm ít nhất một chứng từ giao nhận.',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (header.documentFileNames.isNotEmpty) ...[
                              const VGap.cozy(),
                              for (final entry in header.documentFileNames.asMap().entries)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: VSpacing.space2),
                                  child: Container(
                                    padding: const EdgeInsets.all(VSpacing.space2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: colors.borderDefault),
                                      borderRadius: BorderRadius.circular(VRadius.button),
                                    ),
                                    child: Row(
                                      children: [
                                        const VIcon(
                                          icon: VIcons.file,
                                          iconSize: VIconSize.md,
                                          iconColor: VIconColor.primary,
                                        ),
                                        const VGap(VSpacing.space2, axis: Axis.horizontal),
                                        Expanded(
                                          child: VText(
                                            entry.value,
                                            style: VTypography.bodySmall,
                                          ),
                                        ),
                                        VButton.icon(
                                          icon: VIcons.close,
                                          semanticLabel: 'Xoá chứng từ',
                                          variant: VButtonVariant.tertiary,
                                          size: VButtonSize.small,
                                          onPressed: () => _removeDocument(header, entry.key),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                            const VGap.cozy(),
                            VText(
                              'Xác nhận quyền sở hữu',
                              style: VTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                            const VGap(VSpacing.space1),
                            VText(
                              'Hệ thống lưu người xác nhận, thời điểm và chứng từ giao nhận.',
                              style: VTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: state.permissionDenied || locked
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: VButton(
                      label: 'Xác nhận & tiếp tục',
                      fullWidth: true,
                      size: VButtonSize.large,
                      onPressed: () {
                        if (!header.isValid) {
                          setState(() => _triedContinue = true);
                          return;
                        }
                        context.push('/warehouse/receipts/quick/items');
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }
}
