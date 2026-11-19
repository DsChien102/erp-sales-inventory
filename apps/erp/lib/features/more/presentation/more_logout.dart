import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/session/session_controller.dart';

/// Signs out the current session and navigates back to `/login`.
///
/// Shared between [MorePage] and [ErpSideNavigation].
Future<void> signOutAndGoToLogin(BuildContext context) async {
  try {
    final result = await getIt<SessionController>().signOut();
    if (!context.mounted) return;
    if (!result.localCleared) {
      VToast.show(
        context,
        title: 'Đăng xuất thất bại',
        message: 'Không thể đóng phiên trên máy.',
        type: VToastType.danger,
      );
      return;
    }
    if (!result.remoteSucceeded) {
      VToast.show(
        context,
        title: 'Cảnh báo',
        message: 'Phiên trên máy đã đóng; máy chủ chưa xác nhận đăng xuất',
        type: VToastType.warning,
      );
    }
    context.go('/login');
  } on AppException catch (error) {
    if (!context.mounted) return;
    VToast.show(
      context,
      title: 'Đăng xuất thất bại',
      message: error.userMessage(),
      type: VToastType.danger,
    );
  }
}
