import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

enum InvitationAcceptanceStep {
  tokenEntry,
  inspecting,
  existingAccountLogin,
  newAccountRegistration,
  submitting,
  accepted,
  declined,
  blocked,
}

final class InvitationAcceptanceState {
  const InvitationAcceptanceState({
    this.step = InvitationAcceptanceStep.tokenEntry,
    this.inspection,
    this.tokenPresent = false,
    this.isSubmitting = false,
    this.failure,
    this.acceptedMembership,
    this.registrationResult,
  });

  final InvitationAcceptanceStep step;
  final InvitationTokenInspectionDto? inspection;

  /// Whether Cubit holds a private token — never exposes the raw value.
  final bool tokenPresent;
  final bool isSubmitting;
  final IamUiFailure? failure;
  final TenantMemberDetailDto? acceptedMembership;
  final InvitationRegistrationResultDto? registrationResult;

  InvitationAcceptanceState copyWith({
    InvitationAcceptanceStep? step,
    InvitationTokenInspectionDto? inspection,
    bool? tokenPresent,
    bool? isSubmitting,
    IamUiFailure? failure,
    TenantMemberDetailDto? acceptedMembership,
    InvitationRegistrationResultDto? registrationResult,
    bool clearInspection = false,
    bool clearFailure = false,
    bool clearAcceptedMembership = false,
    bool clearRegistrationResult = false,
  }) {
    return InvitationAcceptanceState(
      step: step ?? this.step,
      inspection: clearInspection ? null : (inspection ?? this.inspection),
      tokenPresent: tokenPresent ?? this.tokenPresent,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      acceptedMembership: clearAcceptedMembership
          ? null
          : (acceptedMembership ?? this.acceptedMembership),
      registrationResult: clearRegistrationResult
          ? null
          : (registrationResult ?? this.registrationResult),
    );
  }
}
