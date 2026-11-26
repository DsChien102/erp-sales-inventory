import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../../../core/config/wide_layout.dart';
import '../../../../../core/di/injection.dart';
import '../../../data/audit_log_repository.dart';
import '../../../data/models/tenant_audit_log.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/tenant_audit_filter.dart';
import '../bloc/tenant_audit_logs_cubit.dart';
import '../bloc/tenant_audit_logs_state.dart';
import '../mappers/tenant_audit_ui_mapper.dart';
import '../models/audit_log_filter_criteria.dart';
import '../models/audit_log_ui_model.dart';
import '../widgets/audit_log_empty_view.dart';
import '../widgets/audit_log_filter_bottom_sheet.dart';
import '../widgets/audit_narrow.dart';
import '../widgets/audit_wide.dart';
import 'audit_log_detail_page.dart';

/// Màn hình danh sách lịch sử quản trị (US-07.2).
class OrganizationAuditLogsPage extends StatelessWidget {
  const OrganizationAuditLogsPage({
    super.key,
    this.auditLogs,
    this.clockLocal,
    this.cubit,
  });

  final AuditLogRepository? auditLogs;
  final DateTime Function()? clockLocal;
  final TenantAuditLogsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _OrganizationAuditLogsView(),
      );
    }
    return BlocProvider(
      create: (_) => TenantAuditLogsCubit(
        auditLogs: auditLogs ?? getIt<AuditLogRepository>(),
        clockLocal: clockLocal,
      )..search(),
      child: const _OrganizationAuditLogsView(),
    );
  }
}

class _OrganizationAuditLogsView extends StatefulWidget {
  const _OrganizationAuditLogsView();

  @override
  State<_OrganizationAuditLogsView> createState() =>
      _OrganizationAuditLogsViewState();
}

