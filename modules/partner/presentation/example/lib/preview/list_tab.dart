import 'package:flutter/material.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class PartnerListTab extends StatefulWidget {
  const PartnerListTab({super.key});

  @override
  State<PartnerListTab> createState() => _PartnerListTabState();
}

class _PartnerListTabState extends State<PartnerListTab> {
  PartnerRoleFilter? _quickRole = PartnerRoleFilter.customer;
  String _wardValue = '';

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'PartnerListItemTile',
        description: 'Active + inactive list rows.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewStateRow(
              label: 'Active',
              child: PartnerListItemTile(
                item: PartnerPreviewFixtures.listActive,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Inactive',
              child: PartnerListItemTile(
                item: PartnerPreviewFixtures.listInactive,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
      const PreviewSection(
        title: 'PartnerListItemSkeletonTile',
        description: 'Loading placeholder.',
        child: PartnerListItemSkeletonTile(),
      ),
      PreviewSection(
        title: 'PartnerListSearchBar',
        description: 'Search + filter badge.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Default',
              child: PartnerListSearchBar(onSearch: (_) {}),
            ),
            PreviewStateRow(
              label: 'With active filters',
              child: PartnerListSearchBar(
                onSearch: (_) {},
                onFilterTap: () {},
                activeFilterCount: 3,
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'PartnerListQuickFilters',
        description: 'Role chips.',
        child: PartnerListQuickFilters(
          selectedRole: _quickRole,
          onRoleSelected: (role) => setState(() => _quickRole = role),
        ),
      ),
      PreviewSection(
        title: 'PartnerActiveFilters',
        description: 'Active filter chips + clear all.',
        child: PartnerActiveFilters(
          partnerType: PartnerType.organization,
          roleFilter: PartnerRoleFilter.customer,
          status: PartnerStatus.active,
          updatedTimeFilter: PartnerUpdatedTimeFilter.last7Days,
          onRemoveFilter: (_) {},
          onClearAll: () {},
        ),
      ),
      PreviewSection(
        title: 'PartnerFilterBottomSheet / PartnerSortBottomSheet',
        description: 'Tap to open sheets.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Open filter sheet',
              onPressed: () {
                PartnerFilterBottomSheet.show(
                  context,
                  role: PartnerRoleFilter.customer,
                  partnerType: PartnerType.person,
                  status: PartnerStatus.active,
                  updatedTimeFilter: PartnerUpdatedTimeFilter.last30Days,
                );
              },
            ),
            PreviewActionButton(
              label: 'Open sort sheet',
              onPressed: () {
                PartnerSortBottomSheet.show(
                  context,
                  initialSort: PartnerSortOption.updatedAtDesc,
                );
              },
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'PartnerWardSearchDropdown',
        description: 'Enabled + disabled ward picker.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Enabled',
              child: PartnerWardSearchDropdown(
                value: _wardValue,
                wards: PartnerPreviewFixtures.sampleWards,
                enabled: true,
                hintText: 'Chọn phường/xã',
                onSelected: (ward) {
                  setState(() => _wardValue = ward.fullName);
                },
              ),
            ),
            PreviewStateRow(
              label: 'Disabled',
              child: PartnerWardSearchDropdown(
                value: '',
                wards: const [],
                enabled: false,
                hintText: 'Chọn tỉnh/thành trước',
                onSelected: (_) {},
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
