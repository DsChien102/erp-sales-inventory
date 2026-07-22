import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';
import 'organization_card_item.dart';
import 'organization_empty_view.dart';

/// Widget danh sách nội dung tổ chức (render cuộn hoặc OrganizationEmptyView).
class OrganizationListContent extends StatelessWidget {
  final List<OrganizationUiModel> organizations;
  final ValueChanged<OrganizationUiModel>? onItemTap;
  final Future<void> Function()? onRefresh;
  final OrganizationEmptyStateType emptyType;
  final VoidCallback? onEmptyAction;

  const OrganizationListContent({
    super.key,
    required this.organizations,
    this.onItemTap,
    this.onRefresh,
    this.emptyType = OrganizationEmptyStateType.noResults,
    this.onEmptyAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (organizations.isEmpty) {
      final emptyBody = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrganizationEmptyView(
          type: emptyType,
          onAction: onEmptyAction ?? () {},
        ),
      );

      if (onRefresh != null) {
        return RefreshIndicator(
          color: colors.primary,
          onRefresh: onRefresh!,
          child: emptyBody,
        );
      }
      return emptyBody;
    }

    final listView = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space3,
      ),
      itemCount: organizations.length,
      separatorBuilder: (context, index) => const VGap.sm(),
      itemBuilder: (context, index) {
        final item = organizations[index];
        return OrganizationCardItem(
          organization: item,
          onTap: () => onItemTap?.call(item),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: colors.primary,
        onRefresh: onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}
