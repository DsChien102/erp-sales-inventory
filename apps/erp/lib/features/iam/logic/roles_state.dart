import '../../../core/iam/iam_load_status.dart';
import 'role_ui_model.dart';

const rolesLoadErrorMessage =
    'Không thể tải danh sách vai trò — Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.';

final class RolesState {
  const RolesState({
    this.status = IamLoadStatus.initial,
    this.roles = const [],
    this.failure,
  });

  final IamLoadStatus status;
  final List<RoleUiModel> roles;
  final String? failure;

  RolesState copyWith({
    IamLoadStatus? status,
    List<RoleUiModel>? roles,
    String? failure,
    bool clearFailure = false,
  }) {
    return RolesState(
      status: status ?? this.status,
      roles: roles ?? this.roles,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
