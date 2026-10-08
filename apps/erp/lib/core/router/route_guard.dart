import '../session/session_state.dart';

// 2-B1 thêm '/signup', '/verify-email'.
const _publicPrefixes = ['/login', '/invitation'];

/// Guard thuần. `null` = ở lại [location].
///
/// 2-B1: email chưa xác minh → '/verify-email'; không có membership → '/no-organization'.
/// P8: platform admin không có membership → '/admin'.
String? routeGuard({required SessionState session, required String location}) {
  final isPublic = _publicPrefixes.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );
  switch (session.authStatus) {
    case AuthStatus.unknown:
      return null;
    case AuthStatus.signedOut:
      return isPublic ? null : '/login';
    case AuthStatus.signedIn:
      if (location == '/login' || location.startsWith('/login/')) return '/';
      return null;
  }
}
