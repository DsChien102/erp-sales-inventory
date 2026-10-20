import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/goods_receipt_repository.dart';
import '../../data/models/receipt_item_draft.dart';
import '../../data/models/receipt_lot_draft.dart';
import '../../logic/quick_receipt_session_cubit.dart';
import '../../logic/quick_receipt_session_state.dart';
import '../../logic/receipt_rules.dart';
import '../widgets/inventory_state_views.dart';
import '../widgets/receipt_key_value_row.dart';
import 'receipt_item_detail_args.dart';

class GoodsReceiptItemsPage extends StatefulWidget {
  const GoodsReceiptItemsPage({super.key});

  @override
  State<GoodsReceiptItemsPage> createState() => _GoodsReceiptItemsPageState();
}

class _GoodsReceiptItemsPageState extends State<GoodsReceiptItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _expandedProductId;
  int? _duplicateIndex;
  bool _triedReview = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  List<ReceiptProductDto> _results(QuickReceiptSessionState state) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return state.items.isEmpty ? state.products : const [];
    return state.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.code.toLowerCase().contains(q) ||
              p.barcode.toLowerCase().contains(q),
        )
        .toList();
  }

  void _onProductTap(ReceiptProductDto p) {
    if (p.units.length == 1) return _onUnitChosen(p, p.units.single);
    setState(() => _expandedProductId = _expandedProductId == p.id ? null : p.id);
  }

  void _onUnitChosen(ReceiptProductDto p, ReceiptUnitDto u) {
    final cubit = context.read<QuickReceiptSessionCubit>();
    final existing = cubit.indexOf(p.id, u.id);
    if (existing >= 0) {
      _searchController.clear();
      setState(() {
        _duplicateIndex = existing;
        _expandedProductId = null;
        _query = '';
      });
      return;
    }

    _openItemDetail(
      ReceiptItemDraft(
        productId: p.id,
        productName: p.name,
        productCode: p.code,
        unitId: u.id,
        unitName: u.name,
        isLotTracked: p.isLotTracked,
        requiresExpiry: p.requiresExpiry,
        lots: const [ReceiptLotDraft()],
        knownLotExpiry: p.knownLotExpiry,
      ),
    );
    _searchController.clear();
    setState(() {
      _duplicateIndex = null;
      _expandedProductId = null;
      _query = '';
    });
  }

  void _openItemDetail(ReceiptItemDraft item, {bool readOnly = false}) {
    context.push(
      '/warehouse/receipts/quick/item-detail',
      extra: ReceiptItemDetailArgs(item: item, readOnly: readOnly),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<QuickReceiptSessionCubit, QuickReceiptSessionState>(
      builder: (context, state) {
        final header = state.header;
        final cubit = context.read<QuickReceiptSessionCubit>();
        final hasDuplicate =
            _duplicateIndex != null &&
            _duplicateIndex! >= 0 &&
            _duplicateIndex! < state.items.length;
        final dup = hasDuplicate ? state.items[_duplicateIndex!] : null;
        final results = state.warehouseLocked ? const <ReceiptProductDto>[] : _results(state);
        final locked = state.warehouseLocked;

        return Scaffold(
          backgroundColor: colors.surfaceAlt,
          appBar: const VAppBar(
            title: 'Hàng thực nhận',
            showBackButton: true,
          ),
          body: state.permissionDenied
              ? const InventoryPermissionDenied()
              : ListView(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  children: [
                    if (state.catalogConflict) ...[
                      InventoryNoticeBanner(
                        InventoryNotice.conflict,
                        action: VButton(
                          label: 'Tải lại',
                          variant: VButtonVariant.secondary,
                          size: VButtonSize.small,
                          onPressed: cubit.loadCatalog,
                        ),
                      ),
                      const VGap.cozy(),
                    ],
                    if (locked) ...[
                      const InventoryNoticeBanner(InventoryNotice.locked),
                      const VGap.cozy(),
                    ],
                    if (_triedReview && !state.canReview && !locked) ...[
                      const InventoryNoticeBanner(InventoryNotice.validation),
                      const VGap.cozy(),
                    ],
                    VSection(
                      title: 'Thông tin lần nhận',
                      trailing: VText(
                        state.items.isEmpty ? 'Chưa có mặt hàng' : '${state.items.length} mặt hàng',
                        style: VTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      child: VCard(
                        child: Padding(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          child: Column(
                            children: [
                              ReceiptKeyValueRow(
                                label: 'Nhà cung cấp',
                                value: header.supplierName.isNotEmpty ? header.supplierName : '--',
                              ),
                              ReceiptKeyValueRow(
                                label: 'Kho nhận',
                                value: header.warehouseName,
                              ),
                              ReceiptKeyValueRow(
                                label: 'Ngày nhận',
                                value: _formatDate(header.receiptDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const VGap(VSpacing.space4),
                    if (!locked) ...[
                      VSearchBar(
                        controller: _searchController,
                        hintText: 'Tìm tên, mã mặt hàng hoặc mã vạch',
                        onChanged: (q) => setState(() => _query = q),
                      ),
                      const VGap.cozy(),
                    ],
                    if (locked)
                      const SizedBox.shrink()
                    else if (state.catalogStatus == CatalogStatus.loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: VSpacing.space6),
                        child: Center(child: VLoading()),
                      )
                    else if (state.catalogStatus == CatalogStatus.failure && !state.catalogConflict)
                      Column(
                        children: [
                          VText(
                            state.errorMessage ?? 'Không tải được danh mục sản phẩm.',
                            style: VTypography.bodyDefault.copyWith(
                              color: colors.danger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const VGap.cozy(),
                          VButton(
                            label: 'Thử lại',
                            variant: VButtonVariant.secondary,
                            onPressed: cubit.loadCatalog,
                          ),
                        ],
                      )
                    else if (_query.trim().isNotEmpty && results.isEmpty)
                      VText(
                        'Sản phẩm chưa có trong danh mục. Hãy bổ sung mặt hàng trước khi quay lại nhận hàng.',
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      )
                    else if (results.isNotEmpty)
                      VCard(
                        child: Column(
                          children: [
                            for (var i = 0; i < results.length; i++) ...[
                              if (i > 0) const VDivider(),
                              _ProductResultRow(
                                product: results[i],
                                expanded: _expandedProductId == results[i].id,
                                onTap: () => _onProductTap(results[i]),
                                unitHelp: (unitId) => cubit.indexOf(results[i].id, unitId) >= 0
                                    ? 'Đã có trong lần nhận'
                                    : null,
                                onUnitChosen: (u) => _onUnitChosen(results[i], u),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (dup != null) ...[
                      const VGap.cozy(),
                      VBanner(
                        status: VBannerStatus.warning,
                        title: '${dup.productName} · ${dup.unitName} đã có trong lần nhận',
                        description: 'Mở mặt hàng đã có để sửa, không tạo thêm dòng mới.',
                        footer: VButton(
                          label: 'Mở sản phẩm đã có',
                          variant: VButtonVariant.secondary,
                          size: VButtonSize.small,
                          onPressed: () {
                            final index = _duplicateIndex!;
                            setState(() => _duplicateIndex = null);
                            _openItemDetail(state.items[index]);
                          },
                        ),
                      ),
                    ],
                    const VGap(VSpacing.space4),
                    if (state.items.isEmpty)
                      const VEmptyState(
                        child: VEmptyHeader(
                          children: [
                            VEmptyMedia(icon: VIcons.inventory),
                            VEmptyTitle('Chưa có mặt hàng trong lần nhận'),
                            VEmptyDescription(
                              'Tìm mặt hàng ở trên để thêm. Sản phẩm phải có sẵn trong danh mục.',
                            ),
                          ],
                        ),
                      )
                    else
                      VCard(
                        child: Column(
                          children: [
                            for (var i = 0; i < state.items.length; i++) ...[
                              if (i > 0) const VDivider(),
                              _ReceiptItemRow(
                                item: state.items[i],
                                showIncomplete: _triedReview,
                                onTap: () => _openItemDetail(
                                  state.items[i],
                                  readOnly: locked,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
          bottomNavigationBar: state.permissionDenied
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: VButton(
                      label: 'Rà soát',
                      fullWidth: true,
                      size: VButtonSize.large,
                      enabled: state.items.isNotEmpty && !locked,
                      onPressed: () {
                        if (!state.canReview) {
                          setState(() => _triedReview = true);
                          return;
                        }
                        context.push('/warehouse/receipts/quick/review');
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _ProductResultRow extends StatelessWidget {
  const _ProductResultRow({
    required this.product,
    required this.expanded,
    required this.onTap,
    required this.unitHelp,
    required this.onUnitChosen,
  });

  final ReceiptProductDto product;
  final bool expanded;
  final VoidCallback onTap;
  final String? Function(String unitId) unitHelp;
  final ValueChanged<ReceiptUnitDto> onUnitChosen;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final units = product.units.map((u) => u.name.toLowerCase()).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        product.name,
                        style: VTypography.labelDefault.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const VGap(VSpacing.space1),
                      VText(
                        '${product.code} · $units',
                        style: VTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const VIcon(
                  icon: VIcons.chevronRight,
                  iconSize: VIconSize.sm,
                  iconColor: VIconColor.muted,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space3,
              0,
              VSpacing.space3,
              VSpacing.space3,
            ),
            child: VChoiceList<String>(
              choices: [
                for (final u in product.units)
                  VChoiceOption(
                    value: u.id,
                    label: u.name,
                    helpText: unitHelp(u.id),
                  ),
              ],
              selected: const [],
              onChanged: (ids) {
                if (ids.isEmpty) return;
                onUnitChosen(
                  product.units.firstWhere((u) => u.id == ids.single),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({
    required this.item,
    required this.onTap,
    this.showIncomplete = false,
  });

  final ReceiptItemDraft item;
  final VoidCallback onTap;
  final bool showIncomplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    item.productName,
                    style: VTypography.labelDefault.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const VGap(VSpacing.space1),
                  VText(
                    '${item.productCode} · ${item.unitName}',
                    style: VTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const VGap(VSpacing.space1),
                  if (showIncomplete && !validateReceiptItem(item).isValid)
                    VText(
                      'Chưa hoàn tất — mở để sửa',
                      style: VTypography.caption.copyWith(color: colors.danger),
                    )
                  else
                    VText(
                      classificationText(item),
                      style: VTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const VIcon(
              icon: VIcons.chevronRight,
              iconSize: VIconSize.sm,
              iconColor: VIconColor.muted,
            ),
          ],
        ),
      ),
    );
  }
}
