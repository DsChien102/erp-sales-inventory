import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import '../mappers/invitation_ui_mapper.dart';
import '../mappers/member_ui_mapper.dart';
import '../models/user_ui_model.dart';
import 'organization_users_state.dart';

final class OrganizationUsersCubit extends Cubit<OrganizationUsersState> {
  OrganizationUsersCubit({
    required IIamModule iamModule,
    required IExecutionContext executionContext,
    DateTime Function()? clock,
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : _iamModule = iamModule,
       _executionContext = executionContext,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _searchDebounce = searchDebounce,
       super(const OrganizationUsersState());

  final IIamModule _iamModule;
  final IExecutionContext _executionContext;
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
      final tenantId = await _executionContext.requireTenantId();
      final page = await _iamModule
          .executeQueryAsync<CursorPageDto<TenantMemberDto>>(
            ListTenantMembersQuery(
              tenantId: tenantId,
              search: _nullableSearch(state.memberSearch),
              status: state.memberFilter,
              cursor: reset ? null : state.memberNextCursor,
            ),
          );
      if (isClosed) return;
      final mapped = page.items.map(MemberUiMapper.fromSummary).toList();
      final merged = reset
          ? mapped
          : _dedupeMembers([...state.members, ...mapped]);
      emit(
        state.copyWith(
          memberStatus: IamLoadStatus.success,
          members: merged,
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
      final tenantId = await _executionContext.requireTenantId();
      final wireStatus = state.invitationFilter == 'expiring'
          ? 'pending'
          : state.invitationFilter;
      final page = await _iamModule
          .executeQueryAsync<CursorPageDto<InvitationSummaryDto>>(
            ListInvitationsQuery(
              tenantId: tenantId,
              search: _nullableSearch(state.invitationSearch),
              status: wireStatus,
              cursor: reset ? null : state.invitationNextCursor,
            ),
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
          invitations: merged,
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

  Future<void> setInvitationFilter(String? status) async {
    emit(
      state.copyWith(
        invitationFilter: status,
        clearInvitationFilter: status == null,
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

  List<InvitationUiModel> _dedupeInvitations(List<InvitationUiModel> items) {
    final seen = <String>{};
    final result = <InvitationUiModel>[];
    for (final item in items) {
      if (seen.add(item.id)) result.add(item);
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
