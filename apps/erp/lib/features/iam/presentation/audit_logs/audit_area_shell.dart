import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';

import '../../data/audit_log_repository.dart';
import 'bloc/tenant_audit_logs_cubit.dart';
import 'views/organization_audit_logs_page.dart';

/// Shell phân khu Lịch sử quản trị — cung cấp [TenantAuditLogsCubit] và bố cục 2 cột web.
class AuditAreaShell extends StatelessWidget {
  const AuditAreaShell({
    super.key,
    required this.child,
    this.selectedId,
    this.auditLogs,
    this.clockLocal,
    this.cubit,
  });

  final Widget child;
  final String? selectedId;
  final AuditLogRepository? auditLogs;
  final DateTime Function()? clockLocal;
  final TenantAuditLogsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: Builder(
          builder: (context) => _buildLayout(context, cubit!),
        ),
      );
    }
    return BlocProvider(
      create: (_) => TenantAuditLogsCubit(
        auditLogs: auditLogs ?? getIt<AuditLogRepository>(),
        clockLocal: clockLocal,
      )..search(),
      child: Builder(
        builder: (context) {
          final cubitInstance = context.read<TenantAuditLogsCubit>();
          return _buildLayout(context, cubitInstance);
        },
      ),
    );
  }

  Widget _buildLayout(BuildContext context, TenantAuditLogsCubit cubitInstance) {
    return VListDetailLayout(
      list: OrganizationAuditLogsPage(
        cubit: cubitInstance,
        selectedId: selectedId,
      ),
      detail: child,
    );
  }
}
