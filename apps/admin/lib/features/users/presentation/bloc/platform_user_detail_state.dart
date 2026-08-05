import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';

enum PlatformUserMutation {
  activationInvite,
  passwordReset,
  suspend,
  restore,
}

final class PlatformUserDetailState {
  const PlatformUserDetailState({
    this.status = IamLoadStatus.initial,
    this.user,
    this.isSubmitting = false,
    this.activeMutation,
    this.failure,
    this.successMessage,
    this.permissions = const [],
  });

  final IamLoadStatus status;
  final PlatformUserDetailDto? user;
  final bool isSubmitting;
  final PlatformUserMutation? activeMutation;
  final IamUiFailure? failure;
  final String? successMessage;
  final List<String> permissions;

  bool hasPermission(String code) {
    // Mirror SessionDto.hasPermission: owner role grants all mapped codes.
    if (permissions.contains('__owner__')) return true;
    return permissions.contains(code);
  }

  bool get canSendActivationInvite =>
      hasPermission(IamPlatformPermissions.userActivationInviteSend);
  bool get canRequestPasswordReset =>
      hasPermission(IamPlatformPermissions.userPasswordResetInitiate);
  bool get canSuspend => hasPermission(IamPlatformPermissions.userSuspend);
  bool get canRestore => hasPermission(IamPlatformPermissions.userRestore);

  bool get showActivationInvite =>
      user?.status == PlatformUserStatus.pendingActivation &&
      canSendActivationInvite;
  bool get showPasswordReset =>
      user?.status == PlatformUserStatus.active && canRequestPasswordReset;
  bool get showSuspend =>
      (user?.status == PlatformUserStatus.active ||
          user?.status == PlatformUserStatus.pendingActivation) &&
      canSuspend;
  bool get showRestore =>
      user?.status == PlatformUserStatus.suspended && canRestore;

  PlatformUserDetailState copyWith({
    IamLoadStatus? status,
    PlatformUserDetailDto? user,
    bool? isSubmitting,
    PlatformUserMutation? activeMutation,
    IamUiFailure? failure,
    String? successMessage,
    List<String>? permissions,
    bool clearUser = false,
    bool clearActiveMutation = false,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return PlatformUserDetailState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeMutation: clearActiveMutation
          ? null
          : (activeMutation ?? this.activeMutation),
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      permissions: permissions ?? this.permissions,
    );
  }
}