class _OrganizationAuditLogsViewState
    extends State<_OrganizationAuditLogsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final cubit = context.read<TenantAuditLogsCubit>();
      final trimmed = value.trim();
      cubit.applyFilter(
        cubit.state.filters.copyWith(
          query: trimmed.isEmpty ? null : trimmed,
          clearQuery: trimmed.isEmpty,
        ),
      );
    });
  }

  void _clearAllFilters() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<TenantAuditLogsCubit>().clearFilter();
  }

  String _rangeLabel(TenantAuditRange range) {
    return switch (range) {
      TenantAuditRange.h24 => '24 giờ',
      TenantAuditRange.d7 => '7 ngày',
      TenantAuditRange.d30 => '30 ngày',
    };
  }

  String _rangeSubtitle(TenantAuditRange range) {
    return switch (range) {
      TenantAuditRange.h24 => 'Thời gian: 24 giờ gần đây · Mới nhất trước',
      TenantAuditRange.d7 => 'Thời gian: 7 ngày gần đây · Mới nhất trước',
      TenantAuditRange.d30 => 'Thời gian: 30 ngày gần đây · Mới nhất trước',
    };
  }

  String _buildSubtitle(TenantAuditLogsState state) {
    if (state.status == IamLoadStatus.failure) {
      if (state.failure?.code == IamBlockedCodes.permissionDenied) {
        return 'Chưa được cấp quyền';
      }
      return 'Không tải được dữ liệu';
    }
    if (state.status == IamLoadStatus.loading ||
        state.status == IamLoadStatus.initial) {
      return 'Đang tải lịch sử quản trị';
    }
    return '${state.totalCount} hoạt động trong ${_rangeLabel(state.filters.range)}';
  }

  AuditLogEmptyStateType? _resolveEmptyType(TenantAuditLogsState state) {
    if (state.status == IamLoadStatus.failure) {
      if (state.failure?.code == IamBlockedCodes.permissionDenied) {
        return AuditLogEmptyStateType.unauthorized;
      }
      return AuditLogEmptyStateType.loadError;
    }
    if (state.status == IamLoadStatus.success && state.items.isEmpty) {
      return state.filters.hasAdvancedFilters
          ? AuditLogEmptyStateType.noResults
          : AuditLogEmptyStateType.noAuditLogs;
    }
    return null;
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    TenantAuditLogsState state,
  ) async {
    final cubit = context.read<TenantAuditLogsCubit>();
    await showVAdaptiveSheet<void>(
      context: context,
      title: 'Bộ lọc lịch sử quản trị',
      child: AuditLogFilterBottomSheet(
        initialCriteria: AuditLogFilterCriteria(
          status: state.filters.result != null
              ? (switch (state.filters.result!) {
                  TenantAuditLogResult.success => AuditLogStatus.success,
                  TenantAuditLogResult.blocked => AuditLogStatus.blocked,
                  TenantAuditLogResult.error => AuditLogStatus.error,
                })
              : null,
          range: state.filters.range,
        ),
        onApply: (criteria) async {
          final result = criteria.status != null
              ? (switch (criteria.status!) {
                  AuditLogStatus.success => TenantAuditLogResult.success,
                  AuditLogStatus.blocked => TenantAuditLogResult.blocked,
                  AuditLogStatus.error => TenantAuditLogResult.error,
                })
              : null;
          await cubit.applyRangeAndResult(criteria.range, result);
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, AuditLogItemUiModel item) async {
    if (isWideLayout(context)) {
      context.go('/more/audit-logs/${item.id}');
      return;
    }
    try {
      await context.push('/more/audit-logs/${item.id}');
    } catch (_) {
      if (!context.mounted) return;
      final cubit = context.read<TenantAuditLogsCubit>();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AuditLogDetailPage(
            auditLogId: item.id,
            cubit: cubit,
          ),
        ),
      );
    }
  }

  void _handleEmptyAction(
    BuildContext context,
    AuditLogEmptyStateType emptyType,
  ) {
    switch (emptyType) {
      case AuditLogEmptyStateType.unauthorized:
        Navigator.of(context).maybePop();
      case AuditLogEmptyStateType.noResults:
        _clearAllFilters();
      case AuditLogEmptyStateType.noAuditLogs:
      case AuditLogEmptyStateType.loadError:
        context.read<TenantAuditLogsCubit>().search(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);

    return BlocConsumer<TenantAuditLogsCubit, TenantAuditLogsState>(
      listenWhen: (previous, current) =>
          previous.loadMoreFailure != current.loadMoreFailure &&
          current.loadMoreFailure != null,
      listener: (context, state) {
        final failure = state.loadMoreFailure;
        if (failure == null) return;
        VToast.show(
          context,
          title: 'Không tải thêm được',
          message: 'Không tải thêm được. ${failure.message}',
          type: VToastType.danger,
        );
        context.read<TenantAuditLogsCubit>().clearLoadMoreFailure();
      },
      builder: (context, state) {
        final cubit = context.read<TenantAuditLogsCubit>();
        final emptyType = _resolveEmptyType(state);
        final isLoading = state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial;
        final isFilterActive = state.filters.range != TenantAuditRange.d30 ||
            state.filters.result != null;
        final mappedItems =
            state.items.map(TenantAuditUiMapper.fromSummary).toList(growable: false);
        final rangeSub = _rangeSubtitle(state.filters.range);

        return VPageScaffold(
          title: 'Lịch sử quản trị',
          subtitle: _buildSubtitle(state),
          showBackButton: true,
          contentMaxWidth: VPageScaffold.fullWidth,
          body: wide
              ? AuditWide(
                  searchController: _searchController,
                  isFilterActive: isFilterActive,
                  selectedCategory: state.filters.eventCategory,
                  rangeSubtitle: rangeSub,
                  emptyType: emptyType,
                  isLoading: isLoading,
                  isLoadingMore: state.isLoadingMore,
                  hasMore: state.hasMore,
                  items: mappedItems,
                  onSearchChanged: _onSearchChanged,
                  onOpenFilter: () => _openFilterSheet(context, state),
                  onCategorySelected: (cat) {
                    cubit.applyFilter(
                      state.filters.copyWith(
                        eventCategory: cat,
                        clearEventCategory: cat == null,
                      ),
                    );
                  },
                  onEmptyAction: () {
                    if (emptyType != null) {
                      _handleEmptyAction(context, emptyType);
                    }
                  },
                  onItemTap: (item) => _openDetail(context, item),
                  onLoadMore: () => cubit.loadNextPage(),
                )
              : AuditNarrow(
                  searchController: _searchController,
                  isFilterActive: isFilterActive,
                  selectedCategory: state.filters.eventCategory,
                  rangeSubtitle: rangeSub,
                  emptyType: emptyType,
                  isLoading: isLoading,
                  isLoadingMore: state.isLoadingMore,
                  hasMore: state.hasMore,
                  items: mappedItems,
                  onSearchChanged: _onSearchChanged,
                  onOpenFilter: () => _openFilterSheet(context, state),
                  onCategorySelected: (cat) {
                    cubit.applyFilter(
                      state.filters.copyWith(
                        eventCategory: cat,
                        clearEventCategory: cat == null,
                      ),
                    );
                  },
                  onEmptyAction: () {
                    if (emptyType != null) {
                      _handleEmptyAction(context, emptyType);
                    }
                  },
                  onItemTap: (item) => _openDetail(context, item),
                  onLoadMore: () => cubit.loadNextPage(),
                ),
        );
      },
    );
  }
}
