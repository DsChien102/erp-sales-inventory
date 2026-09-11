enum PartnerStatusSubmitStatus {
  idle,
  submitting,
  success,
  failure,
}

final class PartnerStatusSubmitState {
  const PartnerStatusSubmitState({
    this.status = PartnerStatusSubmitStatus.idle,
    this.generalError,
    this.successMessage,
  });

  final PartnerStatusSubmitStatus status;
  final String? generalError;
  final String? successMessage;

  bool get isSubmitting => status == PartnerStatusSubmitStatus.submitting;

  PartnerStatusSubmitState copyWith({
    PartnerStatusSubmitStatus? status,
    String? generalError,
    String? successMessage,
    bool clearGeneralError = false,
    bool clearSuccessMessage = false,
  }) {
    return PartnerStatusSubmitState(
      status: status ?? this.status,
      generalError: clearGeneralError
          ? null
          : (generalError ?? this.generalError),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
