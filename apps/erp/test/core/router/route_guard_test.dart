import 'package:erp/core/session/session_state.dart';
import 'package:erp/core/router/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionState session(AuthStatus status) => SessionState(authStatus: status);

  test('signedOut on a private route goes to login', () {
    expect(routeGuard(session: session(AuthStatus.signedOut), location: '/'), '/login');
  });

  test('signedOut stays on public routes', () {
    for (final location in ['/login', '/login/reset-password', '/invitation']) {
      expect(
        routeGuard(session: session(AuthStatus.signedOut), location: location),
        isNull,
        reason: location,
      );
    }
  });

  test('signedIn on login routes goes home, including reset-password', () {
    expect(routeGuard(session: session(AuthStatus.signedIn), location: '/login'), '/');
    expect(
      routeGuard(session: session(AuthStatus.signedIn), location: '/login/reset-password'),
      '/',
    );
  });

  test('signedIn stays on app routes and invitation', () {
    for (final location in ['/', '/partner', '/invitation']) {
      expect(
        routeGuard(session: session(AuthStatus.signedIn), location: location),
        isNull,
        reason: location,
      );
    }
  });

  test('signedOut stays on signup and verify-email', () {
    expect(
      routeGuard(session: session(AuthStatus.signedOut), location: '/signup'),
      isNull,
    );
    expect(
      routeGuard(session: session(AuthStatus.signedOut), location: '/verify-email'),
      isNull,
    );
  });

  test('signedOut on no-organization goes to login', () {
    expect(
      routeGuard(session: session(AuthStatus.signedOut), location: '/no-organization'),
      '/login',
    );
  });

  test('signedIn on signup and verify-email goes home', () {
    expect(routeGuard(session: session(AuthStatus.signedIn), location: '/signup'), '/');
    expect(
      routeGuard(session: session(AuthStatus.signedIn), location: '/verify-email'),
      '/',
    );
  });

  test('signedIn without an organization goes to no-organization except invitation', () {
    const blocked = SessionState(
      authStatus: AuthStatus.signedIn,
      status: TenantLoadStatus.blocked,
      emptyStateType: OrganizationEmptyStateType.noAuthorizedOrganizations,
    );
    expect(routeGuard(session: blocked, location: '/'), '/no-organization');
    expect(routeGuard(session: blocked, location: '/no-organization'), isNull);
    expect(routeGuard(session: blocked, location: '/invitation'), isNull);
    expect(routeGuard(session: blocked, location: '/invitation/x'), isNull);
  });

  test('signedIn with an organization leaves no-organization', () {
    expect(
      routeGuard(session: session(AuthStatus.signedIn), location: '/no-organization'),
      '/',
    );
  });

  test('unknown auth leaves every location alone', () {
    for (final location in ['/', '/login', '/partner', '/invitation']) {
      expect(
        routeGuard(session: session(AuthStatus.unknown), location: location),
        isNull,
        reason: location,
      );
    }
  });
}
