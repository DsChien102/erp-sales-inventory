import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../data/vn_administrative_unit.dart';

/// Selection result containing the selected [province] and optional [ward].
typedef PartnerAdministrativeUnitSelection = ({
  VnAdministrativeUnit province,
  VnWard? ward,
});

/// Displays a cascading bottom sheet to pick a province and ward for partner delivery.
Future<PartnerAdministrativeUnitSelection?> showPartnerAdministrativeUnitPickerSheet({
  required BuildContext context,
  required List<VnAdministrativeUnit> units,
  String? initialProvinceName,
  String? initialCommuneName,
  int initialTab = 0,
}) {
  return showVAdaptiveSheet<PartnerAdministrativeUnitSelection>(
    context: context,
    child: PartnerAdministrativeUnitPickerSheet(
      units: units,
      initialProvinceName: initialProvinceName,
      initialCommuneName: initialCommuneName,
      initialTab: initialTab,
    ),
  );
}

/// Bottom sheet widget that allows users to pick a province and ward
/// in a seamless cascading flow for partner delivery address.
class PartnerAdministrativeUnitPickerSheet extends StatefulWidget {
  const PartnerAdministrativeUnitPickerSheet({
    super.key,
    required this.units,
    this.initialProvinceName,
    this.initialCommuneName,
    this.initialTab = 0,
  });

  final List<VnAdministrativeUnit> units;
  final String? initialProvinceName;
  final String? initialCommuneName;
  final int initialTab;

  @override
  State<PartnerAdministrativeUnitPickerSheet> createState() =>
      _PartnerAdministrativeUnitPickerSheetState();
}

