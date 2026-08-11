import 'package:erp/features/auth/data/owner_activation_client.dart';
import 'package:erp/features/auth/presentation/bloc/owner_activation_cubit.dart';
import 'package:erp/features/auth/presentation/bloc/owner_activation_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeClient implements OwnerActivationClient {
  _FakeClient({this.inspectValid = true, this.activateThrows = false});

  final bool inspectValid;
  final bool activateThrows;
  String? activatedCode;
  String? activatedEmail;
  String? activatedPassword;

  @override
  Future<OwnerActivationInspection> inspect(String code) async {
    return OwnerActivationInspection(
      valid: inspectValid,
      email: inspectValid ? 'owner@example.com' : null,
      givenName: 'An',
      familyName: 'Nguyen',
    );
  }

  bool? activatedAccountExists;

  @override
  Future<void> activate({
    required String code,
    required String email,
    required String password,
    required bool accountExists,
    String? givenName,
    String? familyName,
    String? phone,
    required String idempotencyKey,
  }) async {
    if (activateThrows) throw const OwnerActivationClientException();
    activatedCode = code;
    activatedEmail = email;
    activatedPassword = password;
    activatedAccountExists = accountExists;
  }
}

OwnerActivationCubit _cubit(OwnerActivationClient client) =>
    OwnerActivationCubit(client: client, idempotencyKey: 'k-1');

void main() {
  group('OwnerActivationCubit', () {
    test('inspects then activates on success', () async {
      final client = _FakeClient();
      final cubit = _cubit(client);

      await cubit.submit(code: 'ABCD2345', password: 'Password123!');

      expect(client.activatedCode, 'ABCD2345');
      expect(client.activatedEmail, 'owner@example.com');
      expect(client.activatedPassword, 'Password123!');
      expect(cubit.state.step, OwnerActivationStep.activated);
    });

    test('short password -> failed without calling the client', () async {
      final client = _FakeClient();
      final cubit = _cubit(client);

      await cubit.submit(code: 'ABCD2345', password: 'short');

      expect(cubit.state.step, OwnerActivationStep.failed);
      expect(client.activatedCode, isNull);
    });

    test('invalid code -> failed', () async {
      final client = _FakeClient(inspectValid: false);
      final cubit = _cubit(client);

      await cubit.submit(code: 'WRONG', password: 'Password123!');

      expect(cubit.state.step, OwnerActivationStep.failed);
      expect(client.activatedCode, isNull);
    });

    test('activate failure -> failed with generic message', () async {
      final client = _FakeClient(activateThrows: true);
      final cubit = _cubit(client);

      await cubit.submit(code: 'ABCD2345', password: 'Password123!');

      expect(cubit.state.step, OwnerActivationStep.failed);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });
}
