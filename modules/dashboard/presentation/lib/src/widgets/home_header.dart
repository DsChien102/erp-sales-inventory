import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Dashboard greeting / branch / notification chrome (feature-specific).
class HomeHeader extends StatelessWidget {
  final String userName;
  final String branchName;
  final bool hasNotification;
  final VoidCallback? onBranchTap;
  final VoidCallback? onNotificationTap;
  final Widget? searchBar;

  const HomeHeader({
    super.key,
    this.userName = 'Lan',
    this.branchName = 'Thú y Minh Phát · CN Biên Hoà',
    this.hasNotification = true,
    this.onBranchTap,
    this.onNotificationTap,
    this.searchBar,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Container(
      color: dynamicColors.primary,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chào buổi sáng, $userName 👋',
                      style: VTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: VSpacing.space1),
                    InkWell(
                      onTap: onBranchTap,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: VSpacing.space1),
                          Flexible(
                            child: Text(
                              branchName,
                              style: VTypography.headingH4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Stack(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: onNotificationTap,
                      icon: const Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: VSpacing.minTouchTarget,
                        minHeight: VSpacing.minTouchTarget,
                      ),
                    ),
                  ),
                  if (hasNotification)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dynamicColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (searchBar != null) ...[
            const SizedBox(height: VSpacing.space3),
            searchBar!,
          ],
        ],
      ),
    );
  }
}
