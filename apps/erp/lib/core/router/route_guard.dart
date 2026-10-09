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

/// Guard thuần. `null` = ở lại [location].
///
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
      if (_isAuthEntry(location)) return '/';
      if (session.hasNoOrganization) {
        return _staysWithoutOrganization(location) ? null : '/no-organization';
      }
      if (location == '/no-organization') return '/';
      return null;
  }
}
