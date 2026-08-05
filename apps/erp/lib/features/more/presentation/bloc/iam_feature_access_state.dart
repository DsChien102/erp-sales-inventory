import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';

enum IamReadinessHubBannerTone { warning, success }

final class IamReadinessHubBanner {
  const IamReadinessHubBanner({
    required this.tone,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final IamReadinessHubBannerTone tone;
  final String eyebrow;
  final String title;
  final String body;
}

final class IamFeatureAccessState {
  const IamFeatureAccessState({
    this.status = IamLoadStatus.initial,
    this.session,
    this.readiness,
    this.failure,
  });

  final IamLoadStatus status;
  final SessionDto? session;
  final TenantReadinessDto? readiness;
  final IamUiFailure? failure;

  bool _has(String code) => session?.hasPermission(code) ?? false;

  bool get canViewMembers => _has(IamPermissions.memberView);
  bool get canInviteMembers => _has(IamPermissions.memberInvite);
  bool get canUpdateMemberStatus => _has(IamPermissions.memberStatusUpdate);
  bool get canRemoveMember => _has(IamPermissions.memberRemove);
  bool get canViewTenantProfile => _has(IamPermissions.tenantView);
  bool get canUpdateTenantProfile => _has(IamPermissions.tenantProfileUpdate);
  bool get canUpdateLegalProfile => _has(IamPermissions.tenantLegalProfileUpdate);
  bool get canViewReadiness => _has(IamPermissions.tenantReadinessView);
  bool get canActivateTenant => _has(IamPermissions.tenantActivate);
  bool get canViewTenantAudit => _has(IamPermissions.tenantAuditView);

  /// Hub entry when any phase-1 read capability is present. No roles (S4).
  bool get canOpenIamHub =>
      canViewMembers || canViewTenantProfile || canViewReadiness || canViewTenantAudit;

  IamReadinessHubBanner? get readinessBanner {
    if (!canViewReadiness) return null;
    final r = readiness;
    if (r == null) {
      return const IamReadinessHubBanner(
        tone: IamReadinessHubBannerTone.warning,
        eyebrow: 'Cần hoàn tất',
        title: 'Tổ chức chưa hoàn tất thiết lập',
        body: 'Còn điều kiện bắt buộc trước khi có thể bắt đầu vận hành.',
      );
    }
    if (r.status == TenantLifecycleStatus.active) {
      return null;
    }
    if (r.blockers.isNotEmpty) {
      return IamReadinessHubBanner(
        tone: IamReadinessHubBannerTone.warning,
        eyebrow: 'Cần hoàn tất',
        title: 'Tổ chức chưa hoàn tất thiết lập',
        body:
            'Còn ${r.blockers.length} điều kiện bắt buộc trước khi có thể '
            'bắt đầu vận hành.',
      );
    }
    if (r.warnings.isNotEmpty && r.canActivate) {
      return IamReadinessHubBanner(
        tone: IamReadinessHubBannerTone.success,
        eyebrow: 'Sẵn sàng kích hoạt',
        title: 'Tổ chức đã sẵn sàng kích hoạt',
        body:
            'Còn ${r.warnings.length} cảnh báo nên xử lý, nhưng tổ chức '
            'đã có thể kích hoạt.',
      );
    }
    if (r.canActivate && r.status != TenantLifecycleStatus.active) {
      return const IamReadinessHubBanner(
        tone: IamReadinessHubBannerTone.success,
        eyebrow: 'Sẵn sàng kích hoạt',
        title: 'Tổ chức đã sẵn sàng kích hoạt',
        body: 'Kích hoạt tổ chức để có thể bắt đầu vận hành.',
      );
    }
    if (r.warnings.isNotEmpty) {
      return IamReadinessHubBanner(
        tone: IamReadinessHubBannerTone.warning,
        eyebrow: 'Cần hoàn tất',
        title: 'Tổ chức chưa hoàn tất thiết lập',
        body: 'Còn ${r.warnings.length} cảnh báo nên xử lý trước khi kích hoạt.',
      );
    }
    return null;
  }

  /// Soft banner when view permission; hide once tenant is fully ready/active.
  bool get showReadinessBanner => readinessBanner != null;

  String get readinessBannerBody => readinessBanner?.body ?? '';

  IamFeatureAccessState copyWith({
    IamLoadStatus? status,
    SessionDto? session,
    TenantReadinessDto? readiness,
    IamUiFailure? failure,
    bool clearFailure = false,
    bool clearSession = false,
    bool clearReadiness = false,
  }) {
    return IamFeatureAccessState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      readiness: clearReadiness ? null : (readiness ?? this.readiness),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
