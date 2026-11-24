import '../presentation/widgets/partner_transform_blocked_state.dart';

enum PartnerTransformSubmitStatus {
  idle,
  submitting,
  success,
  blocked,
  duplicate,
  failure,
}

final class PartnerTransformSubmitState {
  const PartnerTransformSubmitState({
    this.status = PartnerTransformSubmitStatus.idle,
    this.blocked,
    this.generalError,
    this.fieldErrors = const {},
    this.transformedPartnerId,
  });

  final PartnerTransformSubmitStatus status;
  final PartnerTransformBlockedKind? blocked;
  final String? generalError;
  final Map<String, String> fieldErrors;
  final String? transformedPartnerId;

  bool get isSubmitting => status == PartnerTransformSubmitStatus.submitting;

  PartnerTransformSubmitState copyWith({
    PartnerTransformSubmitStatus? status,
    PartnerTransformBlockedKind? blocked,
    String? generalError,
    Map<String, String>? fieldErrors,
    String? transformedPartnerId,
    bool clearBlocked = false,
    bool clearGeneralError = false,
    bool clearFieldErrors = false,
  }) {
    return PartnerTransformSubmitState(
      status: status ?? this.status,
      blocked: clearBlocked ? null : (blocked ?? this.blocked),
      generalError: clearGeneralError
          ? null
          : (generalError ?? this.generalError),
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      transformedPartnerId: transformedPartnerId ?? this.transformedPartnerId,
    );
  }
}
