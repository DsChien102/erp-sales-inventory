import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../data/audit_log_repository.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/tenant_audit_logs_cubit.dart';
import '../bloc/tenant_audit_logs_state.dart';
import '../mappers/tenant_audit_ui_mapper.dart';
import '../widgets/audit_log_detail_body.dart';

/// Chi tiết nhật ký — loads by [auditLogId] via [AuditLogRepository.getDetail].
class AuditLogDetailPage extends StatelessWidget {
  const AuditLogDetailPage({
    super.key,
    required this.auditLogId,
    this.auditLogs,
    this.cubit,
    this.onBackPressed,
  });

  final String auditLogId;
  final AuditLogRepository? auditLogs;
  final TenantAuditLogsCubit? cubit;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _AuditLogDetailView(
          auditLogId: auditLogId,
          onBackPressed: onBackPressed,
        ),
      );
    }
    assert(
      auditLogs != null,
      'AuditLogDetailPage requires auditLogs or cubit',
    );
    return BlocProvider(
      create: (_) => TenantAuditLogsCubit(
        auditLogs: auditLogs!,
      )..loadDetail(auditLogId),
      child: _AuditLogDetailView(
        auditLogId: auditLogId,
        onBackPressed: onBackPressed,
      ),
    );
  }
}

class _AuditLogDetailView extends StatefulWidget {
  const _AuditLogDetailView({
    required this.auditLogId,
    this.onBackPressed,
  });

  final String auditLogId;
  final VoidCallback? onBackPressed;

  @override
  State<_AuditLogDetailView> createState() => _AuditLogDetailViewState();
}

class _AuditLogDetailViewState extends State<_AuditLogDetailView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<TenantAuditLogsCubit>();
    if (cubit.state.selectedDetail?.auditLogId != widget.auditLogId) {
      cubit.loadDetail(widget.auditLogId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return BlocBuilder<TenantAuditLogsCubit, TenantAuditLogsState>(
      builder: (context, state) {
        final isSplit = VListDetailLayout.isSplitOf(context);

        if (state.detailStatus == IamLoadStatus.loading ||
            state.detailStatus == IamLoadStatus.initial) {
          return Scaffold(
            backgroundColor: colors.surfaceAlt,
            appBar: AppBar(
              backgroundColor: colors.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: isSplit
                  ? null
                  : IconButton(
                      tooltip: 'Quay lại',
                      icon: VIcon(
                        icon: VIcons.chevronLeft,
                        color: colors.textPrimary,
                      ),
                      onPressed: widget.onBackPressed ?? () => Navigator.of(context).maybePop(),
                    ),
              titleSpacing: isSplit ? VSpacing.space4 : 0,
              title: Semantics(
                header: true,
                child: const VText(
                  'Chi tiết hoạt động',
                  variant: VTextVariant.headingH4,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            body: const Center(child: VLoading(size: 40)),
          );
        }

        if (state.detailStatus == IamLoadStatus.failure || state.selectedDetail == null) {
          return Scaffold(
            backgroundColor: colors.surfaceAlt,
            appBar: AppBar(
              backgroundColor: colors.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: isSplit
                  ? null
                  : IconButton(
                      tooltip: 'Quay lại',
                      icon: VIcon(
                        icon: VIcons.chevronLeft,
                        color: colors.textPrimary,
                      ),
                      onPressed: widget.onBackPressed ?? () => Navigator.of(context).maybePop(),
                    ),
              titleSpacing: isSplit ? VSpacing.space4 : 0,
              title: Semantics(
                header: true,
                child: const VText(
                  'Chi tiết hoạt động',
                  variant: VTextVariant.headingH4,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: const VText(
                        'Không tìm thấy hoạt động',
                        variant: VTextVariant.headingH4,
                      ),
                    ),
                    const VGap.sm(),
                    VText(
                      state.detailFailure?.message ??
                          'Nhật ký không tồn tại hoặc không thuộc tổ chức hiện tại.',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () =>
                          context.read<TenantAuditLogsCubit>().loadDetail(widget.auditLogId),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final log = TenantAuditUiMapper.fromDetail(state.selectedDetail!);
        return AuditLogDetailBody(
          log: log,
          onBackPressed: widget.onBackPressed,
        );
      },
    );
  }
}
