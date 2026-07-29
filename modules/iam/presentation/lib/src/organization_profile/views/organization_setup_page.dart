import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../testing/fake_organization_setup_data.dart';
import '../widgets/confirm_activate_organization_bottom_sheet.dart';

/// Trang Hoàn tất thiết lập & Kích hoạt tổ chức (Hợp nhất TA-D-03 & TA-D-04).
///
/// Giao diện chuyển đổi linh hoạt theo trạng thái [FakeOrganizationSetupData.isReadyToActivate].
class OrganizationSetupPage extends StatefulWidget {
  final VoidCallback? onCompleteTap;
  final VoidCallback? onActivateSuccess;

  const OrganizationSetupPage({
    super.key,
    this.onCompleteTap,
    this.onActivateSuccess,
  });

  @override
  State<OrganizationSetupPage> createState() => _OrganizationSetupPageState();
}

class _OrganizationSetupPageState extends State<OrganizationSetupPage> {
  Future<void> _handleEditProfile() async {
    if (widget.onCompleteTap != null) {
      widget.onCompleteTap!();
      return;
    }

    final result = await context.push('/more/organization-profile/edit');
    if (mounted && (result == true || FakeOrganizationSetupData.isReadyToActivate)) {
      setState(() {});
      VToast.show(
        context,
        title: 'Thành công',
        message: 'Đã cập nhật thông tin tổ chức.',
        type: VToastType.success,
      );
    }
  }

  Future<void> _handleActivate() async {
    final confirmed = await showConfirmActivateOrganizationBottomSheet(
      context: context,
    );

    if (confirmed == true && mounted) {
      FakeOrganizationSetupData.isActivated = true;
      if (widget.onActivateSuccess != null) {
        widget.onActivateSuccess!();
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          context.go('/more/users-and-roles');
        }
        VToast.show(
          context,
          title: 'Thành công',
          message: 'Đã kích hoạt tổ chức thành công.',
          type: VToastType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isReady = FakeOrganizationSetupData.isReadyToActivate;
    final ownerName = FakeOrganizationSetupData.ownerName;
    final operatingRole = isReady ? 'Chủ tổ chức' : FakeOrganizationSetupData.operatingRole;

    return VPageScaffold(
      title: 'Hoàn tất thiết lập',
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: VButton(
          label: isReady ? 'Kích hoạt tổ chức' : 'Bổ sung thông tin tổ chức',
          variant: VButtonVariant.primary,
          tone: VComponentTone.success,
          fullWidth: true,
          onPressed: isReady ? () => _handleActivate() : () => _handleEditProfile(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        children: [
          // Banner Top: Sẵn sàng kích hoạt (chỉ hiện khi isReadyToActivate == true)
          if (isReady) ...[
            VCard(
              backgroundColor: colors.surface,
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Sẵn sàng kích hoạt',
                    variant: VTextVariant.headingH4,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const VGap.xs(),
                  VText(
                    'Các điều kiện bắt buộc đã hoàn tất. Tổ chức có thể bắt đầu vận hành.',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  const VGap.sm(),
                  const VBadge(
                    label: 'Sẵn sàng',
                    status: VBadgeStatus.success,
                  ),
                ],
              ),
            ),
            const VGap.md(),
          ],

          // Card lớn bo góc trắng chứa Điều kiện bắt buộc
          VCard(
            backgroundColor: colors.surface,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Điều kiện bắt buộc',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.md(),

                // Card 1: Hồ sơ tổ chức
                VCard(
                  backgroundColor: isReady ? colors.successBg : colors.warningBg,
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Row(
                    children: [
                      VIcon(
                        icon: isReady ? VIcons.check : VIcons.warning,
                        size: 24,
                        color: isReady ? colors.success : colors.warning,
                      ),
                      const VGap.horizontalSm(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText(
                              'Hồ sơ tổ chức',
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isReady ? colors.success : colors.warning,
                              ),
                            ),
                            const VGap.xs(),
                            VText(
                              isReady ? 'Thông tin cơ bản hợp lệ' : 'Thiếu thông tin',
                              variant: VTextVariant.bodySmall,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const VGap.sm(),

                // Card 2: Chủ sở hữu / Chủ tổ chức
                VCard(
                  backgroundColor: colors.successBg,
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Row(
                    children: [
                      VIcon(
                        icon: VIcons.check,
                        size: 24,
                        color: colors.success,
                      ),
                      const VGap.horizontalSm(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText(
                              isReady ? 'Chủ tổ chức' : 'Chủ sở hữu',
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.success,
                              ),
                            ),
                            const VGap.xs(),
                            VText(
                              ownerName,
                              variant: VTextVariant.bodySmall,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const VGap.sm(),

                // Card 3: Vai trò vận hành
                VCard(
                  backgroundColor: colors.successBg,
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Row(
                    children: [
                      VIcon(
                        icon: VIcons.check,
                        size: 24,
                        color: colors.success,
                      ),
                      const VGap.horizontalSm(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText(
                              'Vai trò vận hành',
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.success,
                              ),
                            ),
                            const VGap.xs(),
                            VText(
                              operatingRole,
                              variant: VTextVariant.bodySmall,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VGap.md(),

          // Card thông tin pháp lý
          VCard(
            backgroundColor: colors.infoBg,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VIcon(
                  icon: VIcons.info,
                  size: 20,
                  color: colors.info,
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Hồ sơ pháp lý',
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.info,
                        ),
                      ),
                      const VGap.xs(),
                      VText(
                        isReady
                            ? 'Một số tính năng pháp lý chưa khả dụng'
                            : 'Chưa khai báo mã số thuế',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
