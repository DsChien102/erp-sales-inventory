import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

import 'support/stub_platform_admin_gateway.dart';

final class _FakePlatformGateway extends StubPlatformAdminGateway {
  _FakePlatformGateway({
    List<PlatformUserSummaryDto>? summaries,
    this.detail,
  }) : summaries = summaries ?? const [];

  final List<PlatformUserSummaryDto> summaries;
  final PlatformUserDetailDto? detail;

  String? lastSearchQuery;
  PlatformUserStatus? lastSearchStatus;

  @override
  Future<bool> hasPlatformPermission(String permission) async => true;

  @override
  Future<CursorPageDto<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
    String? cursor,
    int limit = 20,
  }) async {
    lastSearchQuery = query;
    lastSearchStatus = status;
    return CursorPageDto(items: summaries);
  }

  @override
  Future<PlatformUserDetailDto> getPlatformUser(String userId) async {
    return detail ??
        PlatformUserDetailDto(
          userId: userId,
          fullName: 'User',
          email: 'u@example.com',
          status: PlatformUserStatus.active,
          emailVerified: true,
          createdAt: DateTime.utc(2026, 1, 1),
          version: 1,
        );
  }
}

void main() {
  group('scn_e01_u01_fr01_01 platform users', () {
    test('users_search_ok — SearchPlatformUsersQuery returns cursor page', () async {
      final gateway = _FakePlatformGateway(
        summaries: [
          PlatformUserSummaryDto(
            userId: 'u-1',
            fullName: 'Nguyen A',
            email: 'a@vet45.local',
            status: PlatformUserStatus.active,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      final handler = SearchPlatformUsersQueryHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        SearchPlatformUsersQuery(
          query: 'a@vet45',
          status: PlatformUserStatus.active,
        ),
      );

      expect(gateway.lastSearchQuery, 'a@vet45');
      expect(gateway.lastSearchStatus, PlatformUserStatus.active);
      expect(result.items, hasLength(1));
      expect(result.items.single.email, 'a@vet45.local');
    });

    test('user_detail_ok — GetPlatformUserQuery maps memberships + version', () async {
      final gateway = _FakePlatformGateway(
        detail: PlatformUserDetailDto(
          userId: 'u-1',
          fullName: 'Nguyen A',
          email: 'a@vet45.local',
          status: PlatformUserStatus.active,
          emailVerified: true,
          createdAt: DateTime.utc(2026, 1, 1),
          version: 3,
          memberships: const [
            PlatformUserMembershipDto(
              tenantId: 't-1',
              tenantName: 'Store',
              roleLabel: 'owner',
              isOwner: true,
            ),
          ],
        ),
      );
      final handler = GetPlatformUserQueryHandler(platformGateway: gateway);

      final result = await handler.handle(
        GetPlatformUserQuery(userId: 'u-1'),
      );

      expect(result.version, 3);
      expect(result.memberships.single.isOwner, isTrue);
    });

    test('rejects invalid page limit', () async {
      final handler = SearchPlatformUsersQueryHandler(
        platformGateway: _FakePlatformGateway(),
      );
      expect(
        () => handler.handle(SearchPlatformUsersQuery(limit: 0)),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.validationError,
          ),
        ),
      );
    });
  });
}
