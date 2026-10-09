import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'vn_administrative_units_loader.dart';

/// Selection result containing the selected [province] and optional [ward].
typedef VnAdministrativeUnitSelection = ({
  VnAdministrativeUnit province,
  VnWard? ward,
});

/// Displays a cascading bottom sheet to pick a province and ward.
Future<VnAdministrativeUnitSelection?> showVnAdministrativeUnitPickerSheet({
  required BuildContext context,
  required List<VnAdministrativeUnit> units,
  String? initialProvinceCode,
  String? initialCommuneCode,
  int initialTab = 0,
}) {
  return showVBottomSheet<VnAdministrativeUnitSelection>(
    context: context,
    child: VnAdministrativeUnitPickerSheet(
      units: units,
      initialProvinceCode: initialProvinceCode,
      initialCommuneCode: initialCommuneCode,
      initialTab: initialTab,
    ),
  );
}

/// Bottom sheet widget that allows users to pick a province and ward
/// in a seamless cascading flow.
class VnAdministrativeUnitPickerSheet extends StatefulWidget {
  const VnAdministrativeUnitPickerSheet({
    super.key,
    required this.units,
    this.initialProvinceCode,
    this.initialCommuneCode,
    this.initialTab = 0,
  });

  final List<VnAdministrativeUnit> units;
  final String? initialProvinceCode;
  final String? initialCommuneCode;
  final int initialTab;

  @override
  State<VnAdministrativeUnitPickerSheet> createState() =>
      _VnAdministrativeUnitPickerSheetState();
}

class _VnAdministrativeUnitPickerSheetState
    extends State<VnAdministrativeUnitPickerSheet>
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
    // Resolve initial province
    if (widget.initialProvinceCode != null) {
      for (final unit in widget.units) {
        if (unit.code == widget.initialProvinceCode) {
          _selectedProvince = unit;
          break;
        }
      }
    }

    // Resolve initial ward
    if (_selectedProvince != null && widget.initialCommuneCode != null) {
      for (final ward in _selectedProvince!.wards) {
        if (ward.code == widget.initialCommuneCode) {
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
        final currentIndex = tabController.index;
        final hasProvince = selectedProvince != null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: Row(
            children: [
              // Tab 1: Province
              Expanded(
                child: _StepTabItem(
                  index: 0,
                  isActive: currentIndex == 0,
                  isDone: hasProvince,
                  label: selectedProvince?.fullName ?? 'Tỉnh / thành phố',
                  onTap: () => onTabTap(0),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.borderStrong,
                ),
              ),

              // Tab 2: Ward
              Expanded(
                child: _StepTabItem(
                  index: 1,
                  isActive: currentIndex == 1,
                  isDone: selectedWard != null,
                  isEnabled: hasProvince,
                  label: selectedWard?.fullName ?? 'Xã / phường',
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

class _StepTabItem extends StatelessWidget {
  const _StepTabItem({
    required this.index,
    required this.isActive,
    required this.isDone,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
  });

  final int index;
  final bool isActive;
  final bool isDone;
  final bool isEnabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final labelColor = !isEnabled
        ? colors.textMuted
        : isActive
            ? colors.primary
            : isDone
                ? colors.textPrimary
                : colors.textSecondary;

    return InkWell(
      key: Key('tab_picker_step_$index'),
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(VRadius.r6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? colors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDone && !isActive) ...[
              Icon(Icons.check_circle, size: 16, color: colors.primary),
              const SizedBox(width: VSpacing.space1),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VTypography.bodySmall.copyWith(
                  color: labelColor,
                  fontWeight: isActive || isDone ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    if (provinces.isEmpty) {
      return _EmptySearchState(searchQuery: searchQuery);
    }

    final colors = context.vColors;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: VSpacing.space3,
              horizontal: VSpacing.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    province.fullName,
                    style: VTypography.bodyDefault.copyWith(
                      color: isSelected ? colors.primary : colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
              Icon(Icons.info_outline, size: 40, color: colors.textSecondary),
              const SizedBox(height: VSpacing.space2),
              Text(
                'Vui lòng chọn tỉnh / thành phố trước',
                style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (wards.isEmpty) {
      return _EmptySearchState(searchQuery: searchQuery);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: VSpacing.space3,
              horizontal: VSpacing.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ward.fullName,
                    style: VTypography.bodyDefault.copyWith(
                      color: isSelected ? colors.primary : colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 44, color: colors.textMuted),
            const SizedBox(height: VSpacing.space2),
            Text(
              searchQuery.isEmpty
                  ? 'Không có dữ liệu phù hợp'
                  : 'Không tìm thấy kết quả cho "$searchQuery"',
              textAlign: TextAlign.center,
              style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Normalizes a string by folding Vietnamese diacritics to basic Latin.
String _foldVietnamese(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final codeUnit in lower.codeUnits) {
    buffer.writeCharCode(_foldCodeUnit(codeUnit));
  }
  return buffer.toString();
}

int _foldCodeUnit(int codeUnit) {
  const map = <int, int>{
    // a variants
    0x00E0: 0x61, 0x00E1: 0x61, 0x00E2: 0x61, 0x00E3: 0x61, 0x1EA1: 0x61,
    0x1EA3: 0x61, 0x1EA5: 0x61, 0x1EA7: 0x61, 0x1EA9: 0x61, 0x1EAB: 0x61,
    0x1EAD: 0x61, 0x0103: 0x61, 0x1EAF: 0x61, 0x1EB1: 0x61, 0x1EB3: 0x61,
    0x1EB5: 0x61, 0x1EB7: 0x61,
    // e variants
    0x00E8: 0x65, 0x00E9: 0x65, 0x00EA: 0x65, 0x1EB9: 0x65, 0x1EBB: 0x65,
    0x1EBD: 0x65, 0x1EBF: 0x65, 0x1EC1: 0x65, 0x1EC3: 0x65, 0x1EC5: 0x65,
    0x1EC7: 0x65,
    // i variants
    0x00EC: 0x69, 0x00ED: 0x69, 0x0129: 0x69, 0x1EC9: 0x69, 0x1ECB: 0x69,
    // o variants
    0x00F2: 0x6F, 0x00F3: 0x6F, 0x00F4: 0x6F, 0x00F5: 0x6F, 0x1ECD: 0x6F,
    0x1ECF: 0x6F, 0x1ED1: 0x6F, 0x1ED3: 0x6F, 0x1ED5: 0x6F, 0x1ED7: 0x6F,
    0x1ED9: 0x6F, 0x01A1: 0x6F, 0x1EDB: 0x6F, 0x1EDD: 0x6F, 0x1EDF: 0x6F,
    0x1EE1: 0x6F, 0x1EE3: 0x6F,
    // u variants
    0x00F9: 0x75, 0x00FA: 0x75, 0x0169: 0x75, 0x1EE5: 0x75, 0x1EE7: 0x75,
    0x01B0: 0x75, 0x1EE9: 0x75, 0x1EEB: 0x75, 0x1EED: 0x75, 0x1EEF: 0x75,
    0x1EF1: 0x75,
    // y variants
    0x00FD: 0x79, 0x1EF3: 0x79, 0x1EF5: 0x79, 0x1EF7: 0x79, 0x1EF9: 0x79,
    // d variants
    0x0111: 0x64,
  };
  return map[codeUnit] ?? codeUnit;
}
