import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';
import '../models/user_ui_model.dart';

enum OrganizationUsersTab { members, invitations }

final class OrganizationUsersState {
  const OrganizationUsersState({
    this.activeTab = OrganizationUsersTab.members,
    this.memberStatus = IamLoadStatus.initial,
    this.invitationStatus = IamLoadStatus.initial,
    this.members = const [],
    this.invitations = const [],
    this.memberSearch = '',
    this.invitationSearch = '',
    this.memberFilter,
    this.memberRoleFilter,
    this.memberSort,
    this.invitationFilter,
    this.memberNextCursor,
    this.invitationNextCursor,
    this.memberFailure,
    this.invitationFailure,
    this.loadingMoreMembers = false,
    this.loadingMoreInvitations = false,
  });

  final OrganizationUsersTab activeTab;
  final IamLoadStatus memberStatus;
  final IamLoadStatus invitationStatus;
  final List<MemberUiModel> members;
  final List<InvitationUiModel> invitations;
  final String memberSearch;
  final String invitationSearch;

  /// Wire status: `active` | `inactive` | `removed`, or null = all.
  final String? memberFilter;

  /// Selected role filter label (e.g. 'Quản trị', 'Bán hàng', 'Kế toán'), or null = all.
  final String? memberRoleFilter;

  /// Selected sort option ('Tên A–Z', 'Tên Z–A'), or null = default (owner first).
  final String? memberSort;

  /// Wire status or `expiring` UI sentinel, or null = all.
  final String? invitationFilter;
  final String? memberNextCursor;
  final String? invitationNextCursor;
  final IamUiFailure? memberFailure;
  final IamUiFailure? invitationFailure;
  final bool loadingMoreMembers;
  final bool loadingMoreInvitations;

  bool get hasMoreMembers =>
      memberNextCursor != null && memberNextCursor!.isNotEmpty;

  bool get hasMoreInvitations =>
      invitationNextCursor != null && invitationNextCursor!.isNotEmpty;

  OrganizationUsersState copyWith({
    OrganizationUsersTab? activeTab,
    IamLoadStatus? memberStatus,
    IamLoadStatus? invitationStatus,
    List<MemberUiModel>? members,
    List<InvitationUiModel>? invitations,
    String? memberSearch,
    String? invitationSearch,
    String? memberFilter,
    String? memberRoleFilter,
    String? memberSort,
    String? invitationFilter,
    String? memberNextCursor,
    String? invitationNextCursor,
    IamUiFailure? memberFailure,
    IamUiFailure? invitationFailure,
    bool? loadingMoreMembers,
    bool? loadingMoreInvitations,
    bool clearMemberFilter = false,
    bool clearMemberRoleFilter = false,
    bool clearMemberSort = false,
    bool clearInvitationFilter = false,
    bool clearMemberCursor = false,
    bool clearInvitationCursor = false,
    bool clearMemberFailure = false,
    bool clearInvitationFailure = false,
  }) {
    return OrganizationUsersState(
      activeTab: activeTab ?? this.activeTab,
      memberStatus: memberStatus ?? this.memberStatus,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      memberSearch: memberSearch ?? this.memberSearch,
      invitationSearch: invitationSearch ?? this.invitationSearch,
      memberFilter:
          clearMemberFilter ? null : (memberFilter ?? this.memberFilter),
      memberRoleFilter: clearMemberRoleFilter
          ? null
          : (memberRoleFilter ?? this.memberRoleFilter),
      memberSort:
          clearMemberSort ? null : (memberSort ?? this.memberSort),
      invitationFilter: clearInvitationFilter
          ? null
          : (invitationFilter ?? this.invitationFilter),
      memberNextCursor: clearMemberCursor
          ? null
          : (memberNextCursor ?? this.memberNextCursor),
      invitationNextCursor: clearInvitationCursor
          ? null
          : (invitationNextCursor ?? this.invitationNextCursor),
      memberFailure: clearMemberFailure
          ? null
          : (memberFailure ?? this.memberFailure),
      invitationFailure: clearInvitationFailure
          ? null
          : (invitationFailure ?? this.invitationFailure),
      loadingMoreMembers: loadingMoreMembers ?? this.loadingMoreMembers,
      loadingMoreInvitations:
          loadingMoreInvitations ?? this.loadingMoreInvitations,
    );
  }
}
