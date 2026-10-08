import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  test('returns the same AppException', () {
    const error = AppException('HAS_TRANSACTIONS', serverMessage: 'still used');
    expect(identical(AppException.from(error), error), isTrue);
  });

  test('PERMISSION_DENIED becomes NO_PERMISSION', () {
    final error = AppException.from(const PostgrestException(message: 'PERMISSION_DENIED'));
    expect(error.code, AppErrorCode.noPermission);
  });

  test('NO_PERMISSION keeps the detail after the colon', () {
    final error = AppException.from(
      const PostgrestException(message: 'NO_PERMISSION: einvoice.view required'),
    );
    expect(error.code, AppErrorCode.noPermission);
    expect(error.serverMessage, 'einvoice.view required');
  });

  test('code with a JSON detail keeps nested blockers', () {
    final error = AppException.from(
      const PostgrestException(
        message: 'ISSUANCE_NOT_READY: {"details":{"blockers":["X"]}}',
      ),
    );
    expect(error.code, 'ISSUANCE_NOT_READY');
    expect(error.details?['details']['blockers'], contains('X'));
  });

  test('JSON message reads code and message', () {
    final error = AppException.from(
      const PostgrestException(message: '{"code":"STATE_CHANGED","message":"stale"}'),
    );
    expect(error.code, AppErrorCode.stateChanged);
    expect(error.serverMessage, 'stale');
  });

  test('free-text permission denied becomes NO_PERMISSION', () {
    final error = AppException.from(
      const PostgrestException(message: 'permission denied: partner.detail.view'),
    );
    expect(error.code, AppErrorCode.noPermission);
  });

  test('Postgres 42501 becomes NO_PERMISSION', () {
    final error = AppException.from(
      const PostgrestException(message: 'permission denied for table partners', code: '42501'),
    );
    expect(error.code, AppErrorCode.noPermission);
  });

  test('not authenticated becomes AUTHENTICATION_REQUIRED', () {
    final error = AppException.from(const PostgrestException(message: 'not authenticated'));
    expect(error.code, AppErrorCode.authRequired);
  });

  test('RESOURCE_NOT_FOUND becomes NOT_FOUND and domain codes stay', () {
    expect(
      AppException.from(const PostgrestException(message: 'RESOURCE_NOT_FOUND')).code,
      AppErrorCode.notFound,
    );
    expect(
      AppException.from(const PostgrestException(message: 'HAS_TRANSACTIONS')).code,
      'HAS_TRANSACTIONS',
    );
  });

  test('invalid credentials AuthException keeps INVALID_CREDENTIALS', () {
    final error = AppException.from(
      const AuthException('Invalid login credentials', code: 'invalid_credentials'),
    );
    expect(error.code, 'INVALID_CREDENTIALS');
  });

  test('email not confirmed and rate limit map to their codes', () {
    expect(
      AppException.from(
        const AuthException('Email not confirmed', code: 'email_not_confirmed'),
      ).code,
      'IDENTITY_EMAIL_NOT_VERIFIED',
    );
    expect(
      AppException.from(
        const AuthException('Too many', code: 'over_email_send_rate_limit'),
      ).code,
      'RATE_LIMITED',
    );
    expect(
      AppException.from(const AuthException('unauthorized', statusCode: '401')).code,
      AppErrorCode.authRequired,
    );
    expect(
      AppException.from(const AuthException('boom', statusCode: '500')).code,
      AppErrorCode.unknown,
    );
  });

  test('socket and timeout errors become NETWORK_ERROR', () {
    expect(
      AppException.from(Exception('SocketException: Failed host lookup')).code,
      AppErrorCode.network,
    );
    expect(AppException.from(TimeoutException('slow')).code, AppErrorCode.network);
  });

  test('unknown errors become SYSTEM_ERROR', () {
    final error = AppException.from(Exception('nope'));
    expect(error.code, AppErrorCode.unknown);
    expect(error.cause, isA<Exception>());
  });

  test('userMessage uses an override, otherwise the shared sentence', () {
    const domain = AppException('HAS_TRANSACTIONS');
    expect(domain.userMessage({'HAS_TRANSACTIONS': 'x'}), 'x');
    expect(domain.userMessage(), 'Đã có lỗi xảy ra. Vui lòng thử lại.');
    expect(
      const AppException(AppErrorCode.noPermission).userMessage(),
      'Bạn không có quyền thực hiện thao tác này.',
    );
  });
}
