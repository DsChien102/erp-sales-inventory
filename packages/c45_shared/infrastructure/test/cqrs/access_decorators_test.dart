import 'package:test/test.dart';
import 'package:c45_shared_application/application.dart';
import 'package:c45_shared_infrastructure/infrastructure.dart';

void main() {
  group('AuthorizationCommandHandlerDecorator', () {
    test('requires permission before handler', () async {
      final checker = _RecordingPermissionChecker();
      var handlerRan = false;

      final decorator = AuthorizationCommandHandlerDecorator<_Cmd, void>(
        permissionChecker: checker,
        permissionCode: 'tasks.write',
        inner: (_) async {
          handlerRan = true;
        },
      );

      await decorator.handleCommand(_Cmd('1'));

      expect(handlerRan, isTrue);
      expect(checker.required, ['tasks.write']);
    });
  });

  group('TenantGuardCommandHandlerDecorator', () {
    test('checks tenant for scoped commands', () async {
      final checker = _RecordingTenantChecker();
      var handlerRan = false;

      final decorator = TenantGuardCommandHandlerDecorator<_TenantCmd, void>(
        tenantAccessChecker: checker,
        inner: (_) async {
          handlerRan = true;
        },
      );

      await decorator.handleCommand(_TenantCmd('1', tenantId: 'tenant-1'));

      expect(handlerRan, isTrue);
      expect(checker.checked, ['tenant-1']);
    });
  });
}

final class _Cmd extends CommandBase<void> {
  _Cmd(super.id);
}

final class _TenantCmd extends CommandBase<void> implements ITenantScopedCommand {
  _TenantCmd(super.id, {required this.tenantId});

  @override
  final String tenantId;
}

final class _RecordingPermissionChecker implements IPermissionChecker {
  final List<String> required = [];

  @override
  Future<void> require(String permissionCode) async {
    required.add(permissionCode);
  }
}

final class _RecordingTenantChecker implements ITenantAccessChecker {
  final List<String> checked = [];

  @override
  Future<void> ensureAccess(String tenantId) async {
    checked.add(tenantId);
  }
}
