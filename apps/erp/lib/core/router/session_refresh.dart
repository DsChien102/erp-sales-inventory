import 'dart:async';

import 'package:flutter/foundation.dart';

import '../session/session_controller.dart';
import '../session/session_state.dart';

/// Báo GoRouter chạy lại guard khi [AuthStatus] đổi.
/// Chỉ nghe authStatus để danh sách tổ chức không kích hoạt redirect.
final sessionRefresh = SessionRefresh();

final class SessionRefresh extends ChangeNotifier {
  StreamSubscription<AuthStatus>? _sub;

  void attach(SessionController controller) {
    _sub?.cancel();
    _sub = controller.stream.map((state) => state.authStatus).distinct().listen((_) {
      notifyListeners();
    });
  }
}
