import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:vet45_design_system/design_system.dart';

import '../widgets/pricing_selectable_entity_card.dart';

/// SG-03 (D-04) — Chọn đơn vị bán cho giá riêng.
///
/// List row + radio (Figma), nền xanh khi chọn; nút Chọn để pop.
class PricingPickUnitPage extends StatefulWidget {
  const PricingPickUnitPage({super.key, required this.productId});

  final String productId;

  @override
  State<PricingPickUnitPage> createState() => _PricingPickUnitPageState();
}

class _PricingPickUnitPageState extends State<PricingPickUnitPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProductUnitDto> _units = const [];
  Map<String, ProductPriceBandSnapshotItemDto> _priceByUnitId = const {};
  String? _selectedId;

  ProductUnitDto? get _selectedUnit {
    final id = _selectedId;
    if (id == null) return null;
    for (final unit in _units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final unitRepo = GetIt.instance<MeasurementUnitRepository>();
      final priceRepo = GetIt.instance<ProductPriceRepository>();

      final unitsResult = await unitRepo.listProductUnits(widget.productId);
      final units = unitsResult.units.where((u) => u.isActive).toList();

      var priceByUnitId = <String, ProductPriceBandSnapshotItemDto>{};
      if (units.isNotEmpty) {
        final snapshot = await priceRepo.getPriceBandSnapshot(
          units
              .map(
                (u) => ProductPriceBandSnapshotRequest(
                  productId: widget.productId,
                  productUnitId: u.id,
                ),
              )
              .toList(growable: false),
        );
        priceByUnitId = {
          for (final item in snapshot.items) item.productUnitId: item,
        };
      }

      if (!mounted) return;
      setState(() {
        _units = units;
        _priceByUnitId = priceByUnitId;
        _isLoading = false;
        if (_selectedId != null && !_units.any((e) => e.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không tải được danh sách đơn vị bán.';
        _isLoading = false;
      });
    }
  }

  void _confirm() {
    final unit = _selectedUnit;
    if (unit == null) return;
    final price = _priceByUnitId[unit.id];
    final payload = <String, String>{
      'id': unit.id,
      'name': unit.name,
    };
    if (price != null && !price.listBeforeVatMissing) {
      payload['listPriceDong'] = price.listBeforeVat!.toString();
    }
    if (price != null && !price.floorBeforeVatHidden && !price.floorBeforeVatMissing) {
      payload['floorPriceDong'] = price.floorBeforeVat!.toString();
    }
    context.pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedUnit != null;

    return VPageScaffold(
      title: 'Chọn đơn vị bán',
      showBackButton: true,
      body: _PricingPickUnitBody(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        units: _units,
        priceByUnitId: _priceByUnitId,
        selectedId: _selectedId,
        onRetry: _load,
        onSelected: (id) => setState(() => _selectedId = id),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: VButton(
          label: 'Chọn',
          fullWidth: true,
          onPressed: canConfirm ? _confirm : null,
        ),
      ),
    );
  }
}

class _PricingPickUnitBody extends StatelessWidget {
  const _PricingPickUnitBody({
    required this.isLoading,
    required this.errorMessage,
    required this.units,
    required this.priceByUnitId,
    required this.selectedId,
    required this.onRetry,
    required this.onSelected,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<ProductUnitDto> units;
  final Map<String, ProductPriceBandSnapshotItemDto> priceByUnitId;
  final String? selectedId;
  final VoidCallback onRetry;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const VSkeletonScope(
        child: Padding(
          padding: EdgeInsets.all(VSpacing.space4),
          child: Column(
            children: [
              VSkeleton(width: double.infinity, height: 72),
              VGap.sm(),
              VSkeleton(width: double.infinity, height: 72),
              VGap.sm(),
              VSkeleton(width: double.infinity, height: 72),
            ],
          ),
        ),
      );
    }
    if (errorMessage != null) {
      return VEmptyState(
        icon: VIcons.error,
        title: 'Đã xảy ra lỗi',
        description: errorMessage!,
        actionLabel: 'Thử lại',
        onActionPressed: onRetry,
      );
    }
    if (units.isEmpty) {
      return const VEmptyState(
        icon: VIcons.straighten,
        title: 'Chưa có đơn vị bán',
        description: 'Sản phẩm này chưa được cấu hình đơn vị bán.',
      );
    }
    return RadioGroup<String>(
      groupValue: selectedId,
      onChanged: onSelected,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space2,
        ),
        itemCount: units.length,
        separatorBuilder: (_, _) => const VGap.sm(),
        itemBuilder: (context, index) {
          final unit = units[index];
          final price = priceByUnitId[unit.id];
          return PricingSelectableEntityCard<String>(
            value: unit.id,
            isSelected: selectedId == unit.id,
            onTap: () => onSelected(unit.id),
            style: PricingSelectableCardStyle.listRow,
            selectedSurfaceFill: true,
            title: unit.name,
            subtitleChild: _priceSubtitle(context, price),
            caption: unit.isBaseUnit ? 'Đơn vị cơ bản' : null,
          );
        },
      ),
    );
  }

  Widget? _priceSubtitle(
    BuildContext context,
    ProductPriceBandSnapshotItemDto? price,
  ) {
    if (price == null) return null;

    final colors = context.vColors;
    final listLabel = price.listBeforeVatMissing ? '--' : _formatDong(price.listBeforeVat!);
    final showFloor = !price.floorBeforeVatHidden && !price.floorBeforeVatMissing;
    final floorLabel = showFloor ? _formatDong(price.floorBeforeVat!) : null;

    if (price.listBeforeVatMissing && floorLabel == null) {
      return null;
    }

    return Text.rich(
      TextSpan(
        style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
        children: [
          const TextSpan(text: 'Giá hiện tại: '),
          TextSpan(
            text: listLabel,
            style: VTypography.monoNumeric.copyWith(
              color: colors.textSecondary,
              fontSize: VTypography.bodySmall.fontSize,
            ),
          ),
          if (floorLabel != null) ...[
            const TextSpan(text: ' • Giá sàn: '),
            TextSpan(
              text: floorLabel,
              style: VTypography.monoNumeric.copyWith(
                color: colors.textSecondary,
                fontSize: VTypography.bodySmall.fontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDong(int amountDong) {
    return '${amountDong.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }
}
