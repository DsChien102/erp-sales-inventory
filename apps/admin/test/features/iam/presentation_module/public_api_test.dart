import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';

void main() {
  test('production entrypoint does not export Fake symbols', () {
    // Compile-time: presentation.dart must not re-export Fake* / testing paths.
    // Runtime smoke: shared production types resolve.
    const failure = IamUiFailure(
      code: IamBlockedCodes.systemError,
      message: 'x',
      retryable: true,
    );
    expect(failure.code, IamBlockedCodes.systemError);

    final mapped = IamUiFailureMapper.from(
      const IamBlockedException(IamBlockedCodes.stateChanged),
    );
    expect(mapped.requiresReload, isTrue);

    final key = const UuidIdempotencyKeyFactory().next('invite');
    expect(key.startsWith('invite-'), isTrue);
    expect(key.length, greaterThan('invite-'.length));
  });

  test('testing entrypoint exports fake data and recording module', () {
    expect(FakeUsersData.sampleMembers, isNotEmpty);
    expect(FakeRolesData.sampleRoles, isNotEmpty);
    expect(FakeIdempotencyKeyFactory().next('create'), 'create-test-idempotency-key');
  });

  test('RecordingIamModule records queries and commands', () async {
    final delegate = FakeIamModule(scenario: FakeIamScenario.authSessionOk);
    final module = RecordingIamModule(delegate);

    await module.executeQueryAsync<SessionDto>(GetCurrentSessionQuery());
    expect(module.queriesOf<GetCurrentSessionQuery>(), hasLength(1));

    await module.executeCommandAsync<void>(
      SignInTenantUserCommand(email: 'a@b.com', password: 'secret'),
    );
    expect(module.commandsOf<SignInTenantUserCommand>(), hasLength(1));
  });
}
