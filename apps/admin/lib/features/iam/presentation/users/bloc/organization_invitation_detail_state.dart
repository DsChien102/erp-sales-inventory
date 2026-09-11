import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';

enum InvitationMutation { resend, revoke }

final class OrganizationInvitationDetailState {
  const OrganizationInvitationDetailState({
    this.status = IamLoadStatus.initial,
    this.invitation,
    this.isSubmitting = false,
    this.activeMutation,
    this.failure,
    this.successMessage,
    this.deliveryWarning = false,
  });

  final IamLoadStatus status;
  final InvitationDetailDto? invitation;
  final bool isSubmitting;
  final InvitationMutation? activeMutation;
  final IamUiFailure? failure;
  final String? successMessage;

  /// Resend succeeded but deliveryStatus == failed.
  final bool deliveryWarning;

  bool get canMutate => invitation?.status == 'pending';

  OrganizationInvitationDetailState copyWith({
    IamLoadStatus? status,
    InvitationDetailDto? invitation,
    bool? isSubmitting,
    InvitationMutation? activeMutation,
    IamUiFailure? failure,
    String? successMessage,
    bool? deliveryWarning,
    bool clearInvitation = false,
    bool clearMutation = false,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return OrganizationInvitationDetailState(
      status: status ?? this.status,
      invitation: clearInvitation ? null : (invitation ?? this.invitation),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeMutation:
          clearMutation ? null : (activeMutation ?? this.activeMutation),
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      deliveryWarning: deliveryWarning ?? this.deliveryWarning,
    );
  }
}
