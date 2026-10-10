import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/iam/iam_ui_failure.dart';

import '../data/models/platform_tenant.dart';

enum PlatformTenantAction { suspend, restore, close }

final class PlatformTenantDetailState {
  const PlatformTenantDetailState({
    this.status = IamLoadStatus.initial,
    this.detail,
    this.members = const [],
    this.isSubmitting = false,
    this.failure,
    this.successMessage,
  });

  final IamLoadStatus status;
  final PlatformTenantDetail? detail;
  final List<PlatformTenantMember> members;
  final bool isSubmitting;
  final IamUiFailure? failure;
  final String? successMessage;

  PlatformTenantDetailState copyWith({
    IamLoadStatus? status,
    PlatformTenantDetail? detail,
    List<PlatformTenantMember>? members,
    bool? isSubmitting,
    IamUiFailure? failure,
    String? successMessage,
    bool clearDetail = false,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return PlatformTenantDetailState(
      status: status ?? this.status,
      detail: clearDetail ? null : (detail ?? this.detail),
      members: members ?? this.members,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}
