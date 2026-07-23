import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Advanced filter bottom sheet for platform users list.
Future<({int status, int activation, int email})?> showPlatformUsersFilterSheet({
  required BuildContext context,
  required int filterStatus,
  required int filterActivation,
  required int filterEmail,
}) {
  int tempStatus = filterStatus;
  int tempActivation = filterActivation;
  int tempEmail = filterEmail;

  return showVBottomSheet<({int status, int activation, int email})>(
    context: context,
    child: StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                'Bộ lọc người dùng nền tảng',
                variant: VTextVariant.headingH3,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.lg(),
              VText(
                'Trạng thái',
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                children: [
                  VChip(
                    label: 'Tất cả',
                    emphasis: tempStatus == 0
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempStatus = 0),
                  ),
                  VChip(
                    label: 'Hoạt động',
                    emphasis: tempStatus == 1
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempStatus = 1),
                  ),
                  VChip(
                    label: 'Tạm ngừng',
                    emphasis: tempStatus == 2
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempStatus = 2),
                  ),
                ],
              ),
              const VGap.lg(),
              VText(
                'Kích hoạt',
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                children: [
                  VChip(
                    label: 'Tất cả',
                    emphasis: tempActivation == 0
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempActivation = 0),
                  ),
                  VChip(
                    label: 'Đã kích hoạt',
                    emphasis: tempActivation == 1
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempActivation = 1),
                  ),
                  VChip(
                    label: 'Chờ kích hoạt',
                    emphasis: tempActivation == 2
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempActivation = 2),
                  ),
                  VChip(
                    label: 'Hết hạn',
                    emphasis: tempActivation == 3
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempActivation = 3),
                  ),
                ],
              ),
              const VGap.lg(),
              VText(
                'Email',
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                children: [
                  VChip(
                    label: 'Tất cả',
                    emphasis: tempEmail == 0
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempEmail = 0),
                  ),
                  VChip(
                    label: 'Đã xác minh',
                    emphasis: tempEmail == 1
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempEmail = 1),
                  ),
                  VChip(
                    label: 'Chưa xác minh',
                    emphasis: tempEmail == 2
                        ? VComponentEmphasis.strong
                        : VComponentEmphasis.medium,
                    onTap: () => setSheetState(() => tempEmail = 2),
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
                      onPressed: () {
                        setSheetState(() {
                          tempStatus = 0;
                          tempActivation = 0;
                          tempEmail = 0;
                        });
                      },
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VButton(
                      label: 'Áp dụng',
                      onPressed: () {
                        Navigator.pop(
                          context,
                          (
                            status: tempStatus,
                            activation: tempActivation,
                            email: tempEmail,
                          ),
                        );
                      },
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
