enum OwnerActivationStep { entry, submitting, activated, failed }

final class OwnerActivationState {
  const OwnerActivationState({
    this.step = OwnerActivationStep.entry,
    this.errorMessage,
  });

  final OwnerActivationStep step;
  final String? errorMessage;

  bool get isSubmitting => step == OwnerActivationStep.submitting;

  OwnerActivationState copyWith({
    OwnerActivationStep? step,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnerActivationState(
      step: step ?? this.step,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
