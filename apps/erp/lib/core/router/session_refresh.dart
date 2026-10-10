import 'dart:async';

import 'package:flutter/foundation.dart';

import '../session/session_controller.dart';
import '../session/session_state.dart';

/// Báo GoRouter chạy lại guard khi đăng nhập, trạng thái "không có tổ chức" hoặc
/// quyền Platform Admin đổi.
/// Không nghe cả [SessionState] để danh sách tổ chức không kích hoạt redirect.
final sessionRefresh = SessionRefresh();

final class SessionRefresh extends ChangeNotifier {
  StreamSubscription<({AuthStatus authStatus, bool hasNoOrganization, bool isPlatformAdmin})>?
  _sub;

  void attach(SessionController controller) {
    _sub?.cancel();
    _sub = controller.stream
        .map(
          (state) => (
            authStatus: state.authStatus,
            hasNoOrganization: state.hasNoOrganization,
            isPlatformAdmin: state.isPlatformAdmin,
          ),
        )
        .distinct()
        .listen((_) {
          notifyListeners();
        });
  }
}
