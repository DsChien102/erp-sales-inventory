import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _ScriptedIamModule implements IIamModule {
  _ScriptedIamModule({required this.onCommand, required this.onQuery});

  final Future<Object?> Function(Object message) onCommand;
  final Future<Object?> Function(Object message) onQuery;

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    return await onCommand(command) as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return await onQuery(query) as TResult;
  }
}

void main() {
  test('loads members and preserves nextCursor', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.membersSearchOk),
    );
    final cubit = OrganizationUsersCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.members, isNotEmpty);
    expect(cubit.state.memberStatus, IamLoadStatus.success);
    final query = module.queriesOf<ListTenantMembersQuery>().single;
    expect(query.tenantId, 'org-001');
    await cubit.close();
  });

  test('forbidden emits typed permission failure', () async {
    final cubit = OrganizationUsersCubit(
      iamModule: FakeIamModule(
        scenario: FakeIamScenario.memberInvitationForbidden,
      ),
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.memberFailure?.code, IamBlockedCodes.permissionDenied);
    await cubit.close();
  });

  test('page 2 receives exact cursor from page 1', () async {
    var page = 0;
    final scripted = _ScriptedIamModule(
      onCommand: (message) async => throw UnsupportedError(message.runtimeType.toString()),
      onQuery: (message) async {
        if (message is! ListTenantMembersQuery) {
          throw UnsupportedError(message.runtimeType.toString());
        }
        page += 1;
        if (page == 1) {
          expect(message.cursor, isNull);
          return CursorPageDto<TenantMemberDto>(
            items: [
              TenantMemberDto(
                membershipId: 'm-1',
                userId: 'u-1',
                displayName: 'A',
                email: 'a@example.com',
                roleId: 'r1',
                roleLabel: 'Staff',
                isOwner: false,
                status: 'active',
                joinedAt: DateTime.utc(2026, 1, 1),
                version: 1,
              ),
            ],
            nextCursor: 'cursor-page-1',
          );
        }
        expect(message.cursor, 'cursor-page-1');
        return CursorPageDto<TenantMemberDto>(
          items: [
            TenantMemberDto(
              membershipId: 'm-2',
              userId: 'u-2',
              displayName: 'B',
              email: 'b@example.com',
              roleId: 'r1',
              roleLabel: 'Staff',
              isOwner: false,
              status: 'active',
              joinedAt: DateTime.utc(2026, 2, 1),
              version: 1,
            ),
          ],
        );
      },
    );
    final module = RecordingIamModule(scripted);
    final cubit = OrganizationUsersCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.memberNextCursor, 'cursor-page-1');
    await cubit.loadNextMembersPage();
    expect(cubit.state.members.map((m) => m.id), ['m-1', 'm-2']);
    expect(cubit.state.memberNextCursor, isNull);
    await cubit.close();
  });

  test('always places owner at the top of the member list', () async {
    final scripted = _ScriptedIamModule(
      onCommand: (message) async => throw UnsupportedError(message.runtimeType.toString()),
      onQuery: (message) async {
        return CursorPageDto<TenantMemberDto>(
          items: [
            TenantMemberDto(
              membershipId: 'm-regular',
              userId: 'u-reg',
              displayName: 'Nguyen Duong',
              email: 'dn200422@gmail.com',
              roleId: 'accountant',
              roleLabel: 'Kế toán',
              isOwner: false,
              status: 'active',
              joinedAt: DateTime.utc(2026, 1, 1),
              version: 1,
            ),
            TenantMemberDto(
              membershipId: 'm-owner',
              userId: 'u-owner',
              displayName: 'Đỗ Sỹ Chiến',
              email: 'dosychien9@gmail.com',
              roleId: 'store_owner',
              roleLabel: 'Chủ cửa hàng',
              isOwner: true,
              status: 'active',
              joinedAt: DateTime.utc(2026, 1, 2),
              version: 1,
            ),
          ],
        );
      },
    );
    final cubit = OrganizationUsersCubit(
      iamModule: scripted,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.members.first.id, 'm-owner');
    expect(cubit.state.members.first.isOwner, isTrue);
    expect(cubit.state.members.last.id, 'm-regular');
    await cubit.close();
  });
}
