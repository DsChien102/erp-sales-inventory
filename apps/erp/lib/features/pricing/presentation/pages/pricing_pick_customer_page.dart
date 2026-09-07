import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/pricing_selectable_entity_card.dart';

/// SG-03 (D-03) — Chọn khách hàng cho giá riêng.
///
/// Avatar Card (Figma): tap để chọn (radio + viền), nút Chọn để pop
/// `{'id', 'name', 'role'}`.
class PricingPickCustomerPage extends StatefulWidget {
  const PricingPickCustomerPage({super.key});

  @override
  State<PricingPickCustomerPage> createState() => _PricingPickCustomerPageState();
}

class _PricingPickCustomerPageState extends State<PricingPickCustomerPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  String? _errorMessage;
  List<PartnerListItemDto> _items = const [];
  String? _selectedId;

  PartnerListItemDto? get _selectedItem {
    final id = _selectedId;
    if (id == null) return null;
    for (final item in _items) {
      if (item.partnerId == id) return item;
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
      final executionContext = GetIt.instance<IExecutionContext>();
      final tenantId = await executionContext.requireTenantId();
      final query = _searchController.text.trim();
      final result = await GetIt.instance<IPartnerModule>().executeQueryAsync(
        SearchPartnersQuery(
          tenantId: tenantId,
          query: query.isEmpty ? null : query,
          role: PartnerRoleType.customer,
          requireAnyRole: true,
          status: PartnerStatus.active,
          limit: 30,
        ),
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _isLoading = false;
        if (_selectedId != null && !_items.any((e) => e.partnerId == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không tải được danh sách khách hàng.';
        _isLoading = false;
      });
    }
  }

  void _confirm() {
    final item = _selectedItem;
    if (item == null) return;
    context.pop(<String, String>{
      'id': item.partnerId,
      'name': item.displayName,
      'role': _partnerRoleLabel(item.roles),
    });
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedItem != null;

    return VPageScaffold(
      title: 'Chọn khách hàng',
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
              hintText: 'Tìm tên hoặc số điện thoại khách hàng...',
              controller: _searchController,
              autofocus: true,
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: _PricingPickCustomerBody(
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

class _PricingPickCustomerBody extends StatelessWidget {
  const _PricingPickCustomerBody({
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.selectedId,
    required this.onRetry,
    required this.onSelected,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<PartnerListItemDto> items;
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
        icon: VIcons.person,
        title: 'Không tìm thấy khách hàng',
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
          final secondary = item.email ?? item.phone;
          return PricingSelectableEntityCard<String>(
            value: item.partnerId,
            isSelected: selectedId == item.partnerId,
            onTap: () => onSelected(item.partnerId),
            leading: PricingPickInitialsLeading(name: item.displayName),
            title: item.displayName,
            subtitle: secondary,
            caption: _partnerRoleLabel(item.roles),
          );
        },
      ),
    );
  }
}

String _partnerRoleLabel(List<PartnerRoleType> roles) {
  final isCustomer = roles.contains(PartnerRoleType.customer);
  final isSupplier = roles.contains(PartnerRoleType.supplier);
  return switch ((isCustomer, isSupplier)) {
    (true, true) => 'KH & NCC',
    (true, false) => 'Khách hàng',
    (false, true) => 'Nhà cung cấp',
    (false, false) => 'Chưa có vai trò',
  };
}
