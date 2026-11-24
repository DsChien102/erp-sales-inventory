import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';

import '../data/models/invitation_registration_result.dart';
import '../data/models/invitation_token_inspection.dart';

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
  final InvitationTokenInspection? inspection;

  /// Whether Cubit holds a private token — never exposes the raw value.
  final bool tokenPresent;
  final bool isSubmitting;
  final IamUiFailure? failure;
  final TenantMemberDetail? acceptedMembership;
  final InvitationRegistrationResult? registrationResult;

  InvitationAcceptanceState copyWith({
    InvitationAcceptanceStep? step,
    InvitationTokenInspection? inspection,
    bool? tokenPresent,
    bool? isSubmitting,
    IamUiFailure? failure,
    TenantMemberDetail? acceptedMembership,
    InvitationRegistrationResult? registrationResult,
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
