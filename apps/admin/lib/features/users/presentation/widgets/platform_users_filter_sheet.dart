import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

typedef PlatformUsersFilterResult = ({
  bool applied,
  PlatformUserStatus? status,
});

/// Status-only filter sheet for platform users list (contract: query + status).
Future<PlatformUsersFilterResult?> showPlatformUsersFilterSheet({
  required BuildContext context,
  PlatformUserStatus? selected,
}) {
  PlatformUserStatus? temp = selected;

  return showVBottomSheet<PlatformUsersFilterResult>(
    context: context,
    child: StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VText(
                'Bộ lọc người dùng nền tảng',
                variant: VTextVariant.headingH3,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.lg(),
              const VText(
                'Trạng thái',
                variant: VTextVariant.bodyDefault,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  VChip(
                    label: 'Tất cả',
                    emphasis: temp == null
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => temp = null),
                  ),
                  VChip(
                    label: 'Chờ kích hoạt',
                    emphasis: temp == PlatformUserStatus.pendingActivation
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(
                      () => temp = PlatformUserStatus.pendingActivation,
                    ),
                  ),
                  VChip(
                    label: 'Hoạt động',
                    emphasis: temp == PlatformUserStatus.active
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () =>
                        setSheetState(() => temp = PlatformUserStatus.active),
                  ),
                  VChip(
                    label: 'Tạm ngừng',
                    emphasis: temp == PlatformUserStatus.suspended
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(
                      () => temp = PlatformUserStatus.suspended,
                    ),
                  ),
                ],
              ),
              const VGap.xl(),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Đặt lại',
                      variant: VButtonVariant.outline,
                      onPressed: () => setSheetState(() => temp = null),
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VButton(
                      label: 'Áp dụng',
                      onPressed: () => Navigator.pop(
                        context,
                        (applied: true, status: temp),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
