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
