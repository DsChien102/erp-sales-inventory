import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart' hide TenantAuditEventCategory, TenantAuditLogResult, TenantAuditDisplayOrigin, TenantAuditLogSummaryDto;

import '../../../data/models/tenant_audit_log.dart';

import '../../../data/audit_log_repository.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/tenant_audit_filter.dart';
import '../bloc/tenant_audit_logs_cubit.dart';
import '../bloc/tenant_audit_logs_state.dart';
import '../catalog/tenant_audit_event_catalog.dart';
import '../mappers/tenant_audit_ui_mapper.dart';
import '../models/audit_log_filter_criteria.dart';
import '../models/audit_log_ui_model.dart';
import '../widgets/audit_log_category_filter_chips.dart';
import '../widgets/audit_log_empty_view.dart';
import '../widgets/audit_log_filter_bottom_sheet.dart';
import '../widgets/audit_log_item_card.dart';
import 'audit_log_detail_page.dart';

/// Trang Lịch sử quản trị tổ chức (S13).
class OrganizationAuditLogsPage extends StatelessWidget {
  const OrganizationAuditLogsPage({
    super.key,
    this.auditLogs,
    this.cubit,
    this.clockLocal,
  });

  final AuditLogRepository? auditLogs;
  final TenantAuditLogsCubit? cubit;
  final DateTime Function()? clockLocal;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _AuditLogsView(),
      );
    }
    assert(
      auditLogs != null,
      'OrganizationAuditLogsPage requires auditLogs or cubit',
    );
    return BlocProvider(
      create: (_) => TenantAuditLogsCubit(
        auditLogs: auditLogs!,
        clockLocal: clockLocal,
      )..search(),
      child: const _AuditLogsView(),
    );
  }
}

class _AuditLogsView extends StatefulWidget {
  const _AuditLogsView();

  @override
  State<_AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<_AuditLogsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applySearch(String raw) async {
    final cubit = context.read<TenantAuditLogsCubit>();
    final trimmed = raw.trim();
    final matchingEventCodes = TenantAuditEventCatalog.matchingEventCodes(trimmed);
    final next = switch ((trimmed.isEmpty, matchingEventCodes.isNotEmpty)) {
      (true, _) => cubit.state.filters.copyWith(
        clearQuery: true,
        clearEventCodes: true,
      ),
      (false, true) => cubit.state.filters.copyWith(
        eventCodes: matchingEventCodes,
        clearQuery: true,
      ),
      (false, false) => cubit.state.filters.copyWith(
        query: trimmed,
        clearEventCodes: true,
      ),
    };
    await cubit.applyFilter(next);
  }

