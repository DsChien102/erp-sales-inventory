import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../bloc/tenant_audit_logs_cubit.dart';
import '../bloc/tenant_audit_logs_state.dart';
import '../mappers/tenant_audit_ui_mapper.dart';
import '../widgets/audit_log_empty_view.dart';
import '../widgets/audit_log_item_card.dart';
import 'audit_log_detail_page.dart';

/// Trang Lịch sử quản trị tổ chức (S13).
class OrganizationAuditLogsPage extends StatelessWidget {
  const OrganizationAuditLogsPage({
    super.key,
    this.iamModule,
    this.executionContext,
    this.cubit,
    this.clockLocal,
  });

  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
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
      iamModule != null && executionContext != null,
      'OrganizationAuditLogsPage requires iamModule + executionContext or cubit',
    );
    return BlocProvider(
      create: (_) => TenantAuditLogsCubit(
        iamModule: iamModule!,
        executionContext: executionContext!,
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

  Future<void> _applyEventCodeSearch(String raw) async {
    final cubit = context.read<TenantAuditLogsCubit>();
    final trimmed = raw.trim();
    final next = trimmed.isEmpty
        ? cubit.state.filters.copyWith(clearEventCode: true)
        : cubit.state.filters.copyWith(eventCode: trimmed);
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

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return BlocBuilder<TenantAuditLogsCubit, TenantAuditLogsState>(
      builder: (context, state) {
        final subtitleText = state.failure?.code ==
                IamBlockedCodes.permissionDenied
            ? 'Chưa được cấp quyền'
            : state.status == IamLoadStatus.failure
                ? 'Không tải được dữ liệu'
                : '${state.items.length} hoạt động';

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
                child: VSearchBar(
                  hintText: 'Tìm theo mã sự kiện (event code)',
                  controller: _searchController,
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      _applyEventCodeSearch(value);
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.screenMobile,
                  vertical: VSpacing.space2,
                ),
                child: VText(
                  'Khoảng thời gian: ${state.filters.fromLocal.day}/${state.filters.fromLocal.month} → ${state.filters.toLocal.day}/${state.filters.toLocal.month} · Mới nhất trước',
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

    if (state.status == IamLoadStatus.loading ||
        state.status == IamLoadStatus.initial) {
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
        type: filtered
            ? AuditLogEmptyStateType.noResults
            : AuditLogEmptyStateType.noAuditLogs,
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
                      onPressed: () =>
                          context.read<TenantAuditLogsCubit>().loadNextPage(),
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
