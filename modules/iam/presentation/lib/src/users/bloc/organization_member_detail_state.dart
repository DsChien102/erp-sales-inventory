import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';

enum MembershipMutation { deactivate, reactivate, remove }

final class OrganizationMemberDetailState {
  const OrganizationMemberDetailState({
    this.status = IamLoadStatus.initial,
    this.member,
    this.isSubmitting = false,
    this.activeMutation,
    this.failure,
    this.successMessage,
  });

  final IamLoadStatus status;
  final TenantMemberDetailDto? member;
  final bool isSubmitting;
  final MembershipMutation? activeMutation;
  final IamUiFailure? failure;
  final String? successMessage;

  bool get canDeactivate =>
      member != null &&
      member!.status == MembershipStatus.active &&
      !member!.isSoleOwner;

  bool get canReactivate =>
      member != null && member!.status == MembershipStatus.inactive;

  bool get canRemove =>
      member != null &&
      member!.status != MembershipStatus.removed &&
      !member!.isSoleOwner;

  bool get hasLifecycleActions => canDeactivate || canReactivate || canRemove;

  bool get isReadOnly =>
      member == null || member!.status == MembershipStatus.removed;

  OrganizationMemberDetailState copyWith({
    IamLoadStatus? status,
    TenantMemberDetailDto? member,
    bool? isSubmitting,
    MembershipMutation? activeMutation,
    IamUiFailure? failure,
    String? successMessage,
    bool clearMember = false,
    bool clearMutation = false,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return OrganizationMemberDetailState(
      status: status ?? this.status,
      member: clearMember ? null : (member ?? this.member),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeMutation:
          clearMutation ? null : (activeMutation ?? this.activeMutation),
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
