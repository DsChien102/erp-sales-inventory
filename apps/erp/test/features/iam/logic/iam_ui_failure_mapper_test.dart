import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/iam/logic/iam_ui_failure_mapper.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('IamUiFailureMapper', () {
    test('PLATFORM_USER_SUSPENDED shows suspended account message', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(IamBlockedCodes.platformUserSuspended),
      );
      expect(failure.code, IamBlockedCodes.platformUserSuspended);
      expect(
        failure.message,
        'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.',
      );
    });

    test('STATE_CHANGED requires reload', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(IamBlockedCodes.stateChanged),
      );
      expect(failure.requiresReload, isTrue);
      expect(failure.code, IamBlockedCodes.stateChanged);
      expect(failure.retryable, isFalse);
      expect(failure.requiresStepUp, isFalse);
    });

    test('STEP_UP_AUTH_REQUIRED requests step-up UX', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(IamBlockedCodes.stepUpAuthRequired),
      );
      expect(failure.requiresStepUp, isTrue);
      expect(failure.code, IamBlockedCodes.stepUpAuthRequired);
      expect(failure.retryable, isFalse);
      expect(failure.requiresReload, isFalse);
    });

    test('SYSTEM_ERROR is retryable', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(IamBlockedCodes.systemError),
      );
      expect(failure.code, IamBlockedCodes.systemError);
      expect(failure.retryable, isTrue);
      expect(failure.requiresReload, isFalse);
      expect(failure.requiresStepUp, isFalse);
    });

    test('RESET_RATE_LIMITED is retryable', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(IamBlockedCodes.resetRateLimited),
      );
      expect(failure.code, IamBlockedCodes.resetRateLimited);
      expect(failure.retryable, isTrue);
    });

    test('exact ApplicationException code is preserved', () {
      final failure = IamUiFailureMapper.from(
        ApplicationException(IamBlockedCodes.permissionDenied),
      );
      expect(failure.code, IamBlockedCodes.permissionDenied);
      expect(failure.retryable, isFalse);
      expect(failure.requiresReload, isFalse);
      expect(failure.requiresStepUp, isFalse);
    });

    test('human sentence is not parsed as a stable code', () {
      final failure = IamUiFailureMapper.from(
        ApplicationException('Platform user not found: user-1'),
      );
      expect(failure.code, IamBlockedCodes.systemError);
      expect(failure.retryable, isTrue);
    });

    test('raw driver text never reaches the user for a known code', () {
      // Infra stringifies the whole PostgrestException into the exception
      // message (`RpcException(error.toString())`), so a known code must still
      // render its curated sentence rather than the driver dump.
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(
          IamBlockedCodes.invitationTokenInvalid,
          message:
              'PostgrestException(message: INVITATION_TOKEN_INVALID, '
              'code: P0001, details: Bad Request, hint: null)',
        ),
      );
      expect(failure.code, IamBlockedCodes.invitationTokenInvalid);
      expect(failure.message, 'Mã lời mời không hợp lệ.');
      expect(failure.message, isNot(contains('PostgrestException')));
    });

    test('permission denied dump is replaced by the curated sentence', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(
          IamBlockedCodes.permissionDenied,
          message:
              'PostgrestException(message: permission denied for schema iam, '
              'code: 42501, details: Unauthorized, hint: null)',
        ),
      );
      expect(failure.message, 'Bạn không có quyền thực hiện thao tác này.');
    });

    test('unknown code still falls back to the raw message', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException('SOME_UNMAPPED_CODE', message: 'chi tiết lạ'),
      );
      expect(failure.code, 'SOME_UNMAPPED_CODE');
      expect(failure.message, 'chi tiết lạ');
    });

    test('ValidationException maps to VALIDATION_ERROR', () {
      final failure = IamUiFailureMapper.from(
        ValidationException('email required'),
      );
      expect(failure.code, IamBlockedCodes.validationError);
      expect(failure.message, 'email required');
      expect(failure.retryable, isFalse);
    });

    test('NO_ACTIVE_MEMBERSHIP uses curated login copy', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(IamBlockedCodes.noActiveMembership),
      );
      expect(failure.code, IamBlockedCodes.noActiveMembership);
      expect(
        failure.message,
        'Tài khoản chưa thuộc tổ chức nào đang hoạt động.',
      );
      expect(failure.retryable, isFalse);
    });

    test('AppException NO_PERMISSION keeps the old permission sentence', () {
      final failure = IamUiFailureMapper.from(
        const AppException(AppErrorCode.noPermission),
      );
      expect(failure.code, IamBlockedCodes.permissionDenied);
      expect(failure.message, 'Bạn không có quyền thực hiện thao tác này.');
    });

    test('AppException STATE_CHANGED requires reload', () {
      final failure = IamUiFailureMapper.from(
        const AppException(AppErrorCode.stateChanged),
      );
      expect(failure.code, IamBlockedCodes.stateChanged);
      expect(failure.requiresReload, isTrue);
    });

    test('AppException NETWORK_ERROR uses the network sentence', () {
      final failure = IamUiFailureMapper.from(
        const AppException(AppErrorCode.network),
      );
      expect(failure.code, IamBlockedCodes.systemError);
      expect(
        failure.message,
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
      );
      expect(failure.retryable, isTrue);
    });

    test('unknown error maps to SYSTEM_ERROR', () {
      final failure = IamUiFailureMapper.from(StateError('boom'));
      expect(failure.code, IamBlockedCodes.systemError);
      expect(failure.retryable, isTrue);
    });
  });
}
