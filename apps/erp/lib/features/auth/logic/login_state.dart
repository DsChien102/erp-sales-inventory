import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:vet45_iam_application/application.dart';

enum LoginStatus { initial, submitting, success, failure, needsVerification }

final class LoginState {
  const LoginState({
    this.status = LoginStatus.initial,
    this.session,
    this.failure,
    this.verificationEmail,
  });

  final LoginStatus status;
  final SessionDto? session;
  final IamUiFailure? failure;
  final String? verificationEmail;

  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    LoginStatus? status,
    SessionDto? session,
    IamUiFailure? failure,
    String? verificationEmail,
    bool clearFailure = false,
    bool clearSession = false,
    bool clearVerificationEmail = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      failure: clearFailure ? null : (failure ?? this.failure),
      verificationEmail: clearVerificationEmail
          ? null
          : (verificationEmail ?? this.verificationEmail),
    );
  }
}
