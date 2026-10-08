import '../data/models/tenant_invitation.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure.dart';
import 'invitation_role_options.dart';

final class OrganizationInviteMemberState {
  const OrganizationInviteMemberState({
    this.status = IamLoadStatus.initial,
    this.email = '',
    this.roleOptions = const [],
    this.selectedRoleId,
    this.isSubmitting = false,
    this.createdInvitation,
    this.failure,
    this.deliveryWarning = false,
  });

  final IamLoadStatus status;
  final String email;
  final List<InvitationRoleOption> roleOptions;
  final String? selectedRoleId;
  final bool isSubmitting;
  final InvitationDetailDto? createdInvitation;
  final IamUiFailure? failure;

  /// Create succeeded but deliveryStatus == failed.
  final bool deliveryWarning;

  String? get selectedRoleLabel {
    final id = selectedRoleId;
    if (id == null) return null;
    for (final option in roleOptions) {
      if (option.roleId == id) return option.label;
    }
    return null;
  }

  OrganizationInviteMemberState copyWith({
    IamLoadStatus? status,
    String? email,
    List<InvitationRoleOption>? roleOptions,
    String? selectedRoleId,
    bool? isSubmitting,
    InvitationDetailDto? createdInvitation,
    IamUiFailure? failure,
    bool? deliveryWarning,
    bool clearSelectedRole = false,
    bool clearCreated = false,
    bool clearFailure = false,
  }) {
    return OrganizationInviteMemberState(
      status: status ?? this.status,
      email: email ?? this.email,
      roleOptions: roleOptions ?? this.roleOptions,
      selectedRoleId:
          clearSelectedRole ? null : (selectedRoleId ?? this.selectedRoleId),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdInvitation:
          clearCreated ? null : (createdInvitation ?? this.createdInvitation),
      failure: clearFailure ? null : (failure ?? this.failure),
      deliveryWarning: deliveryWarning ?? this.deliveryWarning,
    );
  }
}
