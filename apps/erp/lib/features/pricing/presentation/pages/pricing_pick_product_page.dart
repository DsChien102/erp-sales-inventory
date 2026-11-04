import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:vet45_design_system/design_system.dart';

import '../widgets/pricing_selectable_entity_card.dart';

/// SG-03 (D-04) — Chọn sản phẩm cho giá riêng.
///
/// Avatar Card (Figma): tap để chọn (radio + viền), nút Chọn để pop
/// `{'id', 'name', ...}`.
class PricingPickProductPage extends StatefulWidget {
  const PricingPickProductPage({super.key});

  @override
  State<PricingPickProductPage> createState() => _PricingPickProductPageState();
}

class _PricingPickProductPageState extends State<PricingPickProductPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  String? _errorMessage;
  List<ProductListItemDto> _items = const [];
  String? _selectedId;

  ProductListItemDto? get _selectedItem {
    final id = _selectedId;
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final keyword = _searchController.text.trim();
      final result = await GetIt.instance<ProductRepository>().search(
        criteria: ProductSearchCriteria(
          keyword: keyword.isEmpty ? null : keyword,
        ),
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _isLoading = false;
        if (_selectedId != null && !_items.any((e) => e.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không tải được danh sách sản phẩm.';
        _isLoading = false;
      });
    }
  }

  void _confirm() {
    final item = _selectedItem;
    if (item == null) return;
    final payload = <String, String>{
      'id': item.id,
      'name': item.name,
    };
    if (item.listBeforeVat != null) {
      payload['listPriceDong'] = item.listBeforeVat!.toString();
    }
    if (item.floorBeforeVat != null) {
      payload['floorPriceDong'] = item.floorBeforeVat!.toString();
    }
    context.pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedItem != null;

    return VPageScaffold(
      title: 'Chọn sản phẩm',
      showBackButton: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space3,
              VSpacing.space4,
              VSpacing.space2,
            ),
            child: VSearchBar(
              hintText: 'Tìm tên sản phẩm...',
              controller: _searchController,
              autofocus: true,
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: _PricingPickProductBody(
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              items: _items,
              selectedId: _selectedId,
              onRetry: _load,
              onSelected: (id) => setState(() => _selectedId = id),
            ),
          ),
        ],
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

class _PricingPickProductBody extends StatelessWidget {
  const _PricingPickProductBody({
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.selectedId,
    required this.onRetry,
    required this.onSelected,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<ProductListItemDto> items;
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
    if (items.isEmpty) {
      return const VEmptyState(
        icon: VIcons.inventory,
        title: 'Không tìm thấy sản phẩm',
        description: 'Thử từ khóa khác hoặc kiểm tra chính tả.',
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
        itemCount: items.length,
        separatorBuilder: (_, _) => const VGap.sm(),
        itemBuilder: (context, index) {
          final item = items[index];
          final colors = context.vColors;
          return PricingSelectableEntityCard<String>(
            value: item.id,
            isSelected: selectedId == item.id,
            onTap: () => onSelected(item.id),
            leading: VIconBox(
              icon: VIcons.inventory,
              size: 52,
              iconSize: 20,
              borderRadius: VRadius.r16,
            ),
            title: item.name,
            subtitleChild: item.listBeforeVat == null
                ? null
                : Text.rich(
                    TextSpan(
                      style: VTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Giá hiện tại: '),
                        TextSpan(
                          text: _formatDong(item.listBeforeVat!),
                          style: VTypography.monoNumeric.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
            caption: item.baseUnit == null ? null : 'Đơn vị cơ bản: ${item.baseUnit}',
          );
        },
      ),
    );
  }

  String _formatDong(int amountDong) {
    return '${amountDong.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }
}