class _PartnerAdministrativeUnitPickerSheetState
    extends State<PartnerAdministrativeUnitPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  VnAdministrativeUnit? _selectedProvince;
  VnWard? _selectedWard;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Resolve initial province by name
    if (widget.initialProvinceName != null && widget.initialProvinceName!.isNotEmpty) {
      for (final unit in widget.units) {
        if (unit.fullName == widget.initialProvinceName) {
          _selectedProvince = unit;
          break;
        }
      }
    }

    // Resolve initial ward by name
    if (_selectedProvince != null &&
        widget.initialCommuneName != null &&
        widget.initialCommuneName!.isNotEmpty) {
      for (final ward in _selectedProvince!.wards) {
        if (ward.fullName == widget.initialCommuneName) {
          _selectedWard = ward;
          break;
        }
      }
    }

    final startTab = (widget.initialTab == 1 && _selectedProvince != null) ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: startTab);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onProvinceSelected(VnAdministrativeUnit province) {
    setState(() {
      _selectedProvince = province;
      if (_selectedWard?.provinceCode != province.code) {
        _selectedWard = null;
      }
      _searchController.clear();
      _searchQuery = '';
    });
    _tabController.animateTo(1);
  }

  void _onWardSelected(VnWard ward) {
    setState(() {
      _selectedWard = ward;
    });
    if (_selectedProvince != null) {
      Navigator.of(context).pop((
        province: _selectedProvince!,
        ward: ward,
      ));
    }
  }

  List<VnAdministrativeUnit> _filterProvinces() {
    final sorted = List<VnAdministrativeUnit>.from(widget.units)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (_searchQuery.isEmpty) return sorted;
    final normalizedQuery = _foldVietnamese(_searchQuery);
    return sorted.where((p) {
      final normalizedName = _foldVietnamese(p.fullName);
      return normalizedName.contains(normalizedQuery);
    }).toList(growable: false);
  }

  List<VnWard> _filterWards() {
    if (_selectedProvince == null) return const [];
    final sorted = List<VnWard>.from(_selectedProvince!.wards)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (_searchQuery.isEmpty) return sorted;
    final normalizedQuery = _foldVietnamese(_searchQuery);
    return sorted.where((w) {
      final normalizedName = _foldVietnamese(w.fullName);
      return normalizedName.contains(normalizedQuery);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.viewInsets.bottom;

    // Adapt sheet height dynamically when software keyboard opens to avoid overflow.
    final availableHeight = (screenHeight * 0.95) - 24.0 - bottomInset;
    final preferredHeight = screenHeight * 0.75;
    final sheetHeight = preferredHeight > availableHeight
        ? availableHeight.clamp(200.0, screenHeight)
        : preferredHeight;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space1,
              VSpacing.space2,
              VSpacing.space2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VText(
                  'Khu vực hành chính',
                  variant: VTextVariant.headingH4,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  key: const Key('button_close_unit_picker'),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            child: VSearchBar(
              key: const Key('input_unit_search'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: _tabController.index == 0
                  ? 'Tìm kiếm tỉnh, thành phố...'
                  : 'Tìm kiếm xã, phường tại ${_selectedProvince?.fullName ?? ''}...',
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
          ),

          const SizedBox(height: VSpacing.space2),

          // Cascading Stepper / Tabs
          _PickerStepperTabs(
            tabController: _tabController,
            selectedProvince: _selectedProvince,
            selectedWard: _selectedWard,
            onTabTap: (index) {
              if (index == 1 && _selectedProvince == null) return;
              _tabController.animateTo(index);
            },
          ),

          const VDivider(),

          // Tab Views (Provinces & Wards)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Province List
                _ProvinceListView(
                  provinces: _filterProvinces(),
                  selectedCode: _selectedProvince?.code,
                  onSelected: _onProvinceSelected,
                  searchQuery: _searchQuery,
                ),

                // Tab 1: Ward List
                _WardListView(
                  selectedProvince: _selectedProvince,
                  wards: _filterWards(),
                  selectedCode: _selectedWard?.code,
                  onSelected: _onWardSelected,
                  searchQuery: _searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Stepper Tabs showing [Province] -> [Ward] status.
class _PickerStepperTabs extends StatelessWidget {
  const _PickerStepperTabs({
    required this.tabController,
    required this.selectedProvince,
    required this.selectedWard,
    required this.onTabTap,
  });

  final TabController tabController;
  final VnAdministrativeUnit? selectedProvince;
  final VnWard? selectedWard;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final currentTab = tabController.index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: Row(
            children: [
              // Step 1: Province
              Expanded(
                child: _StepButton(
                  key: const Key('tab_picker_step_0'),
                  index: 0,
                  stepNumber: '1',
                  title: 'Tỉnh / thành phố',
                  subtitle: selectedProvince?.fullName,
                  isActive: currentTab == 0,
                  isCompleted: selectedProvince != null,
                  onTap: () => onTabTap(0),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.textSecondary.withValues(alpha: 0.5),
                ),
              ),

              // Step 2: Ward
              Expanded(
                child: _StepButton(
                  key: const Key('tab_picker_step_1'),
                  index: 1,
                  stepNumber: '2',
                  title: 'Xã / phường',
                  subtitle: selectedWard?.fullName,
                  isActive: currentTab == 1,
                  isCompleted: selectedWard != null,
                  isEnabled: selectedProvince != null,
                  onTap: () => onTabTap(1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.index,
    required this.stepNumber,
    required this.title,
    this.subtitle,
    required this.isActive,
    required this.isCompleted,
    this.isEnabled = true,
    required this.onTap,
  });

  final int index;
  final String stepNumber;
  final String title;
  final String? subtitle;
  final bool isActive;
  final bool isCompleted;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final badgeColor = isActive
        ? colors.primary
        : (isCompleted ? colors.primary.withValues(alpha: 0.15) : colors.surfaceAlt);
    final badgeTextColor = isActive
        ? colors.surface
        : (isCompleted ? colors.primary : colors.textSecondary);
    final titleColor = isEnabled ? colors.textPrimary : colors.textSecondary;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(VRadius.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space2,
          vertical: VSpacing.space2,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? colors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isCompleted && !isActive
                  ? Icon(Icons.check, size: 12, color: colors.primary)
                  : Text(
                      stepNumber,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A-Z Province ListView.
class _ProvinceListView extends StatelessWidget {
  const _ProvinceListView({
    required this.provinces,
    required this.selectedCode,
    required this.onSelected,
    required this.searchQuery,
  });

  final List<VnAdministrativeUnit> provinces;
  final String? selectedCode;
  final ValueChanged<VnAdministrativeUnit> onSelected;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (provinces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: colors.textSecondary),
              const SizedBox(height: VSpacing.space2),
              VText(
                'Không tìm thấy tỉnh / thành phố',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: VSpacing.space1),
                VText(
                  'Không có kết quả nào khớp với "$searchQuery"',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('list_provinces'),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      itemCount: provinces.length,
      separatorBuilder: (context, index) => const VDivider(),
      itemBuilder: (context, index) {
        final province = provinces[index];
        final isSelected = province.code == selectedCode;

        return InkWell(
          key: Key('item_province_${province.code}'),
          onTap: () => onSelected(province),
          borderRadius: BorderRadius.circular(VRadius.r6),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space3,
              vertical: VSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(VRadius.r6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Text(
                    province.fullName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${province.wards.length} xã/phường',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: VSpacing.space2),
                  Icon(Icons.check_circle_rounded, size: 18, color: colors.primary),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A-Z Ward ListView.
class _WardListView extends StatelessWidget {
  const _WardListView({
    required this.selectedProvince,
    required this.wards,
    required this.selectedCode,
    required this.onSelected,
    required this.searchQuery,
  });

  final VnAdministrativeUnit? selectedProvince;
  final List<VnWard> wards;
  final String? selectedCode;
  final ValueChanged<VnWard> onSelected;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (selectedProvince == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, size: 36, color: colors.textSecondary),
              const SizedBox(height: VSpacing.space2),
              VText(
                'Vui lòng chọn tỉnh / thành phố trước',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    if (wards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: colors.textSecondary),
              const SizedBox(height: VSpacing.space2),
              VText(
                'Không tìm thấy xã / phường',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: VSpacing.space1),
                VText(
                  'Không có kết quả nào khớp với "$searchQuery"',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('list_wards'),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      itemCount: wards.length,
      separatorBuilder: (context, index) => const VDivider(),
      itemBuilder: (context, index) {
        final ward = wards[index];
        final isSelected = ward.code == selectedCode;

        return InkWell(
          key: Key('item_ward_${ward.code}'),
          onTap: () => onSelected(ward),
          borderRadius: BorderRadius.circular(VRadius.r6),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space3,
              vertical: VSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(VRadius.r6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 18,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Text(
                    ward.fullName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 18, color: colors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper function to normalize Vietnamese text for search comparison
/// by folding diacritics and converting to lowercase.
String _foldVietnamese(String input) {
  var str = input.toLowerCase();
  str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');
  return str;
}
