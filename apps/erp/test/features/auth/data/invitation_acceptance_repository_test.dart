import 'dart:io';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/data/invitation_acceptance_repository.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';

import '../support/scripted_auth.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  late _MockFunctions functions;
  late InvitationAcceptanceRepository repository;

  setUp(() {
    functions = _MockFunctions();
    repository = InvitationAcceptanceRepository(rpc: testRpc(), functions: functions);
  });

  Future<Object> register() async {
    try {
      return await repository.registerAndAccept(
        token: 'K7P29XQM',
        password: 'Password123@',
        givenName: 'Minh',
        familyName: 'Tran',
        phone: '0900000000',
        idempotencyKey: 'register-from-invitation-1',
      );
    } on AppException catch (error) {
      return error;
    }
  }

  When<Future<FunctionResponse>> stubInvoke() => when(
    () => functions.invoke(any(), body: any(named: 'body')),
  );

  test('registerAndAccept sends the snake_case body and parses the membership', () async {
    stubInvoke().thenAnswer(
      (_) async => FunctionResponse(
        status: 200,
        data: {
          'membership': {
            'membership_id': 'mem-1',
            'tenant_id': 'org-001',
            'user_id': 'user-9',
            'role': 'staff',
            'status': 'active',
            'version': 1,
            'joined_at': '2026-10-12T00:00:00Z',
          },
        },
      ),
    );

    final result = await register();

    final membership = result as TenantMemberDetail;
    expect(membership.membershipId, 'mem-1');
    expect(membership.userId, 'user-9');
    expect(membership.status, MembershipStatus.active);
    final captured = verify(
      () => functions.invoke('invitation-signup', body: captureAny(named: 'body')),
    ).captured.single as Map<String, dynamic>;
    expect(captured, {
      'token': 'K7P29XQM',
      'password': 'Password123@',
      'given_name': 'Minh',
      'family_name': 'Tran',
      'phone': '0900000000',
      'idempotency_key': 'register-from-invitation-1',
    });
  });

  test('registerAndAccept maps function error codes', () async {
    final cases = <String, String>{
      'ACCOUNT_EXISTS': 'PLATFORM_USER_ALREADY_EXISTS',
      'WEAK_PASSWORD': 'PASSWORD_POLICY_VIOLATION',
      'INVITATION_EXPIRED': 'INVITATION_EXPIRED',
      'INVITATION_ALREADY_USED': 'INVITATION_ALREADY_USED',
    };
    for (final entry in cases.entries) {
      stubInvoke().thenThrow(
        FunctionException(status: 400, details: {'code': entry.key}),
      );
      final error = await register();
      expect((error as AppException).code, entry.value, reason: entry.key);
    }
  });

  test('registerAndAccept treats a missing code as a system error', () async {
    stubInvoke().thenThrow(const FunctionException(status: 500, details: 'boom'));
    expect(((await register()) as AppException).code, AppErrorCode.unknown);
  });

  test('registerAndAccept reports transport failures as network errors', () async {
    stubInvoke().thenThrow(
      const FunctionsFetchException(details: SocketException('offline')),
    );
    expect(((await register()) as AppException).code, AppErrorCode.network);
  });
}
