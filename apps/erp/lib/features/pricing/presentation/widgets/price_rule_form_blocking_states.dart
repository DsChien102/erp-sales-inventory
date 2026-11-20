import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// D-09 SG-03 — Không có quyền sửa/tạo giá riêng (full-screen state).
class PriceRuleFormNoPermissionState extends StatelessWidget {
  const PriceRuleFormNoPermissionState({
    super.key,
    required this.isEdit,
    required this.onClose,
  });

  final bool isEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: VEmptyState(
        icon: VIcons.lock,
        tone: VComponentTone.primary,
        title: isEdit
            ? 'Bạn không có quyền sửa giá riêng'
            : 'Bạn không có quyền tạo giá riêng',
        description: isEdit
            ? 'Liên hệ quản trị viên nếu bạn cần quyền chỉnh sửa giá riêng.'
            : 'Liên hệ quản trị viên nếu bạn cần quyền tạo giá riêng.',
        actionLabel: 'Đóng',
        onActionPressed: onClose,
      ),
    );
  }
}

/// D-09 SG-03 — Rule đã thay đổi bởi người khác (full-screen state).
class PriceRuleFormStateChangedState extends StatelessWidget {
  const PriceRuleFormStateChangedState({
    super.key,
    required this.onReload,
  });

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: VEmptyState(
        icon: VIcons.refresh,
        tone: VComponentTone.warning,
        title: 'Giá riêng đã được cập nhật',
        description:
            'Giá riêng này vừa được cập nhật bởi người khác. '
            'Vui lòng tải lại trước khi sửa.',
        actionLabel: 'Tải lại',
        onActionPressed: onReload,
      ),
    );
  }
}
