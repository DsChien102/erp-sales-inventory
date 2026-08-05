import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import 'package:vet45_iam_infrastructure/src/configuration/processing/generated/iam_access_metadata.g.dart';

class _RecordingAccessGateway implements IIamAccessGateway {
  var assignCalled = false;

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {
    assignCalled = true;
  }

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async => null;

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => true;

  @override
  Future<bool> isMember(String tenantId) async => true;

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError('S2 BE');

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError('S3 BE');

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];
}

class _ThrowingAccessGateway implements IIamAccessGateway {
  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {
    throw StateError('handler should not run');
  }

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async => null;

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => true;

  @override
  Future<bool> isMember(String tenantId) async => true;

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError('S2 BE');

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError('S3 BE');

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];
}

void main() {
  group('IamCommandPipeline', () {
    test('requires permission before AssignMemberRole handler', () async {
      final permissionChecker = FakePermissionChecker();
      final gateway = _RecordingAccessGateway();
      final container = GetIt.asNewInstance()
        ..registerSingleton<IAccessMetadataRegistry>(iamAccessMetadataRegistry)
        ..registerSingleton<IPermissionChecker>(permissionChecker)
        ..registerSingleton<ITenantAccessChecker>(FakeTenantAccessChecker());

      final pipeline =
          IamCommandPipeline.buildBusinessPipeline<
            AssignMemberRoleCommand,
            void,
            AssignMemberRoleCommandHandler
          >(
            container: container,
            handler: AssignMemberRoleCommandHandler(
              accessGateway: gateway,
            ),
            invoke: (command, handler) => handler.handle(command),
          );

      await pipeline(
        AssignMemberRoleCommand(
          tenantId: 'tenant-1',
          userId: 'user-2',
          role: 'staff',
        ),
      );

      expect(permissionChecker.required, [IamPermissions.membersAssignRole]);
      expect(gateway.assignCalled, isTrue);
    });

    test('denies AssignMemberRole when permission checker rejects', () async {
      final container = GetIt.asNewInstance()
        ..registerSingleton<IAccessMetadataRegistry>(iamAccessMetadataRegistry)
        ..registerSingleton<IPermissionChecker>(
          FakePermissionChecker(deny: {IamPermissions.membersAssignRole}),
        )
        ..registerSingleton<ITenantAccessChecker>(FakeTenantAccessChecker());

      final pipeline =
          IamCommandPipeline.buildBusinessPipeline<
            AssignMemberRoleCommand,
            void,
            AssignMemberRoleCommandHandler
          >(
            container: container,
            handler: AssignMemberRoleCommandHandler(
              accessGateway: _ThrowingAccessGateway(),
            ),
            invoke: (command, handler) => handler.handle(command),
          );

      await expectLater(
        pipeline(
          AssignMemberRoleCommand(
            tenantId: 'tenant-1',
            userId: 'user-2',
            role: 'staff',
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });
  });
}
