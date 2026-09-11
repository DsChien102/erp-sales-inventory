import 'package:admin/features/organizations/presentation/bloc/platform_onboarding_cubit.dart';
import 'package:admin/features/organizations/presentation/bloc/platform_onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';

void main() {
  test('searchOwners only requests active platform users', () async {
    final module = FakeIamModule();
    final cubit = PlatformOnboardingCubit(iamModule: module);

    await cubit.searchOwners('');

    expect(cubit.state.status, PlatformOnboardingLoadStatus.idle);
    expect(
      cubit.state.searchResults.every((u) => u.status == PlatformUserStatus.active),
      isTrue,
    );
    expect(
      cubit.state.searchResults.any((u) => u.email == 'hoa@gmail.com'),
      isFalse,
    );
    expect(
      cubit.state.searchResults.any((u) => u.email == 'minh@gmail.com'),
      isFalse,
    );
    expect(
      cubit.state.searchResults.any((u) => u.email == 'lan@gmail.com'),
      isTrue,
    );

    await cubit.close();
  });

  group('checkEmailExists', () {
    test('returns true for existing active user', () async {
      final module = FakeIamModule();
      final cubit = PlatformOnboardingCubit(iamModule: module);

      final exists = await cubit.checkEmailExists('lan@gmail.com');
      expect(exists, isTrue);

      await cubit.close();
    });

    test('returns true for existing pending/non-active user', () async {
      final module = FakeIamModule();
      final cubit = PlatformOnboardingCubit(iamModule: module);

      final exists = await cubit.checkEmailExists('hoa@gmail.com');
      expect(exists, isTrue);

      await cubit.close();
    });

    test('returns false for non-existent email', () async {
      final module = FakeIamModule();
      final cubit = PlatformOnboardingCubit(iamModule: module);

      final exists = await cubit.checkEmailExists('nonexistent@vet45.com');
      expect(exists, isFalse);

      await cubit.close();
    });

    test('returns false for empty email', () async {
      final module = FakeIamModule();
      final cubit = PlatformOnboardingCubit(iamModule: module);

      final exists = await cubit.checkEmailExists('');
      expect(exists, isFalse);

      await cubit.close();
    });

    test('returns null when query throws an exception (fail-closed)', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.userForbidden403);
      final cubit = PlatformOnboardingCubit(iamModule: module);

      final exists = await cubit.checkEmailExists('lan@gmail.com');
      expect(exists, isNull);

      await cubit.close();
    });
  });
}
