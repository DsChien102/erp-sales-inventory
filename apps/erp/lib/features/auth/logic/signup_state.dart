import '../data/models/signup_input.dart';

enum SignupStep { account, store, verify }

enum SignupField {
  familyName,
  givenName,
  email,
  phone,
  password,
  confirmPassword,
  storeName,
  storePhone,
  province,
  commune,
  address,
  contactEmail,
}

final class SignupState {
  const SignupState({
    this.step = SignupStep.account,
    this.account,
    this.store,
    this.submitting = false,
    this.fieldErrors = const {},
    this.failure,
    this.emailExists = false,
    this.completed = false,
    this.tenantName,
    this.nameDiffers = false,
    this.passwordSyncFailed = false,
    this.verifyCooldownSeconds,
  });

  final SignupStep step;
  final SignupAccountInput? account;
  final SignupStoreInput? store;
  final bool submitting;
  final Map<SignupField, String> fieldErrors;
  final String? failure;
  final bool emailExists;

  /// Bước xác minh xong: trang chào mừng rồi vào `/`.
  final bool completed;
  final String? tenantName;
  final bool nameDiffers;
  final bool passwordSyncFailed;

  /// Số giây phải đợi trước khi gửi lại, khi đăng ký lại trong cửa sổ 60 giây.
  final int? verifyCooldownSeconds;

  SignupState copyWith({
    SignupStep? step,
    SignupAccountInput? account,
    SignupStoreInput? store,
    bool? submitting,
    Map<SignupField, String>? fieldErrors,
    String? failure,
    bool? emailExists,
    bool? completed,
    String? tenantName,
    bool? nameDiffers,
    bool? passwordSyncFailed,
    int? verifyCooldownSeconds,
    bool clearFailure = false,
  }) {
    return SignupState(
      step: step ?? this.step,
      account: account ?? this.account,
      store: store ?? this.store,
      submitting: submitting ?? this.submitting,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : (failure ?? this.failure),
      emailExists: emailExists ?? this.emailExists,
      completed: completed ?? this.completed,
      tenantName: tenantName ?? this.tenantName,
      nameDiffers: nameDiffers ?? this.nameDiffers,
      passwordSyncFailed: passwordSyncFailed ?? this.passwordSyncFailed,
      verifyCooldownSeconds:
          verifyCooldownSeconds ?? this.verifyCooldownSeconds,
    );
  }
}
