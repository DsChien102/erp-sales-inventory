import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/invitation_repository.dart';
import '../data/member_repository.dart';
import 'iam_load_status.dart';
import 'iam_role_label_mapper.dart';
import 'iam_ui_failure_mapper.dart';
import 'invitation_ui_mapper.dart';
import 'member_ui_mapper.dart';
import 'organization_users_state.dart';
import 'user_ui_model.dart';

final class OrganizationUsersCubit extends Cubit<OrganizationUsersState> {
  OrganizationUsersCubit({
    required MemberRepository members,
    required InvitationRepository invitations,
    DateTime Function()? clock,
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : _members = members,
       _invitations = invitations,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _searchDebounce = searchDebounce,
       super(const OrganizationUsersState());

  final MemberRepository _members;
  final InvitationRepository _invitations;
  final DateTime Function() _clock;
  final Duration _searchDebounce;

  Timer? _memberSearchTimer;
  Timer? _invitationSearchTimer;

  Future<void> loadInitial() async {
    await Future.wait([
      loadMembers(reset: true),
      loadInvitations(reset: true),
    ]);
  }

  Future<void> loadMembers({bool reset = false}) async {
    if (isClosed) return;
    if (reset) {
      emit(
        state.copyWith(
          memberStatus: IamLoadStatus.loading,
          clearMemberFailure: true,
          clearMemberCursor: true,
          members: const [],
        ),
      );
    } else if (state.memberStatus == IamLoadStatus.initial) {
      emit(
        state.copyWith(
          memberStatus: IamLoadStatus.loading,
          clearMemberFailure: true,
        ),
      );
    }

    try {
      final page = await _members.listMembers(
        search: _nullableSearch(state.memberSearch),
        status: state.memberFilter,
        cursor: reset ? null : state.memberNextCursor,
      );
      if (isClosed) return;
      final mapped = page.items.map(MemberUiMapper.fromSummary).toList();
      final merged = reset
          ? mapped
          : _dedupeMembers([...state.members, ...mapped]);
      emit(
        state.copyWith(
          memberStatus: IamLoadStatus.success,
          members: _filterAndSortMembers(merged),
          memberNextCursor: page.nextCursor,
          clearMemberCursor: page.nextCursor == null,
          clearMemberFailure: true,
          loadingMoreMembers: false,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          memberStatus: IamLoadStatus.failure,
          memberFailure: IamUiFailureMapper.from(error),
          loadingMoreMembers: false,
        ),
      );
    }
  }

  Future<void> loadInvitations({bool reset = false}) async {
    if (isClosed) return;
    if (reset) {
      emit(
        state.copyWith(
          invitationStatus: IamLoadStatus.loading,
          clearInvitationFailure: true,
          clearInvitationCursor: true,
          invitations: const [],
        ),
      );
    } else if (state.invitationStatus == IamLoadStatus.initial) {
      emit(
        state.copyWith(
          invitationStatus: IamLoadStatus.loading,
          clearInvitationFailure: true,
        ),
      );
    }

    try {
      final wireStatus = state.invitationFilter == 'expiring'
          ? 'pending'
          : state.invitationFilter;
      final page = await _invitations.listInvitations(
        search: _nullableSearch(state.invitationSearch),
        status: wireStatus,
        cursor: reset ? null : state.invitationNextCursor,
      );
      if (isClosed) return;
      final now = _clock();
      var mapped = page.items
          .map((dto) => InvitationUiMapper.fromSummary(dto, nowUtc: now))
          .toList();
      if (state.invitationFilter == 'expiring') {
        mapped = mapped
            .where((i) => i.status == InvitationStatus.expiring)
            .toList();
      }
      final merged = reset
          ? mapped
          : _dedupeInvitations([...state.invitations, ...mapped]);
      emit(
        state.copyWith(
          invitationStatus: IamLoadStatus.success,
          invitations: _filterInvitations(merged),
          invitationNextCursor: page.nextCursor,
          clearInvitationCursor: page.nextCursor == null,
          clearInvitationFailure: true,
          loadingMoreInvitations: false,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          invitationStatus: IamLoadStatus.failure,
          invitationFailure: IamUiFailureMapper.from(error),
          loadingMoreInvitations: false,
        ),
      );
    }
  }

  Future<void> loadNextMembersPage() async {
    if (isClosed ||
        state.loadingMoreMembers ||
        !state.hasMoreMembers ||
        state.memberStatus == IamLoadStatus.loading) {
      return;
    }
    emit(state.copyWith(loadingMoreMembers: true));
    await loadMembers(reset: false);
  }

  Future<void> loadNextInvitationsPage() async {
    if (isClosed ||
        state.loadingMoreInvitations ||
        !state.hasMoreInvitations ||
        state.invitationStatus == IamLoadStatus.loading) {
      return;
    }
    emit(state.copyWith(loadingMoreInvitations: true));
    await loadInvitations(reset: false);
  }

  Future<void> setMemberSearch(String value) async {
    emit(state.copyWith(memberSearch: value));
    _memberSearchTimer?.cancel();
    if (_searchDebounce == Duration.zero) {
      await loadMembers(reset: true);
      return;
    }
    final completer = Completer<void>();
    _memberSearchTimer = Timer(_searchDebounce, () async {
      await loadMembers(reset: true);
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> setInvitationSearch(String value) async {
    emit(state.copyWith(invitationSearch: value));
    _invitationSearchTimer?.cancel();
    if (_searchDebounce == Duration.zero) {
      await loadInvitations(reset: true);
      return;
    }
    final completer = Completer<void>();
    _invitationSearchTimer = Timer(_searchDebounce, () async {
      await loadInvitations(reset: true);
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> setMemberFilter(String? status) async {
    emit(
      state.copyWith(
        memberFilter: status,
        clearMemberFilter: status == null,
      ),
    );
    await loadMembers(reset: true);
  }

  Future<void> applyMemberCriteria({
    String? status,
    String? role,
    String? sort,
  }) async {
    emit(
      state.copyWith(
        memberFilter: status,
        clearMemberFilter: status == null,
        memberRoleFilter: role,
        clearMemberRoleFilter: role == null,
        memberSort: sort,
        clearMemberSort: sort == null,
      ),
    );
    await loadMembers(reset: true);
  }

  Future<void> setInvitationFilter(String? status) async {
    emit(
      state.copyWith(
        invitationFilter: status,
        clearInvitationFilter: status == null,
      ),
    );
    await loadInvitations(reset: true);
  }

  Future<void> applyInvitationCriteria({
    String? status,
    String? sendResult,
    String? timeRange,
    DateTimeRange? customDateRange,
  }) async {
    emit(
      state.copyWith(
        invitationFilter: status,
        clearInvitationFilter: status == null,
        invitationSendResultFilter: sendResult,
        clearInvitationSendResultFilter:
            sendResult == null || sendResult == 'Tất cả',
        invitationTimeRangeFilter: timeRange,
        clearInvitationTimeRangeFilter:
            timeRange == null || timeRange == 'Tất cả',
        invitationCustomDateRange: customDateRange,
        clearInvitationCustomDateRange: customDateRange == null,
      ),
    );
    await loadInvitations(reset: true);
  }

  void selectTab(OrganizationUsersTab tab) {
    if (isClosed || state.activeTab == tab) return;
    emit(state.copyWith(activeTab: tab));
  }

  Future<void> refreshActiveTab() async {
    if (state.activeTab == OrganizationUsersTab.members) {
      await loadMembers(reset: true);
    } else {
      await loadInvitations(reset: true);
    }
  }

  String? _nullableSearch(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<MemberUiModel> _dedupeMembers(List<MemberUiModel> items) {
    final seen = <String>{};
    final result = <MemberUiModel>[];
    for (final item in items) {
      if (seen.add(item.id)) result.add(item);
    }
    return result;
  }

  List<MemberUiModel> _filterAndSortMembers(List<MemberUiModel> items) {
    var result = List<MemberUiModel>.from(items);
    if (state.memberRoleFilter != null && state.memberRoleFilter != 'Tất cả') {
      final code = IamRoleLabelMapper.toRoleCode(state.memberRoleFilter);
      result = result.where((m) => m.roleCode == code).toList();
    }
    if (state.memberSort == 'Tên A–Z') {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (state.memberSort == 'Tên Z–A') {
      result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else {
      result = _sortMembers(result);
    }
    return result;
  }

  List<MemberUiModel> _sortMembers(List<MemberUiModel> items) {
    final list = List<MemberUiModel>.from(items);
    list.sort((a, b) {
      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;
      return 0;
    });
    return list;
  }

  List<InvitationUiModel> _dedupeInvitations(List<InvitationUiModel> items) {
    final seen = <String>{};
    final result = <InvitationUiModel>[];
    for (final item in items) {
      if (seen.add(item.id)) result.add(item);
    }
    return result;
  }

  List<InvitationUiModel> _filterInvitations(List<InvitationUiModel> items) {
    var result = List<InvitationUiModel>.from(items);
    final now = _clock();

    if (state.invitationSendResultFilter != null &&
        state.invitationSendResultFilter != 'Tất cả') {
      final opt = state.invitationSendResultFilter!;
      result = result.where((item) {
        return switch (opt) {
          'Đã gửi' =>
            item.deliveryStatus == 'sent' &&
                item.status != InvitationStatus.revoked,
          'Gửi lỗi' =>
            item.deliveryStatus == 'failed' ||
                item.status == InvitationStatus.failed,
          'Thu hồi' => item.status == InvitationStatus.revoked,
          _ => true,
        };
      }).toList();
    }

    if (state.invitationTimeRangeFilter != null &&
        state.invitationTimeRangeFilter != 'Tất cả') {
      final opt = state.invitationTimeRangeFilter!;
      result = result.where((item) {
        final itemDate =
            item.expiresAt?.subtract(const Duration(days: 7)) ?? now;

        if (opt == '7 ngày') {
          final threshold = now.subtract(const Duration(days: 7));
          return itemDate.isAfter(threshold);
        } else if (opt == '30 ngày') {
          final threshold = now.subtract(const Duration(days: 30));
          return itemDate.isAfter(threshold);
        } else if (opt == 'Tùy chọn' &&
            state.invitationCustomDateRange != null) {
          final range = state.invitationCustomDateRange!;
          final startOfFirstDay = DateTime.utc(
            range.start.year,
            range.start.month,
            range.start.day,
          );
          final endOfLastDay = DateTime.utc(
            range.end.year,
            range.end.month,
            range.end.day,
            23,
            59,
            59,
            999,
          );
          return (itemDate.isAfter(startOfFirstDay) ||
                  itemDate.isAtSameMomentAs(startOfFirstDay)) &&
              (itemDate.isBefore(endOfLastDay) ||
                  itemDate.isAtSameMomentAs(endOfLastDay));
        }
        return true;
      }).toList();
    }

    return result;
  }

  @override
  Future<void> close() {
    _memberSearchTimer?.cancel();
    _invitationSearchTimer?.cancel();
    return super.close();
  }
}
