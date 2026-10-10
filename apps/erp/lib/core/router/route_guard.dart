import '../session/session_state.dart';

const _publicPrefixes = ['/login', '/invitation', '/signup', '/verify-email'];

bool _isAuthEntry(String location) {
  return location == '/login' ||
      location.startsWith('/login/') ||
      location == '/signup' ||
      location.startsWith('/signup/') ||
      location == '/verify-email' ||
      location.startsWith('/verify-email/');
}

bool _staysWithoutOrganization(String location) {
  return location == '/no-organization' ||
      location == '/invitation' ||
      location.startsWith('/invitation/');
}

/// Khu "Quản trị nền tảng" trong tab Thêm (chỉ Platform Admin).
bool _isPlatformArea(String location) {
  return location == '/more/platform' || location.startsWith('/more/platform/');
}

/// Guard thuần. `null` = ở lại [location].
///
/// G5: không có tổ chức → `/no-organization` (trừ `/invitation`; Platform Admin
/// được vào `/more/platform/**`). G7: ngoài Platform Admin không vào khu đó.
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
      if (_isAuthEntry(location)) return '/';
      if (session.hasNoOrganization) {
        if (_staysWithoutOrganization(location)) return null;
        if (session.isPlatformAdmin && _isPlatformArea(location)) return null;
        return '/no-organization';
      }
      if (location == '/no-organization') return '/';
      if (_isPlatformArea(location) && !session.isPlatformAdmin) return '/';
      return null;
  }
}
