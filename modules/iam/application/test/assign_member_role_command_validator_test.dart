import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('AssignMemberRoleCommandValidator', () {
    final validator = AssignMemberRoleCommandValidator();

    test('accepts owner and staff roles', () async {
      for (final role in AssignMemberRoleRules.allowedRoleValues) {
        await validator.validate(
          AssignMemberRoleCommand(
            tenantId: 'tenant-1',
            userId: 'user-1',
            role: role,
          ),
        );
      }
    });

    test('rejects unknown role', () async {
      await expectLater(
        validator.validate(
          AssignMemberRoleCommand(
            tenantId: 'tenant-1',
            userId: 'user-1',
            role: 'admin',
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
