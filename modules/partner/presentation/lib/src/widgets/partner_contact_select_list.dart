import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerContactSelectList extends StatefulWidget {
  const PartnerContactSelectList({
    super.key,
    required this.partnerModule,
    required this.executionContext,
    required this.onSelect,
    required this.onCancel,
    this.excludePersonPartnerIds = const [],
  });

  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final void Function(List<Map<String, dynamic>> selectedContacts) onSelect;
  final VoidCallback onCancel;
  final List<String> excludePersonPartnerIds;

  @override
  State<PartnerContactSelectList> createState() => _PartnerContactSelectListState();
}

class _PartnerContactSelectListState extends State<PartnerContactSelectList> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<PartnerListItemDto> _items = [];
  final Set<String> _selectedIds = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _search();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search();
    });
  }

  Future<void> _search() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tenantId = await widget.executionContext.requireTenantId();
      final result = await widget.partnerModule.executeQueryAsync(
        SearchPartnersQuery(
          tenantId: tenantId,
          query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
          partnerType: PartnerType.person,
          status: PartnerStatus.active,
          limit: 30,
          page: 1,
        ),
      );
      if (mounted) {
        setState(() {
          _items = result.items
              .where((item) => !widget.excludePersonPartnerIds.contains(item.partnerId))
              .toList();
          _isLoading = false;
          // Clean selection if not in new list
          _selectedIds.retainWhere((id) => _items.any((i) => i.partnerId == id));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Color _getAvatarColor(String displayName) {
    final palette = [
      VColors.success,
      VColors.warning,
      VColors.info,
      VColors.primary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    int sum = 0;
    for (int i = 0; i < displayName.length; i++) {
      sum += displayName.codeUnitAt(i);
    }
    return palette[sum % palette.length];
  }

  String _getInitials(String displayName) {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar area
        Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: VSearchBar(
            key: const Key('input_contact_select_search'),
            controller: _searchController,
            hintText: 'Tìm kiếm tên, SĐT, email',
            onChanged: (val) {}, // Handled by listener
          ),
        ),

        // List area
        Expanded(
          child: _buildBody(colors),
        ),

        // Action footer
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.borderDefault)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Hủy',
                      variant: VButtonVariant.outline,
                      foregroundColor: colors.success,
                      onPressed: widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: VButton(
                      key: const Key('btn_contact_select_submit'),
                      label: 'Chọn (${_selectedIds.length})',
                      variant: VButtonVariant.primary,
                      onPressed: _selectedIds.isNotEmpty
                          ? () {
                              final selected = _items
                                  .where((i) => _selectedIds.contains(i.partnerId))
                                  .map(
                                    (i) => {
                                      'personPartnerId': i.partnerId,
                                      'displayName': i.displayName,
                                    },
                                  )
                                  .toList();
                              widget.onSelect(selected);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(VColorScheme colors) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Text(
            'Lỗi: $_errorMessage',
            style: VTypography.bodyDefault.copyWith(color: colors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy cá nhân nào.',
          style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
      itemCount: _items.length,
      separatorBuilder: (_, __) => Divider(color: colors.borderDefault, height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];

        return InkWell(
          onTap: () {
            setState(() {
              if (_selectedIds.contains(item.partnerId)) {
                _selectedIds.remove(item.partnerId);
              } else {
                _selectedIds.add(item.partnerId);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(item.displayName),
                  child: Text(
                    _getInitials(item.displayName),
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: VTypography.bodyDefault.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.phone != null && item.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.phone!,
                          style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ],
                      if (item.email != null && item.email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.email!,
                          style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                _buildSelectionIndicator(_selectedIds.contains(item.partnerId), colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionIndicator(bool isSelected, VColorScheme colors) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? colors.success : Colors.transparent,
        border: Border.all(
          color: isSelected ? colors.success : colors.borderStrong,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            )
          : null,
    );
  }
}
