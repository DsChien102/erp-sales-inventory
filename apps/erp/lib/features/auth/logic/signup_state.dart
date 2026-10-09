import '../data/models/signup_input.dart';

enum SignupStep { account, store, verify }

final class SignupState {
  const SignupState({
    this.step = SignupStep.account,
    this.account,
    this.store,
    this.submitting = false,
    this.failure,
    this.emailExists = false,
  });

  final SignupStep step;
  final SignupAccountInput? account;
  final SignupStoreInput? store;
  final bool submitting;
  final String? failure;
  final bool emailExists;

  SignupState copyWith({
    SignupStep? step,
    SignupAccountInput? account,
    SignupStoreInput? store,
    bool? submitting,
    String? failure,
    bool? emailExists,
    bool clearFailure = false,
  }) {
    return SignupState(
      step: step ?? this.step,
      account: account ?? this.account,
      store: store ?? this.store,
      submitting: submitting ?? this.submitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      emailExists: emailExists ?? this.emailExists,
    );
  }
}
