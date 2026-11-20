import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/iam_fixtures.dart';

void main() {
  test('production entrypoint resolves shared production types', () {
    // Compile-time: presentation.dart must not re-export Fake* / testing paths.
    // Runtime smoke: shared production types resolve.
    const failure = IamUiFailure(
      code: IamBlockedCodes.systemError,
      message: 'x',
      retryable: true,
    );
    expect(failure.code, IamBlockedCodes.systemError);

    final mapped = IamUiFailureMapper.from(
      const AppException(IamBlockedCodes.stateChanged),
    );
    expect(mapped.requiresReload, isTrue);

    final key = const UuidIdempotencyKeyFactory().next('invite');
    expect(key.startsWith('invite-'), isTrue);
    expect(key.length, greaterThan('invite-'.length));
  });

  test('test fixtures stay deterministic', () {
    expect(FakeUsersData.sampleMembers, isNotEmpty);
    expect(FakeRolesData.sampleRoles, isNotEmpty);
    expect(FakeIdempotencyKeyFactory().next('create'), 'create-test-idempotency-key');
  });
}
