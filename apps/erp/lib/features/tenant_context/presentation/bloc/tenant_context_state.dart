import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:erp/features/iam/presentation.dart';

enum TenantContextLoadStatus {
  initial,
  loading,
  ready,
  blocked,
  failure,
}

final class TenantContextState {
  const TenantContextState({
    this.status = TenantContextLoadStatus.initial,
    this.current,
    this.tenants = const [],
    this.branchDisplayName,
    required this.userDisplayName,
    this.contextFailure,
    this.selectorFailure,
    this.switchFailure,
    this.blockedErrorCode,
    this.emptyStateType,
    this.suspendedOrgName,
    this.tenantsLoading = false,
    this.isSwitching = false,
    this.openSelectorRequested = false,
  });

  final TenantContextLoadStatus status;
  final TenantContextDto? current;
  final List<SelectOrganizationItemUiModel> tenants;
  final String? branchDisplayName;
  final String userDisplayName;
  final IamUiFailure? contextFailure;
  final IamUiFailure? selectorFailure;
  final IamUiFailure? switchFailure;
  final String? blockedErrorCode;
  final OrganizationEmptyStateType? emptyStateType;
  final String? suspendedOrgName;
  final bool tenantsLoading;
  final bool isSwitching;
  final bool openSelectorRequested;

  bool get isValid =>
      status == TenantContextLoadStatus.ready &&
      current?.status == TenantContextStatus.valid;

  bool get isBlocked => status == TenantContextLoadStatus.blocked;

  TenantContextState copyWith({
    TenantContextLoadStatus? status,
    TenantContextDto? current,
    List<SelectOrganizationItemUiModel>? tenants,
    String? branchDisplayName,
    String? userDisplayName,
    IamUiFailure? contextFailure,
    IamUiFailure? selectorFailure,
    IamUiFailure? switchFailure,
    String? blockedErrorCode,
    OrganizationEmptyStateType? emptyStateType,
    String? suspendedOrgName,
    bool? tenantsLoading,
    bool? isSwitching,
    bool? openSelectorRequested,
    bool clearContextFailure = false,
    bool clearSelectorFailure = false,
    bool clearSwitchFailure = false,
    bool clearCurrent = false,
    bool clearEmptyState = false,
  }) {
    return TenantContextState(
      status: status ?? this.status,
      current: clearCurrent ? null : (current ?? this.current),
      tenants: tenants ?? this.tenants,
      branchDisplayName: branchDisplayName ?? this.branchDisplayName,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      contextFailure: clearContextFailure
          ? null
          : (contextFailure ?? this.contextFailure),
      selectorFailure: clearSelectorFailure
          ? null
          : (selectorFailure ?? this.selectorFailure),
      switchFailure: clearSwitchFailure
          ? null
          : (switchFailure ?? this.switchFailure),
      blockedErrorCode: clearContextFailure
          ? null
          : (blockedErrorCode ?? this.blockedErrorCode),
      emptyStateType: clearEmptyState
          ? null
          : (emptyStateType ?? this.emptyStateType),
      suspendedOrgName: clearEmptyState
          ? null
          : (suspendedOrgName ?? this.suspendedOrgName),
      tenantsLoading: tenantsLoading ?? this.tenantsLoading,
      isSwitching: isSwitching ?? this.isSwitching,
      openSelectorRequested:
          openSelectorRequested ?? this.openSelectorRequested,
    );
  }
}
