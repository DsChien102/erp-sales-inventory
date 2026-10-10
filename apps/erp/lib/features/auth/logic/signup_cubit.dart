import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/validation/password_policy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../data/auth_repository.dart';
import '../data/models/signup_input.dart';
import 'signup_state.dart';

final class SignupCubit extends Cubit<SignupState> {
  SignupCubit({
    required AuthRepository auth,
    required SessionController session,
  }) : _auth = auth,
       _session = session,
       super(const SignupState());

  final AuthRepository _auth;
  final SessionController _session;

  /// Kiểm bước tài khoản. Không gọi server.
  void continueToStore(SignupAccountInput account) {
    if (state.submitting) return;
    final failure = _accountFailure(account);
    if (failure != null) {
      emit(state.copyWith(failure: failure, emailExists: false));
      return;
    }
    emit(
      state.copyWith(
        step: SignupStep.store,
        account: account,
        clearFailure: true,
        emailExists: false,
      ),
    );
  }

  /// Quay lại bước tài khoản, giữ dữ liệu đã nhập.
  void back() {
    if (state.submitting || state.step != SignupStep.store) return;
    emit(state.copyWith(step: SignupStep.account, clearFailure: true));
  }

  Future<void> createStore(SignupStoreInput store) async {
    if (state.submitting || state.step != SignupStep.store) return;
    final account = state.account;
    if (account == null) return;

    final failure = _storeFailure(store);
    if (failure != null) {
      emit(state.copyWith(store: store, failure: failure, emailExists: false));
      return;
    }

    emit(
      state.copyWith(
        store: store,
        submitting: true,
        clearFailure: true,
        emailExists: false,
      ),
    );

    try {
      await _auth.signUpStore(account: account, store: store);
      if (isClosed) return;
      emit(
        state.copyWith(
          step: SignupStep.verify,
          submitting: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      if (error is AppException && error.code == AppErrorCode.resendCooldown) {
        emit(
          state.copyWith(
            step: SignupStep.verify,
            submitting: false,
            verifyCooldownSeconds: _cooldownSeconds(error),
            clearFailure: true,
          ),
        );
        return;
      }
      final mapped = IamUiFailureMapper.from(error);
      final exists = error is AppException && error.code == 'PLATFORM_USER_ALREADY_EXISTS' ||
          mapped.code == IamBlockedCodes.platformUserAlreadyExists;
      emit(
        state.copyWith(
          submitting: false,
          emailExists: exists,
          failure: exists ? 'Email đã được đăng ký' : mapped.message,
        ),
      );
    }
  }

  /// Sau khi mã OTP đúng: ghi lại mật khẩu vừa nhập, tải phiên, rồi mới gắn đăng nhập.
  Future<void> completeAfterVerification(String userId) async {
    // Trang đóng giữa chừng: vẫn gắn phiên để không kẹt cờ giữ của SessionController.
    if (isClosed) {
      _session.applySignedInUser(userId);
      return;
    }
    if (state.completed || state.submitting || state.step != SignupStep.verify) {
      return;
    }
    emit(state.copyWith(submitting: true, clearFailure: true));

    var passwordSyncFailed = false;
    final password = state.account?.password ?? '';
    if (password.isNotEmpty) {
      try {
        await _auth.updatePassword(password);
      } catch (_) {
        passwordSyncFailed = true;
      }
    }
    if (isClosed) {
      _session.applySignedInUser(userId);
      return;
    }

    await _session.bootstrap();
    if (isClosed) {
      _session.applySignedInUser(userId);
      return;
    }

    final tenantName = _session.state.current?.tenantName;
    final entered = state.store?.name.trim() ?? '';
    final differs = tenantName != null && tenantName.trim() != entered;
    emit(
      state.copyWith(
        submitting: false,
        completed: true,
        tenantName: tenantName,
        nameDiffers: differs,
        passwordSyncFailed: passwordSyncFailed,
        clearFailure: true,
      ),
    );
    _session.applySignedInUser(userId);
  }

  static int _cooldownSeconds(AppException error) {
    final raw = error.details?['seconds'];
    if (raw is int && raw > 0) return raw;
    return 60;
  }

  static String? _accountFailure(SignupAccountInput account) {
    if (account.familyName.trim().isEmpty) return 'Vui lòng nhập họ và tên đệm';
    if (account.givenName.trim().isEmpty) return 'Vui lòng nhập tên';
    final email = account.email.trim();
    if (email.isEmpty || !_email.hasMatch(email)) return 'Email không hợp lệ';
    final phone = account.phone?.trim() ?? '';
    if (phone.isNotEmpty && !_validPhone(phone)) {
      return 'Số điện thoại phải có 9–11 chữ số';
    }
    final passwordError = PasswordPolicy.validate(account.password);
    if (passwordError != null) {
      if (account.password.length < PasswordPolicy.minLength) {
        return 'Mật khẩu phải có ít nhất 8 ký tự';
      }
      return passwordError;
    }
    if (account.password != account.confirmPassword) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  static String? _storeFailure(SignupStoreInput store) {
    if (store.addressText.trim().isEmpty) return 'Vui lòng nhập địa chỉ cửa hàng';
    if (store.name.trim().isEmpty) return 'Vui lòng nhập tên cửa hàng';
    if (!_validPhone(store.contactPhone)) return 'Số điện thoại phải có 9–11 chữ số';
    if (store.provinceCode.trim().isEmpty) return 'Vui lòng chọn tỉnh / thành phố';
    if (store.communeCode.trim().isEmpty) return 'Vui lòng chọn xã / phường';
    return null;
  }

  static bool _validPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && digits.length <= 11;
  }

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
