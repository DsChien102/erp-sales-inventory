import 'package:flutter/material.dart';

import 'iam_load_status.dart';
import 'iam_ui_failure.dart';
import 'user_ui_model.dart';

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
    this.invitationSendResultFilter,
    this.invitationTimeRangeFilter,
    this.invitationCustomDateRange,
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

  /// Send result filter: 'Đã gửi' | 'Gửi lỗi' | 'Thu hồi', or null = all.
  final String? invitationSendResultFilter;

  /// Time range filter: '7 ngày' | '30 ngày' | 'Tùy chọn', or null = all.
  final String? invitationTimeRangeFilter;

  /// Custom date range when [invitationTimeRangeFilter] is 'Tùy chọn'.
  final DateTimeRange? invitationCustomDateRange;

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

  bool get isInvitationFiltered =>
      invitationSearch.trim().isNotEmpty ||
      invitationFilter != null ||
      invitationSendResultFilter != null ||
      invitationTimeRangeFilter != null ||
      invitationCustomDateRange != null;

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
    String? invitationSendResultFilter,
    String? invitationTimeRangeFilter,
    DateTimeRange? invitationCustomDateRange,
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
    bool clearInvitationSendResultFilter = false,
    bool clearInvitationTimeRangeFilter = false,
    bool clearInvitationCustomDateRange = false,
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
      invitationSendResultFilter: clearInvitationSendResultFilter
          ? null
          : (invitationSendResultFilter ?? this.invitationSendResultFilter),
      invitationTimeRangeFilter: clearInvitationTimeRangeFilter
          ? null
          : (invitationTimeRangeFilter ?? this.invitationTimeRangeFilter),
      invitationCustomDateRange: clearInvitationCustomDateRange
          ? null
          : (invitationCustomDateRange ?? this.invitationCustomDateRange),
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
