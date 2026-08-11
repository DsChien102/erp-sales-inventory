import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  final sample = TenantMemberDetailDto(
    membershipId: 'm-1',
    tenantId: 't-1',
    userId: 'u-1',
    role: 'staff',
    isOwner: false,
    isSoleOwner: false,
    status: MembershipStatus.active,
    version: 1,
    joinedAt: DateTime.utc(2026, 1, 1),
  );

  group('scn_e03_u05_fr01_01 membership lifecycle handlers', () {
    test('GetTenantMemberQuery returns detail', () async {
      final gateway = _RecordingReadGateway(sample);
      final handler = GetTenantMemberQueryHandler(readGateway: gateway);
      final result = await handler.handle(
        GetTenantMemberQuery(tenantId: 't-1', membershipId: 'm-1'),
      );
      expect(result.membershipId, 'm-1');
      expect(gateway.calls, 1);
    });

    test('GetTenantMemberQuery throws RESOURCE_NOT_FOUND', () async {
      final handler = GetTenantMemberQueryHandler(
        readGateway: _RecordingReadGateway(null),
      );
      expect(
        () => handler.handle(
          GetTenantMemberQuery(tenantId: 't-1', membershipId: 'missing'),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.resourceNotFound,
          ),
        ),
      );
    });

    test('DeactivateMembershipCommand delegates to gateway', () async {
      final gateway = _RecordingCommandGateway(
        sample.copyWith(status: MembershipStatus.inactive, version: 2),
      );
      final handler = DeactivateMembershipCommandHandler(
        commandGateway: gateway,
      );
      final result = await handler.handle(
        DeactivateMembershipCommand(
          tenantId: 't-1',
          membershipId: 'm-1',
          expectedVersion: 1,
        ),
      );
      expect(result.status, MembershipStatus.inactive);
      expect(gateway.lastOp, 'deactivate');
    });

    test('ReactivateMembershipCommand delegates to gateway', () async {
      final gateway = _RecordingCommandGateway(sample);
      final handler = ReactivateMembershipCommandHandler(
        commandGateway: gateway,
      );
      await handler.handle(
        ReactivateMembershipCommand(
          tenantId: 't-1',
          membershipId: 'm-1',
          expectedVersion: 2,
        ),
      );
      expect(gateway.lastOp, 'reactivate');
    });

    test('RemoveMembershipCommand delegates to gateway', () async {
      final gateway = _RecordingCommandGateway(
        sample.copyWith(status: MembershipStatus.removed, version: 2),
      );
      final handler = RemoveMembershipCommandHandler(commandGateway: gateway);
      final result = await handler.handle(
        RemoveMembershipCommand(
          tenantId: 't-1',
          membershipId: 'm-1',
          expectedVersion: 1,
        ),
      );
      expect(result.status, MembershipStatus.removed);
      expect(gateway.lastOp, 'remove');
    });

    test('member_state_changed — STATE_CHANGED from gateway', () async {
      final handler = DeactivateMembershipCommandHandler(
        commandGateway: _ThrowingCommandGateway(
          const IamBlockedException(IamBlockedCodes.stateChanged),
        ),
      );
      expect(
        () => handler.handle(
          DeactivateMembershipCommand(
            tenantId: 't-1',
            membershipId: 'm-1',
            expectedVersion: 1,
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.stateChanged,
          ),
        ),
      );
    });

    test('member_forbidden — PERMISSION_DENIED from gateway', () async {
      final handler = RemoveMembershipCommandHandler(
        commandGateway: _ThrowingCommandGateway(
          const IamBlockedException(IamBlockedCodes.permissionDenied),
        ),
      );
      expect(
        () => handler.handle(
          RemoveMembershipCommand(
            tenantId: 't-1',
            membershipId: 'm-1',
            expectedVersion: 1,
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.permissionDenied,
          ),
        ),
      );
    });
  });
}

extension on TenantMemberDetailDto {
  TenantMemberDetailDto copyWith({
    MembershipStatus? status,
    int? version,
  }) {
    return TenantMemberDetailDto(
      membershipId: membershipId,
      tenantId: tenantId,
      userId: userId,
      role: role,
      isOwner: isOwner,
      isSoleOwner: isSoleOwner,
      status: status ?? this.status,
      version: version ?? this.version,
      joinedAt: joinedAt,
      statusChangedAt: statusChangedAt,
      removedAt: removedAt,
    );
  }
}

final class _RecordingReadGateway implements ITenantMembershipReadGateway {
  _RecordingReadGateway(this.member);

  final TenantMemberDetailDto? member;
  int calls = 0;

  @override
  Future<TenantMemberDetailDto?> getMember({
    required String tenantId,
    required String membershipId,
  }) async {
    calls += 1;
    return member;
  }
}

final class _RecordingCommandGateway
    implements ITenantMembershipCommandGateway {
  _RecordingCommandGateway(this.result);

  final TenantMemberDetailDto result;
  String? lastOp;

  @override
  Future<TenantMemberDetailDto> deactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) async {
    lastOp = 'deactivate';
    return result;
  }

  @override
  Future<TenantMemberDetailDto> reactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) async {
    lastOp = 'reactivate';
    return result;
  }

  @override
  Future<TenantMemberDetailDto> remove({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) async {
    lastOp = 'remove';
    return result;
  }
}

final class _ThrowingCommandGateway
    implements ITenantMembershipCommandGateway {
  _ThrowingCommandGateway(this.error);

  final Object error;

  @override
  Future<TenantMemberDetailDto> deactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) async {
    throw error;
  }

  @override
  Future<TenantMemberDetailDto> reactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) async {
    throw error;
  }

  @override
  Future<TenantMemberDetailDto> remove({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) async {
    throw error;
  }
}