  Future<void> _openDetail(String auditLogId) async {
    try {
      await context.push('/more/audit-logs/$auditLogId');
    } catch (_) {
      if (!mounted) return;
      final cubit = context.read<TenantAuditLogsCubit>();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AuditLogDetailPage(
            auditLogId: auditLogId,
            cubit: cubit,
          ),
        ),
      );
    }
  }

  int _calculateRangeDays(DateTime from, DateTime to) {
    return to.difference(from).inDays + 1;
  }

  String _formatTimeInfo(TenantAuditFilter filter) {
    final days = _calculateRangeDays(filter.fromLocal, filter.toLocal);
    if (days == 30) {
      return 'Thời gian: 30 ngày gần đây · Mới nhất trước';
    } else if (days == 7) {
      return 'Thời gian: 7 ngày gần đây · Mới nhất trước';
    } else if (days <= 1) {
      return 'Thời gian: 24 giờ gần đây · Mới nhất trước';
    }
    return 'Thời gian: ${filter.fromLocal.day}/${filter.fromLocal.month} → ${filter.toLocal.day}/${filter.toLocal.month} · Mới nhất trước';
  }

  Future<void> _openFilterBottomSheet(
    BuildContext context,
    TenantAuditLogsState state,
  ) async {
    final cubit = context.read<TenantAuditLogsCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.vColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.sheet)),
      ),
      builder: (_) => AuditLogFilterBottomSheet(
        initialCriteria: AuditLogFilterCriteria(
          status: state.filters.result != null
              ? (switch (state.filters.result!) {
                  TenantAuditLogResult.success => AuditLogStatus.success,
                  TenantAuditLogResult.blocked => AuditLogStatus.blocked,
                  TenantAuditLogResult.error => AuditLogStatus.error,
                })
              : null,
          timeRange: _resolveTimeRange(state.filters),
          actorType: 'Tất cả',
        ),
        onApply: (criteria) async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final fromLocal = switch (criteria.timeRange) {
            '24 giờ' => today.subtract(const Duration(days: 1)),
            '7 ngày' => today.subtract(const Duration(days: 6)),
            '30 ngày' => today.subtract(const Duration(days: 29)),
            _ => state.filters.fromLocal,
          };
          final result = criteria.status != null
              ? (switch (criteria.status!) {
                  AuditLogStatus.success => TenantAuditLogResult.success,
                  AuditLogStatus.blocked => TenantAuditLogResult.blocked,
                  AuditLogStatus.error => TenantAuditLogResult.error,
                })
              : null;
          final next = state.filters.copyWith(
            fromLocal: fromLocal,
            toLocal: today,
            result: result,
            clearResult: result == null,
          );
          await cubit.applyFilter(next);
        },
      ),
    );
  }

  String _resolveTimeRange(TenantAuditFilter filter) {
    final days = _calculateRangeDays(filter.fromLocal, filter.toLocal);
    if (days <= 1) return '24 giờ';
    if (days == 7) return '7 ngày';
    return '30 ngày';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return BlocBuilder<TenantAuditLogsCubit, TenantAuditLogsState>(
      builder: (context, state) {
        final days = _calculateRangeDays(
          state.filters.fromLocal,
          state.filters.toLocal,
        );
        final subtitleText = state.failure?.code == IamBlockedCodes.permissionDenied
            ? 'Chưa được cấp quyền'
            : state.status == IamLoadStatus.failure
            ? 'Không tải được dữ liệu'
            : '${state.totalCount} hoạt động trong $days ngày';

        return Scaffold(
          backgroundColor: colors.surfaceAlt,
          appBar: VAppBar(
            title: 'Lịch sử quản trị',
            subtitle: subtitleText,
            showBackButton: true,
            leading: IconButton(
              icon: VIcon(
                icon: VIcons.chevronLeft,
                color: colors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: colors.surfaceAlt,
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.screenMobile,
                  vertical: VSpacing.space2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: VSearchBar(
                        hintText: 'Tìm người thực hiện hoặc hoạt động',
                        controller: _searchController,
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 350), () {
                            _applySearch(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: VSpacing.space2),
                    InkWell(
                      onTap: () => _openFilterBottomSheet(context, state),
                      borderRadius: BorderRadius.circular(VRadius.input),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(VRadius.input),
                          border: VBorders.all(colors.borderDefault),
                        ),
                        child: Center(
                          child: VIcon(
                            icon: VIcons.tune,
                            size: 20,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AuditLogCategoryFilterChips(
                selectedCategory: state.filters.eventCategory,
                onCategorySelected: (category) {
                  final cubit = context.read<TenantAuditLogsCubit>();
                  final next = category == null
                      ? state.filters.copyWith(clearEventCategory: true)
                      : state.filters.copyWith(eventCategory: category);
                  cubit.applyFilter(next);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.screenMobile,
                  vertical: VSpacing.space2,
                ),
                child: VText(
                  _formatTimeInfo(state.filters),
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TenantAuditLogsState state) {
    if (state.failure?.code == IamBlockedCodes.permissionDenied) {
      return AuditLogEmptyView(
        type: AuditLogEmptyStateType.unauthorized,
        onAction: () => Navigator.of(context).maybePop(),
      );
    }

    if (state.status == IamLoadStatus.loading || state.status == IamLoadStatus.initial) {
      return const Center(child: VLoading(size: 40));
    }

    if (state.status == IamLoadStatus.failure) {
      return AuditLogEmptyView(
        type: AuditLogEmptyStateType.loadError,
        onAction: () => context.read<TenantAuditLogsCubit>().search(),
      );
    }

    if (state.items.isEmpty) {
      final filtered = state.filters.hasAdvancedFilters;
      return AuditLogEmptyView(
        type: filtered ? AuditLogEmptyStateType.noResults : AuditLogEmptyStateType.noAuditLogs,
        onAction: filtered
            ? () {
                _searchController.clear();
                context.read<TenantAuditLogsCubit>().clearFilter();
              }
            : () => context.read<TenantAuditLogsCubit>().search(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(
        left: VSpacing.screenMobile,
        right: VSpacing.screenMobile,
        bottom: VSpacing.space6,
      ),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const VGap.sm(),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: VSpacing.space4),
            child: Center(
              child: state.isLoadingMore
                  ? const VLoading(size: 28)
                  : VButton(
                      label: 'Tải thêm',
                      variant: VButtonVariant.secondary,
                      onPressed: () => context.read<TenantAuditLogsCubit>().loadNextPage(),
                    ),
            ),
          );
        }
        final summary = state.items[index];
        final log = TenantAuditUiMapper.fromSummary(summary);
        return AuditLogItemCard(
          log: log,
          onTap: () => _openDetail(summary.auditLogId),
        );
      },
    );
  }
}
