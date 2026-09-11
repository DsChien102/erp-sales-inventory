import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';
import 'organization_profile_form_input.dart';

final class OrganizationProfileState {
  const OrganizationProfileState({
    this.status = IamLoadStatus.initial,
    this.tenant,
    this.isSubmittingProfile = false,
    this.isSubmittingLegal = false,
    this.duplicateWarning,
    this.pendingLegalInput,
    this.failure,
    this.successMessage,
  });

  final IamLoadStatus status;
  final TenantDto? tenant;
  final bool isSubmittingProfile;
  final bool isSubmittingLegal;
  final DuplicateTaxCodeWarningDto? duplicateWarning;
  final LegalProfileFormInput? pendingLegalInput;
  final IamUiFailure? failure;
  final String? successMessage;

  bool get hasLegalProfile => tenant?.legalProfile != null;

  OrganizationProfileState copyWith({
    IamLoadStatus? status,
    TenantDto? tenant,
    bool? isSubmittingProfile,
    bool? isSubmittingLegal,
    DuplicateTaxCodeWarningDto? duplicateWarning,
    LegalProfileFormInput? pendingLegalInput,
    IamUiFailure? failure,
    String? successMessage,
    bool clearTenant = false,
    bool clearDuplicate = false,
    bool clearPendingLegal = false,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return OrganizationProfileState(
      status: status ?? this.status,
      tenant: clearTenant ? null : (tenant ?? this.tenant),
      isSubmittingProfile: isSubmittingProfile ?? this.isSubmittingProfile,
      isSubmittingLegal: isSubmittingLegal ?? this.isSubmittingLegal,
      duplicateWarning: clearDuplicate
          ? null
          : (duplicateWarning ?? this.duplicateWarning),
      pendingLegalInput: clearPendingLegal
          ? null
          : (pendingLegalInput ?? this.pendingLegalInput),
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
