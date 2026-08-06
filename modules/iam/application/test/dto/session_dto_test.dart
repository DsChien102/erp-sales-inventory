import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  group('SessionDto.hasPermission', () {
    test('owner bypasses via isOwner regardless of role', () {
      const owner = SessionDto(
        isAuthenticated: true,
        role: 'accountant',
        isOwner: true,
        permissions: [],
      );
      expect(owner.hasPermission('anything.at.all'), isTrue);
    });

    test('non-owner is limited to mapped permissions', () {
      const member = SessionDto(
        isAuthenticated: true,
        role: 'accountant',
        isOwner: false,
        permissions: ['x.read'],
      );
      expect(member.hasPermission('x.read'), isTrue);
      expect(member.hasPermission('x.write'), isFalse);
    });

    test('role value is never a bypass (no role OWNER)', () {
      const notOwner = SessionDto(
        isAuthenticated: true,
        role: 'store_owner',
        permissions: [],
      );
      expect(notOwner.hasPermission('anything'), isFalse);
    });
  });
}
