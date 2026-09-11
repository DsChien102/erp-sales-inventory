import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation.dart';

enum LoginStatus { initial, submitting, success, failure }

final class LoginState {
  const LoginState({
    this.status = LoginStatus.initial,
    this.session,
    this.failure,
  });

  final LoginStatus status;
  final SessionDto? session;
  final IamUiFailure? failure;

  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    LoginStatus? status,
    SessionDto? session,
    IamUiFailure? failure,
    bool clearFailure = false,
    bool clearSession = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
