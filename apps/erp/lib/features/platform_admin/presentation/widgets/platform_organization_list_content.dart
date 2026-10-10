import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';
import 'platform_organization_card.dart';

/// Danh sách cuộn có kéo để tải lại và nút "Tải thêm" khi còn trang sau.
class PlatformOrganizationListContent extends StatelessWidget {
  const PlatformOrganizationListContent({
    super.key,
    required this.tenants,
    required this.onRefresh,
    this.onTap,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final List<PlatformTenantSummary> tenants;
  final Future<void> Function() onRefresh;
  final ValueChanged<PlatformTenantSummary>? onTap;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final footer = hasMore ? 1 : 0;

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space3,
        ),
        itemCount: tenants.length + footer,
        separatorBuilder: (context, index) => const VGap.sm(),
        itemBuilder: (context, index) {
          if (index == tenants.length) {
            return Center(
              child: isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(VSpacing.space3),
                      child: CircularProgressIndicator(),
                    )
                  : VButton(
                      label: 'Tải thêm',
                      variant: VButtonVariant.secondary,
                      onPressed: onLoadMore,
                    ),
            );
          }
          final tenant = tenants[index];
          return PlatformOrganizationCard(
            tenant: tenant,
            onTap: onTap == null ? null : () => onTap!(tenant),
          );
        },
      ),
    );
  }
}
