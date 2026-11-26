import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../../../core/config/wide_layout.dart';
import '../../../data/audit_log_repository.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/tenant_audit_logs_cubit.dart';
import '../bloc/tenant_audit_logs_state.dart';
import '../mappers/tenant_audit_ui_mapper.dart';
import '../widgets/audit_detail_narrow.dart';
import '../widgets/audit_detail_wide.dart';

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
      ),
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
    final wide = isWideLayout(context);

    final backLeading = widget.onBackPressed == null
        ? null
        : IconButton(
            tooltip: 'Quay lại',
            icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
            onPressed: widget.onBackPressed,
          );

    return BlocBuilder<TenantAuditLogsCubit, TenantAuditLogsState>(
      builder: (context, state) {
        if (state.detailStatus == IamLoadStatus.loading ||
            state.detailStatus == IamLoadStatus.initial) {
          return VPageScaffold(
            title: 'Chi tiết hoạt động',
            showBackButton: true,
            leading: backLeading,
            contentMaxWidth: VPageScaffold.fullWidth,
            body: const Center(child: VLoading(size: 40)),
          );
        }

        if (state.detailStatus == IamLoadStatus.failure ||
            state.selectedDetail == null) {
          final isNotFound =
              state.detailFailure?.code == IamBlockedCodes.resourceNotFound;
          final title = isNotFound
              ? 'Không tìm thấy hoạt động'
              : 'Không tải được hoạt động';
          final message = isNotFound
              ? 'Nhật ký không tồn tại hoặc không thuộc tổ chức hiện tại.'
              : (state.detailFailure?.message ??
                    'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.');

          return VPageScaffold(
            title: 'Chi tiết hoạt động',
            showBackButton: true,
            leading: backLeading,
            contentMaxWidth: VPageScaffold.fullWidth,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: VText(
                        title,
                        variant: VTextVariant.headingH4,
                      ),
                    ),
                    const VGap.sm(),
                    VText(
                      message,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () => context
                          .read<TenantAuditLogsCubit>()
                          .loadDetail(widget.auditLogId),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final log = TenantAuditUiMapper.fromDetail(state.selectedDetail!);
        return VPageScaffold(
          title: 'Chi tiết hoạt động',
          showBackButton: true,
          leading: backLeading,
          contentMaxWidth: VPageScaffold.fullWidth,
          body: wide ? AuditDetailWide(log: log) : AuditDetailNarrow(log: log),
        );
      },
    );
  }
}
